import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/mobile_services.dart';
import '../../l10n/app_localizations.dart';

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
      throw const MobileApiException(409, 'AI summary unavailable');
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
    final l10n = AppLocalizations.of(context)!;
    if (summaryController.text.trim().length < 10 || originalSummary == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.summaryMinLength)));
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
      final createdTasks = selectedFollowUps.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            createdTasks == 0
                ? l10n.visitApprovedMemory
                : l10n.visitApprovedTasks(createdTasks),
          ),
        ),
      );
      context.go('/visits');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.summaryApprovalFailed)));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// AI özeti işe yaramazsa ziyareti reddeder.
  ///
  /// Tek çıkış "Onayla ve hafızaya ekle" idi; kötü bir özetle karşılaşan
  /// kullanıcının yapabileceği bir şey yoktu ve ziyaret sonsuza kadar
  /// inceleme kuyruğunda kalıyordu. Reddedilen ziyaret silinmez, yalnız
  /// kurumsal hafızaya girmez.
  Future<void> reject() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.rejectSummaryDialogTitle),
        content: Text(l10n.rejectSummaryDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.reject),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => busy = true);
    try {
      await widget.services.api.post(
        '/api/visits/${widget.visitId}/reject',
        const {},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.summaryRejected)));
      context.go('/visits');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.summaryRejectFailed)));
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewAiSummary)),
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
                  snapshot.error is MobileApiException
                      ? l10n.aiSummaryNotFound
                      : l10n.reviewLoadFailed,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final data = snapshot.data!;
          final company = data['company'] as Map? ?? {};
          final sensitive =
              originalSummary?['sensitiveContentDetected'] == true;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                company['name']?.toString() ?? l10n.customerVisit,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(l10n.aiOutputApprovalNotice),
              // Uyarı listenin dibinde duruyordu; onay düğmesine inen kullanıcı
              // görmeden geçebiliyordu.
              if (sensitive) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(l10n.sensitiveDataWarning),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              TextField(
                controller: summaryController,
                minLines: 5,
                maxLines: 9,
                maxLength: 1200,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: l10n.visitSummary,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: outcome,
                decoration: InputDecoration(labelText: l10n.outcome),
                items: [
                  DropdownMenuItem(
                    value: 'positive',
                    child: Text(l10n.positive),
                  ),
                  DropdownMenuItem(value: 'neutral', child: Text(l10n.neutral)),
                  DropdownMenuItem(
                    value: 'negative',
                    child: Text(l10n.negative),
                  ),
                  DropdownMenuItem(value: 'unknown', child: Text(l10n.unknown)),
                ],
                onChanged: busy
                    ? null
                    : (value) => setState(() => outcome = value ?? 'unknown'),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.suggestedFollowUps,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (followUps.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(l10n.noFollowUpsFound),
                )
              else
                ...List.generate(
                  followUps.length,
                  (index) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selectedFollowUps.contains(index),
                    title: Text(
                      followUps[index]['title']?.toString() ??
                          l10n.followUpFallback,
                    ),
                    // Tarih ve sorumlu ipucu gösterilmiyordu; onaylanan takip
                    // veritabanı trigger'ı ile bu tarihten göreve yazılıyor,
                    // yani kullanıcı görmediği bir tarihi onaylıyordu.
                    subtitle: Text(
                      _followUpDetail(followUps[index], l10n, locale),
                    ),
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
              // Özetin kaynağı. Karşılaştıracak metin olmadan yapılan onay,
              // onay değil kabuldür.
              if ((data['transcript']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 18),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(l10n.transcript),
                  subtitle: Text(l10n.compareSummarySource),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(data['transcript'].toString()),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: busy ? null : approve,
                icon: const Icon(Icons.verified_outlined),
                label: Text(busy ? l10n.approving : l10n.approveAndAddMemory),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: busy ? null : reject,
                icon: const Icon(Icons.block_outlined),
                label: Text(l10n.rejectAiSummary),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Takip önerisinin tarihi ve sorumlu ipucu.
  static String _followUpDetail(
    Map<String, dynamic> followUp,
    AppLocalizations l10n,
    String locale,
  ) {
    final parts = <String>[];
    final due = followUp['dueDate']?.toString();
    if (due != null && due.isNotEmpty) {
      final parsed = DateTime.tryParse(due);
      parts.add(
        parsed == null
            ? l10n.dueDatePrefix(due)
            : l10n.dueDatePrefix(
                locale == 'en'
                    ? '${parsed.month}/${parsed.day}/${parsed.year}'
                    : '${parsed.day.toString().padLeft(2, '0')}.${parsed.month.toString().padLeft(2, '0')}.${parsed.year}',
              ),
      );
    } else {
      parts.add(l10n.undated);
    }
    final owner = followUp['ownerHint']?.toString();
    if (owner != null && owner.isNotEmpty) parts.add(owner);
    return parts.join(' · ');
  }
}
