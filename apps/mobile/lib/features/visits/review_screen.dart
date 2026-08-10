import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/mobile_services.dart';

class VisitReviewScreen extends StatefulWidget {
  const VisitReviewScreen({
    super.key,
    required this.services,
    required this.visitId,
  });

  final MobileServices services;
  final String visitId;

  @override
  State<VisitReviewScreen> createState() => _VisitReviewScreenState();
}

class _VisitReviewScreenState extends State<VisitReviewScreen> {
  late Future<Map<String, dynamic>> visit;
  final summaryController = TextEditingController();
  Map<String, dynamic>? originalSummary;
  List<Map<String, dynamic>> followUps = [];
  Set<int> selectedFollowUps = {};
  String outcome = 'unknown';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    visit = load();
  }

  Future<Map<String, dynamic>> load() async {
    final response =
        await widget.services.api.get('/api/visits/${widget.visitId}')
            as Map<String, dynamic>;
    final data = Map<String, dynamic>.from(response['data'] as Map);
    final summary = data['ai_summary'] as Map?;
    if (summary == null) {
      throw const MobileApiException(409, 'İncelenecek AI özeti bulunamadı.');
    }
    originalSummary = Map<String, dynamic>.from(summary);
    summaryController.text = summary['summary']?.toString() ?? '';
    outcome = summary['outcome']?.toString() ?? 'unknown';
    followUps = List<Map<String, dynamic>>.from(
      summary['followUps'] as List? ?? [],
    );
    selectedFollowUps = Set<int>.from(
      List<int>.generate(followUps.length, (index) => index),
    );
    return data;
  }

  Future<void> approve() async {
    if (summaryController.text.trim().length < 10 || originalSummary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Özet en az 10 karakter olmalıdır.')),
      );
      return;
    }
    setState(() => busy = true);
    try {
      await widget.services.api.post('/api/visits/${widget.visitId}/approve', {
        'summary': {
          ...originalSummary!,
          'summary': summaryController.text.trim(),
          'outcome': outcome,
          'followUps': [
            for (var index = 0; index < followUps.length; index++)
              if (selectedFollowUps.contains(index)) followUps[index],
          ],
        },
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ziyaret onaylandı ve hafızaya eklendi.')),
      );
      context.go('/visits');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI özetini incele')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: visit,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final company = data['company'] as Map? ?? {};
        final sensitive = originalSummary?['sensitiveContentDetected'] == true;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              company['name']?.toString() ?? 'Müşteri ziyareti',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'AI çıktısı siz onaylamadan kurumsal hafızaya eklenmez.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: summaryController,
              minLines: 5,
              maxLines: 9,
              maxLength: 1200,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Ziyaret özeti',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: outcome,
              decoration: const InputDecoration(labelText: 'Sonuç'),
              items: const [
                DropdownMenuItem(value: 'positive', child: Text('Olumlu')),
                DropdownMenuItem(value: 'neutral', child: Text('Nötr')),
                DropdownMenuItem(value: 'negative', child: Text('Olumsuz')),
                DropdownMenuItem(value: 'unknown', child: Text('Belirsiz')),
              ],
              onChanged: busy
                  ? null
                  : (value) => setState(() => outcome = value ?? 'unknown'),
            ),
            const SizedBox(height: 18),
            Text(
              'Önerilen takipler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (followUps.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('Takip önerisi bulunamadı.'),
              )
            else
              ...List.generate(
                followUps.length,
                (index) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selectedFollowUps.contains(index),
                  title: Text(followUps[index]['title']?.toString() ?? 'Takip'),
                  onChanged: busy
                      ? null
                      : (selected) => setState(() {
                          if (selected == true) {
                            selectedFollowUps.add(index);
                          } else {
                            selectedFollowUps.remove(index);
                          }
                        }),
                ),
              ),
            if (sensitive)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Hassas kişisel veri olasılığı var. Onaylamadan önce özeti düzenleyin.',
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: busy ? null : approve,
              icon: const Icon(Icons.verified_outlined),
              label: Text(busy ? 'Onaylanıyor…' : 'Onayla ve hafızaya ekle'),
            ),
          ],
        );
      },
    ),
  );
}
