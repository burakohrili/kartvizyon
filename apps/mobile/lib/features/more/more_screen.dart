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
