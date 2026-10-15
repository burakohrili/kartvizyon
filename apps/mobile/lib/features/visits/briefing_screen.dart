import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/mobile_services.dart';
import '../../core/refresh.dart';
import '../../l10n/app_localizations.dart';
import '../tasks/task_list.dart';

class BriefingScreen extends StatefulWidget {
  const BriefingScreen({
    super.key,
    required this.services,
    required this.companyId,
  });

  final MobileServices services;
  final String companyId;

  @override
  State<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends State<BriefingScreen> {
  late Future<Map<String, dynamic>> briefing;
  bool starting = false;

  @override
  void initState() {
    super.initState();
    briefing = load();
  }

  Future<Map<String, dynamic>> load() async {
    await widget.services.refreshContext();
    final response =
        await widget.services.api.get('/api/briefings/${widget.companyId}')
            as Map<String, dynamic>;
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  Future<void> refresh() async {
    final next = load();
    setState(() => briefing = next);
    await settleRefresh(next);
  }

  /// Brifingden doğrudan ziyarete geçer.
  ///
  /// Ekran çıkmaz sokaktı: kullanıcı müşterinin kapısında kartı okuyor, sonra
  /// geri çıkıp Ziyaretler ekranından müşteriyi baştan seçmek zorunda
  /// kalıyordu.
  Future<void> startVisit(String companyName) async {
    if (starting) return;
    setState(() => starting = true);
    try {
      final response =
          await widget.services.api.post('/api/visits', {
                'workspaceId': widget.services.workspaceId,
                'organizationId': widget.services.organizationId,
                'companyId': widget.companyId,
                'purpose': AppLocalizations.of(
                  context,
                )!.briefingDefaultVisitPurpose,
                'startedAt': DateTime.now().toUtc().toIso8601String(),
                'clientMutationId': const Uuid().v4(),
              })
              as Map<String, dynamic>;
      final data = response['data'] as Map<String, dynamic>;
      if (!mounted) return;
      context.push('/visits/${data['id']}/debrief');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.briefingStartVisitFailed),
        ),
      );
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  Future<void> navigate(Map company) async {
    final latitude = company['latitude'];
    final longitude = company['longitude'];
    if (latitude == null || longitude == null) return;
    await launchUrl(
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  /// "12 gün önce" gibi; ziyaretin ne kadar eskidiği tek bakışta görünmeli.
  String _sinceLabel(Object? value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return '';
    final at = DateTime.tryParse(raw)?.toLocal();
    if (at == null) return '';
    final days = DateTime.now().difference(at).inDays;
    final l10n = AppLocalizations.of(context)!;
    if (days <= 0) return l10n.today;
    if (days == 1) return l10n.yesterday;
    return l10n.daysAgo(days);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.briefingTitle)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: briefing,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.briefingLoadFailed, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: refresh,
                      child: Text(l10n.briefingRetry),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snapshot.data!;
          final company = data['company'] as Map? ?? {};
          final memory = data['memory'] as Map?;
          final tasks = List<Map<String, dynamic>>.from(
            data['openTasks'] as List? ?? [],
          );
          final promises = List<Object?>.from(
            memory?['open_promises'] as List? ?? const [],
          );
          final lastVisit = data['lastApprovedVisit'] as Map?;
          final since = _sinceLabel(lastVisit?['approved_at']);
          final staleAfter = DateTime.tryParse(
            memory?['stale_after']?.toString() ?? '',
          );
          final stale =
              staleAfter != null && staleAfter.isBefore(DateTime.now().toUtc());
          final companyName =
              company['name']?.toString() ?? l10n.customerFallback;
          final canNavigate =
              company['latitude'] != null && company['longitude'] != null;

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  companyName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((company['address']?.toString() ?? '').isNotEmpty)
                  Text(company['address'].toString()),
                const SizedBox(height: 8),
                Text(
                  since.isEmpty
                      ? l10n.briefingNeverVisited
                      : l10n.lastApprovedVisit(since),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.customerMemoryCard,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Bayat kart sessizce eski bilgi verir; kullanıcı
                            // buna güvenip yanlış şey söyleyebilir.
                            if (stale)
                              Text(
                                l10n.updateRequired,
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          memory?['summary']?.toString() ??
                              l10n.noApprovedSummary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Verilen söz takibi ürünün ana vaadi; sunucu bu alanı
                // döndürüyordu ama ekran hiç basmıyordu.
                Text(
                  l10n.promisesCount(promises.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (promises.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(l10n.noOpenPromises),
                  )
                else
                  ...promises.map(
                    (promise) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.handshake_outlined),
                      title: Text(_promiseText(promise, l10n.promiseFallback)),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  l10n.openFollowUpsCount(tasks.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (tasks.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(l10n.noOpenFollowUps),
                  )
                else
                  ...tasks.map((task) {
                    final due = taskDueLabel(
                      task,
                      locale: Localizations.localeOf(context).languageCode,
                    );
                    final dueDate = taskDueDate(task);
                    final overdue =
                        dueDate != null && dueDate.isBefore(DateTime.now());
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        overdue
                            ? Icons.warning_amber_outlined
                            : Icons.task_alt_outlined,
                      ),
                      title: Text(
                        task['title']?.toString() ?? l10n.taskFallback,
                      ),
                      subtitle: due.isEmpty
                          ? null
                          : Text(
                              overdue
                                  ? '$due · ${l10n.overdue}'
                                  : l10n.dueDateLabel(due),
                            ),
                    );
                  }),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: starting ? null : () => startVisit(companyName),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    starting ? l10n.startingVisit : l10n.startVisitAndTakeNote,
                  ),
                ),
                if (canNavigate) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => navigate(company),
                    icon: const Icon(Icons.navigation_outlined),
                    label: Text(l10n.openNavigation),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Söz kaydı düz metin ya da `{title: …}` biçiminde gelebilir.
  static String _promiseText(Object? promise, String fallback) {
    if (promise is Map) {
      return promise['title']?.toString() ??
          promise['promise']?.toString() ??
          promise['text']?.toString() ??
          fallback;
    }
    return promise?.toString() ?? fallback;
  }
}
