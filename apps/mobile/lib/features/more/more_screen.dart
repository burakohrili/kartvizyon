import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/mobile_services.dart';
import '../../core/store_billing_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.services,
    required this.onSignedOut,
  });
  final MobileServices services;
  final VoidCallback onSignedOut;
  Future<void> chooseWorkspace(BuildContext context) async {
    try {
      final response =
          await services.api.get('/api/workspaces') as Map<String, dynamic>;
      if (!context.mounted) return;
      final workspaces = List<Map<String, dynamic>>.from(
        response['data'] as List? ?? [],
      );
      final target = await showModalBottomSheet<String>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Çalışma alanı seçin')),
              for (final item in workspaces)
                ListTile(
                  title: Text(item['name']?.toString() ?? 'Çalışma alanı'),
                  trailing: item['id'] == services.workspaceId
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () =>
                      Navigator.pop(sheetContext, item['id']?.toString()),
                ),
            ],
          ),
        ),
      );
      if (target == null || target == services.workspaceId) return;
      await services.switchWorkspace(target);
      if (context.mounted) context.go('/');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çalışma alanı değiştirilemedi. Tekrar deneyin.'),
          ),
        );
      }
    }
  }

  Future<void> signOut() async {
    try {
      await StoreBillingService.signOutIfConfigured();
    } catch (_) {
      // Mağaza servisi çıkışı, uygulama oturumundan çıkmayı engellememeli.
    }
    if (services.config.hasSupabase) {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
    }
    await services.sessions.clear();
    services.clearIdentityContext();
    onSignedOut();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Daha fazla')),
    body: ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.map_outlined),
          title: const Text('Saha haritası'),
          subtitle: const Text('Yakındaki müşteriler ve ziyaret rotası'),
          onTap: () => context.push('/map'),
        ),
        ListTile(
          leading: const Icon(Icons.mic_none),
          title: const Text('Ziyaretler ve sesli not'),
          subtitle: const Text(
            'Kullanıcı onayından önce kurumsal hafızaya eklenmez',
          ),
          onTap: () => context.push('/visits'),
        ),
        ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('Eşitleme merkezi'),
          subtitle: const Text('Bekleyen kayıtlar ve hatalar'),
          onTap: () => context.push('/offline'),
        ),
        const Divider(),
        if (services.config.hasSupabase)
          ListTile(
            leading: const Icon(Icons.swap_horiz_outlined),
            title: const Text('Çalışma alanı değiştir'),
            onTap: () => chooseWorkspace(context),
          ),
        ListTile(
          leading: const Icon(Icons.calendar_month_outlined),
          title: const Text('Takvim'),
          subtitle: const Text('Planlanan ziyaretler ve tarihli görevler'),
          onTap: () => context.push('/calendar'),
        ),
        ListTile(
          leading: const Icon(Icons.history_toggle_off_outlined),
          title: const Text('Aktivite'),
          subtitle: const Text('Ziyaret, görev, fırsat ve sipariş geçmişi'),
          onTap: () => context.push('/activity'),
        ),
        ListTile(
          leading: const Icon(Icons.analytics_outlined),
          title: const Text('Rapor özeti'),
          subtitle: const Text('Müşteri, ziyaret ve görev göstergeleri'),
          onTap: () => context.push('/reports'),
        ),
        ListTile(
          leading: const Icon(Icons.notifications_none),
          title: const Text('Bildirimler'),
          subtitle: const Text('Yorumlar, görevler ve onay olayları'),
          onTap: () => context.push('/notifications'),
        ),
        ListTile(
          leading: const Icon(Icons.trending_up),
          title: const Text('Fırsatlar'),
          subtitle: const Text('Satış pipeline ve aşama görünümü'),
          onTap: () => context.push('/opportunities'),
        ),
        ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: const Text('Ürün ve fiyatlar'),
          subtitle: const Text('Aktif ürün kataloğu ve liste fiyatları'),
          onTap: () => context.push('/products'),
        ),
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('Sipariş taslakları'),
          subtitle: const Text('Taslak ve onay durumlarını görüntüleyin'),
          onTap: () => context.push('/orders'),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Belgeler'),
          subtitle: const Text('Dosya ve güvenlik tarama durumları'),
          onTap: () => context.push('/documents'),
        ),
        ListTile(
          leading: const Icon(Icons.dynamic_form_outlined),
          title: const Text('Saha formları'),
          subtitle: const Text('Aktif şablonlar ve gönderimler'),
          onTap: () => context.push('/forms'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.business_outlined),
          title: const Text('Firma bilgileri'),
          subtitle: const Text('Çalışma alanınızın firma adını düzenleyin'),
          onTap: () => context.push('/company-info'),
        ),
        ListTile(
          leading: const Icon(Icons.workspace_premium_outlined),
          title: const Text('Premium ve abonelik'),
          subtitle: const Text(
            'Planınızı görüntüleyin veya mağaza satın alımını yönetin',
          ),
          onTap: () => context.push('/premium'),
        ),
        // Bu iki madde ayar değil, ürünün verdiği söz. Daha önce `ListTile`
        // olarak duruyorlardı ve tıklanmadıkları için bozuk düğme gibi
        // görünüyorlardı. "Dil" satırı kaldırıldı: alt metni İngilizce
        // altyapısının hazır olduğunu söylüyordu ama arayüz dili
        // `app.dart` içinde Türkçe'ye sabit.
        const _PromiseCard(
          icon: Icons.location_off_outlined,
          title: 'Konum gizliliği',
          body:
              'Sürekli GPS takibi yapılmaz. Konum yalnızca siz istediğinizde '
              'ya da saha modunu başlattığınızda alınır; saha modu çalışırken '
              'bunu gizlemez ve akşam kendiliğinden kapanır.',
        ),
        const _PromiseCard(
          icon: Icons.graphic_eq,
          title: 'Ses saklama',
          body:
              'Sesli not yalnızca metne çevrilmek için gönderilir. Ham kayıt '
              'yöneticilere açılmaz ve 30 gün sonra sunucudan silinir.',
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('KVKK ve veri hakları'),
          subtitle: const Text('Aydınlatma, dışa aktarma ve silme merkezi'),
          onTap: () => context.push('/privacy'),
        ),
        ListTile(
          leading: Icon(
            Icons.delete_forever_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            'Hesabımı sil',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          subtitle: const Text(
            'Hesabınızı ve kişisel verilerinizi kalıcı olarak silin',
          ),
          onTap: () => context.push('/privacy?delete=true'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Tüm cihazlardan çıkış'),
          onTap: signOut,
        ),
        const _AppVersionTile(),
      ],
    ),
  );
}

/// Ayar değil, bilgi. Dokunulabilir görünmemesi için `ListTile` kullanılmaz.
class _PromiseCard extends StatelessWidget {
  const _PromiseCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 14),
          child: Icon(icon, size: 22),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(body, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Sürüm ve derleme numarasını gösterir.
///
/// Kapalı testte her yükleme "1.0.0" göründüğü için testçi hangi derlemeyi
/// kullandığını söyleyemiyordu; hata bildirimlerinde derleme numarası şart.
class _AppVersionTile extends StatelessWidget {
  const _AppVersionTile();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform(),
    builder: (context, snapshot) {
      final info = snapshot.data;
      final label = info == null
          ? 'Sürüm bilgisi yükleniyor…'
          : 'Sürüm ${info.version} · Derleme ${info.buildNumber}';
      return ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('Uygulama sürümü'),
        subtitle: Text(label),
        // Hata bildirirken kopyalanabilsin.
        onTap: info == null
            ? null
            : () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${info.packageName} $label'),
                  duration: const Duration(seconds: 4),
                ),
              ),
      );
    },
  );
}
