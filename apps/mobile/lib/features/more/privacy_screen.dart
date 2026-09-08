import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/mobile_services.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({
    super.key,
    required this.services,
    this.openDeletion = false,
  });
  final MobileServices services;
  final bool openDeletion;
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  Map<String, bool> consents = {};
  List<Map<String, dynamic>> requests = [];
  String? message;
  bool submittingRequest = false;

  bool _hasOpenRequest(String kind) => requests.any((item) {
    final status = item['status']?.toString();
    return item['kind'] == kind &&
        const {'requested', 'processing', 'ready'}.contains(status);
  });

  String _openRequestMessage(String kind) => kind == 'deletion'
      ? 'Hesap silme talebiniz zaten açık. Güncel durumunu Taleplerim bölümünden takip edebilirsiniz.'
      : 'Dışa aktarma talebiniz zaten açık. Hazır olduğunda Taleplerim bölümünden indirebilirsiniz.';
  @override
  void initState() {
    super.initState();
    load();
    if (widget.openDeletion) {
      WidgetsBinding.instance.addPostFrameCallback((_) => confirmDeletion());
    }
  }

  Future<void> confirmDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabımı kalıcı olarak sil'),
        content: const Text(
          'Bu işlem hesabınızı, müşteri ve ziyaret kayıtlarınızı, görevlerinizi '
          've diğer kişisel verilerinizi kalıcı olarak siler. İşlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hesabımı sil'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await createRequest('deletion');
  }

  Future<void> load() async {
    if (!widget.services.config.hasSupabase) return;
    try {
      final result =
          await widget.services.api.get('/api/settings/privacy')
              as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        consents = {
          for (final item in List<Map<String, dynamic>>.from(
            result['consents'] as List? ?? [],
          ))
            item['purpose'].toString(): item['granted'] == true,
        };
        requests = List<Map<String, dynamic>>.from(
          result['requests'] as List? ?? [],
        );
      });
    } catch (error) {
      if (mounted) setState(() => message = error.toString());
    }
  }

  Future<void> update(String purpose, bool granted) async {
    setState(() => consents[purpose] = granted);
    try {
      await widget.services.api.patch('/api/settings/privacy', {
        'workspaceId': widget.services.workspaceId,
        'purpose': purpose,
        'granted': granted,
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          consents[purpose] = !granted;
          message = error.toString();
        });
      }
    }
  }

  Future<void> createRequest(String kind) async {
    if (!widget.services.config.hasSupabase) {
      setState(() => message = 'Demo modunda talep oluşturulmaz.');
      return;
    }
    if (submittingRequest) return;
    if (_hasOpenRequest(kind)) {
      setState(() => message = _openRequestMessage(kind));
      return;
    }

    setState(() {
      submittingRequest = true;
      message = null;
    });
    try {
      final result =
          await widget.services.api.post('/api/settings/privacy', {
                'workspaceId': widget.services.workspaceId,
                'kind': kind,
              })
              as Map<String, dynamic>;
      if (!mounted) return;
      setState(
        () => message = result['duplicate'] == true
            ? _openRequestMessage(kind)
            : kind == 'deletion'
            ? 'Hesap silme işlemi başlatıldı. Hesabınız ve kişisel verileriniz kalıcı olarak silinecek.'
            : 'Talebiniz güvenli biçimde alındı.',
      );
      await load();
    } on MobileApiException catch (error) {
      if (!mounted) return;
      // Sunucu güncellenmeden çalışan eski dağıtımlarda da 409 kullanıcıya
      // hata gibi görünmesin. Listeyi yenileyip mevcut talebi gösteririz.
      if (error.statusCode == 409) {
        await load();
        if (mounted) {
          setState(() => message = _openRequestMessage(kind));
        }
        return;
      }
      setState(() => message = error.message);
    } catch (error) {
      if (mounted) setState(() => message = error.toString());
    } finally {
      if (mounted) setState(() => submittingRequest = false);
    }
  }

  /// Hazır dışa aktarmayı imzalı bağlantıyla açar.
  ///
  /// Bağlantı 60 saniye geçerlidir; loglanmaz ve ekranda bırakılmaz.
  Future<void> download(String? id) async {
    if (id == null) return;
    try {
      final result =
          await widget.services.api.get('/api/settings/privacy/export/$id')
              as Map<String, dynamic>;
      final url = result['url']?.toString();
      if (url == null || url.isEmpty) throw StateError('boş bağlantı');
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => message = error is MobileApiException
            ? error.message
            : 'Dışa aktarma açılamadı. Kısa süre sonra tekrar deneyin.',
      );
    }
  }

  static String _statusLabel(String status) => switch (status) {
    'requested' => 'Alındı, sıraya girdi',
    'processing' => 'Hazırlanıyor',
    'ready' => 'Hazır',
    'completed' => 'Tamamlandı',
    'failed' => 'Hazırlanamadı',
    'rejected' => 'Reddedildi',
    _ => status,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('KVKK ve veri hakları')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Rıza tercihlerinizi değiştirebilir, verilerinizi dışa aktarma veya silme talebi oluşturabilirsiniz.',
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Ürün analitiği'),
          value: consents['product_analytics'] ?? false,
          onChanged: (value) => update('product_analytics', value),
        ),
        SwitchListTile(
          title: const Text('AI ile not işleme'),
          value: consents['ai_processing'] ?? false,
          onChanged: (value) => update('ai_processing', value),
        ),
        SwitchListTile(
          title: const Text('E-posta bildirimleri'),
          value: consents['email_notifications'] ?? false,
          onChanged: (value) => update('email_notifications', value),
        ),
        const Divider(),
        FilledButton.tonalIcon(
          onPressed: submittingRequest || _hasOpenRequest('export')
              ? null
              : () => createRequest('export'),
          icon: const Icon(Icons.download_outlined),
          label: Text(
            _hasOpenRequest('export')
                ? 'Dışa aktarma talebi açık'
                : 'Verilerimi dışa aktar',
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: submittingRequest || _hasOpenRequest('deletion')
              ? null
              : confirmDeletion,
          icon: const Icon(Icons.delete_outline),
          label: Text(
            _hasOpenRequest('deletion')
                ? 'Hesap silme talebi açık'
                : 'Hesabımı kalıcı olarak sil',
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(message!),
          ),
        if (requests.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Taleplerim',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...requests.map((item) {
            final status = item['status']?.toString() ?? 'requested';
            final ready = item['kind'] == 'export' && status == 'ready';
            return ListTile(
              title: Text(item['kind'] == 'export' ? 'Dışa aktarma' : 'Silme'),
              subtitle: Text(_statusLabel(status)),
              // Dosya hazır olduğu halde ekranda yalnız "ready" yazıyordu ve
              // indirme yolu hiç sunulmuyordu.
              trailing: ready
                  ? FilledButton.tonalIcon(
                      onPressed: () => download(item['id']?.toString()),
                      icon: const Icon(Icons.download),
                      label: const Text('İndir'),
                    )
                  : null,
            );
          }),
        ],
      ],
    ),
  );
}
