import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/mobile_services.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.services,
    required this.onSignedOut,
  });
  final MobileServices services;
  final VoidCallback onSignedOut;
  Future<void> signOut() async {
    if (services.config.hasSupabase) {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
    }
    await services.sessions.clear();
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
        ListTile(
          leading: const Icon(Icons.calendar_month_outlined),
          title: const Text('Takvim'),
          subtitle: const Text('Planlanan ziyaretler ve tarihli görevler'),
          onTap: () => context.push('/calendar'),
        ),
        ListTile(
          leading: const Icon(Icons.history_toggle_off_outlined),
          title: const Text('Aktivite'),
          subtitle: const Text('Son onaylanan saha ziyaretleri'),
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
        const ListTile(
          leading: Icon(Icons.language),
          title: Text('Dil'),
          subtitle: Text('Türkçe · İngilizce altyapısı hazır'),
        ),
        const ListTile(
          leading: Icon(Icons.location_off_outlined),
          title: Text('Konum gizliliği'),
          subtitle: Text(
            'Sürekli GPS kapalı; yalnızca açık işlemle kullanılır',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.graphic_eq),
          title: Text('Ses saklama'),
          subtitle: Text('Ham ses varsayılan olarak yöneticiye kapalı'),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('KVKK ve veri hakları'),
          subtitle: const Text('Aydınlatma, dışa aktarma ve silme merkezi'),
          onTap: () => context.push('/privacy'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Tüm cihazlardan çıkış'),
          onTap: signOut,
        ),
      ],
    ),
  );
}
