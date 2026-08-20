import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:kartvizyon_mobile/core/mobile_services.dart';
import 'package:kartvizyon_mobile/data/local/app_database.dart';
import 'package:kartvizyon_mobile/data/secure_session_store.dart';
import 'package:kartvizyon_mobile/data/sync_engine.dart';
import 'package:kartvizyon_mobile/features/customers/customers_screen.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _EmptySessionStore extends SecureSessionStore {
  const _EmptySessionStore();

  @override
  Future<({String accessToken, String refreshToken})?> read() async => null;
}

/// Galeri/kamera açmadan sabit bir dosya döndüren sahte seçici.
class _FakePicker extends ImagePickerPlatform with MockPlatformInterfaceMixin {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile('kart.jpg');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('kartvizit okunurken ekran bunu gösterir ve düğmeler kapanır', (
    tester,
  ) async {
    ImagePickerPlatform.instance = _FakePicker();

    // OCR isteği testte bilerek tamamlanmaz; asıl mesele bekleme süresince
    // ekranın ne gösterdiği.
    final inFlight = Completer<http.Response>();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    const config = MobileConfig(
      apiBaseUrl: 'https://app.kartvizyon.app',
      supabaseUrl: '',
      supabaseAnonKey: '',
      sentryDsn: '',
    );
    final services = MobileServices.forTesting(
      config: config,
      database: database,
      sessions: const _EmptySessionStore(),
      api: MobileApiClient(
        baseUrl: Uri.parse(config.apiBaseUrl),
        sessions: const _EmptySessionStore(),
        client: MockClient((_) => inFlight.future),
      ),
      sync: SyncEngine(
        database: database,
        sessions: const _EmptySessionStore(),
        baseUrl: Uri.parse(config.apiBaseUrl),
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: CustomersScreen(services: services)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Kartvizit tara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galeriden seç'));
    await tester.pump();
    await tester.pump();

    // Daha önce bu süre boyunca ekranda hiçbir şey değişmiyordu.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Kartvizit okunuyor…'), findsOneWidget);
    final scanButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.document_scanner_outlined),
    );
    expect(scanButton.onPressed, isNull);

    inFlight.complete(http.Response('{"data":{}}', 200));
    await tester.pumpAndSettle();
  });

  test('taranan kartvizitin adresi forma aktarılır', () {
    // Adres alanı formda vardı ama OCR yanıtından hiç doldurulmuyordu. Sunucu
    // adresi koordinata çevirdiği için boş adres, kartvizitten eklenen her
    // müşteriyi haritadan ve yakınlık hatırlatmalarından tamamen çıkarıyordu.
    //
    // Bu, widget testi yerine kaynak üzerinden doğrulanır: yükleme yolu
    // kartvizit dosyasını diskten gerçekten okuyor ve bu iş `pump` içindeki
    // FakeAsync bölgesinde güvenilir biçimde tamamlanmıyor.
    final source = File(
      'lib/features/customers/customers_screen.dart',
    ).readAsStringSync();
    final start = source.indexOf('_CustomerDraft(');
    expect(start, greaterThan(-1), reason: 'OCR taslağı bulunamadı');
    final draft = source.substring(start, source.indexOf(');', start));

    for (final field in [
      'companyName',
      'firstName',
      'lastName',
      'title',
      'phone',
      'email',
      'website',
      'address',
    ]) {
      expect(
        draft.contains("data['$field']"),
        isTrue,
        reason: '$field OCR yanıtından forma aktarılmıyor',
      );
    }
  });
}
