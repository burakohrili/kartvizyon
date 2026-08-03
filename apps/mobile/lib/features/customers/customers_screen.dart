import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/mobile_services.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key, required this.services});
  final MobileServices services;
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late Future<List<Map<String, dynamic>>> customers;
  @override
  void initState() {
    super.initState();
    customers = load();
  }

  Future<List<Map<String, dynamic>>> load() async {
    if (!widget.services.config.hasSupabase) {
      return const [
        {
          'id': 'demo-atlas',
          'name': 'Atlas Medikal',
          'address': 'Ümraniye, İstanbul',
        },
        {'id': 'demo-nova', 'name': 'Nova Otomasyon', 'address': 'Bursa'},
      ];
    }
    final result =
        await widget.services.api.get(
              '/api/customers?workspaceId=${widget.services.workspaceId}',
            )
            as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(result['data'] as List? ?? []);
  }

  Future<void> scanCard() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (!mounted || image == null) return;
    if (!widget.services.config.hasSupabase) {
      await _showOcr({
        'firstName': 'Ayşe',
        'lastName': 'Yılmaz',
        'companyName': 'Atlas Medikal',
        'title': 'Satın Alma Müdürü',
        'email': 'ayse@example.com',
        'phone': '+90 555 000 00 00',
      });
      return;
    }
    try {
      final result =
          await widget.services.api.postFile(
                '/api/contacts/ocr',
                field: 'image',
                filePath: image.path,
              )
              as Map<String, dynamic>;
      await _showOcr(Map<String, dynamic>.from(result['data'] as Map));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _showOcr(Map<String, dynamic> data) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Kartvizit alanlarını doğrulayın'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue:
                  '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
              decoration: const InputDecoration(labelText: 'Ad soyad'),
            ),
            TextFormField(
              initialValue: data['companyName']?.toString(),
              decoration: const InputDecoration(labelText: 'Firma'),
            ),
            TextFormField(
              initialValue: data['title']?.toString(),
              decoration: const InputDecoration(labelText: 'Unvan'),
            ),
            TextFormField(
              initialValue: data['phone']?.toString(),
              decoration: const InputDecoration(labelText: 'Telefon'),
            ),
            TextFormField(
              initialValue: data['email']?.toString(),
              decoration: const InputDecoration(labelText: 'E-posta'),
            ),
            const SizedBox(height: 12),
            const Text(
              'AI çıktısı otomatik kaydedilmez. Alanları doğruladıktan sonra müşteri veya kişi kaydına dönüştürün.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Doğruladım'),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Müşteriler'),
      actions: [
        IconButton(
          onPressed: scanCard,
          tooltip: 'Kartvizit tara',
          icon: const Icon(Icons.document_scanner_outlined),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: customers,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorView(
            message: snapshot.error.toString(),
            retry: () => setState(() => customers = load()),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Henüz müşteri yok.'));
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() => customers = load()),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final item = items[index];
              final name = item['name']?.toString() ?? 'Firma';
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      name
                          .substring(0, name.length < 2 ? name.length : 2)
                          .toUpperCase(),
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text(
                    item['address']?.toString() ?? 'Adres belirtilmedi',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/customers/${item['id']}'),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: retry, child: const Text('Tekrar dene')),
        ],
      ),
    ),
  );
}
