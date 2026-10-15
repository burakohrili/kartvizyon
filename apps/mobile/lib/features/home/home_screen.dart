import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/mobile_services.dart';
import '../field_mode/field_mode_card.dart';
import '../../core/refresh.dart';
import '../../l10n/app_localizations.dart';
import 'home_summary.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});

  final MobileServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeSummary> summary;

  @override
  void initState() {
    super.initState();
    summary = load();
    widget.services.screenRevision.addListener(_onScreenRevision);
    widget.services.activeTab.addListener(_onActiveTabChanged);
  }

  void _onScreenRevision() {
    if (mounted) {
      setState(() {
        summary = load();
      });
    }
  }

  void _onActiveTabChanged() {
    if (widget.services.activeTab.value == 0 && mounted) {
      setState(() {
        summary = load();
      });
    }
  }

  @override
  void dispose() {
    widget.services.screenRevision.removeListener(_onScreenRevision);
    widget.services.activeTab.removeListener(_onActiveTabChanged);
    super.dispose();
  }

  Future<HomeSummary> load() async {
    if (!widget.services.config.hasSupabase) {
      return const HomeSummary(
        plannedToday: 0,
        awaitingReview: 0,
        openVisits: 0,
        openTasks: 0,
      );
    }
    await widget.services.refreshContext();
    final results = await Future.wait([
      widget.services.api.get(
        '/api/visits?workspaceId=${widget.services.workspaceId}',
      ),
      widget.services.api.get(
        '/api/tasks?workspaceId=${widget.services.workspaceId}',
      ),
    ]);
    final visitsResponse = results[0] as Map<String, dynamic>;
    final tasksResponse = results[1] as Map<String, dynamic>;
    final visits = List<Map<String, dynamic>>.from(
      visitsResponse['data'] as List? ?? [],
    );
    final tasks = List<Map<String, dynamic>>.from(
      tasksResponse['data'] as List? ?? [],
    );
    return summarize(visits: visits, tasks: tasks, now: DateTime.now());
  }

  Future<void> refresh() async {
    final next = load();
    setState(() {
      summary = next;
    });
    await settleRefresh(next);
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: refresh,
    child: FutureBuilder<HomeSummary>(
      future: summary,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasData) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 280),
              Center(child: CircularProgressIndicator()),
            ],
          );
        }
        if (snapshot.hasError && !snapshot.hasData) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 180),
              const Icon(Icons.cloud_off_outlined, size: 42),
              const SizedBox(height: 12),
              Text(l10n.homeLoadFailed, textAlign: TextAlign.center),
              TextButton(onPressed: refresh, child: Text(l10n.tryAgain)),
            ],
          );
        }
        final data = snapshot.data!;
        final nextCompany = data.nextVisit?['company'] as Map?;
        final nextCompanyId = nextCompany?['id']?.toString();
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.services.displayName?.trim().isNotEmpty == true
                  ? l10n.greeting(widget.services.displayName!.trim())
                  : l10n.greetingAnonymous,
              style: Theme.of(context).textTheme.labelLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              widget.services.workspaceCompanyName?.trim().isNotEmpty == true
                  ? l10n.todaySummaryForCompany(
                      widget.services.workspaceCompanyName!.trim(),
                    )
                  : l10n.fieldSummary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            if (widget.services.workspaceCompanyName == null &&
                widget.services.config.hasSupabase) ...[
              Card(
                child: ListTile(
                  title: Text(l10n.completeCompanyDetails),
                  subtitle: Text(l10n.companyContextForSummary),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/company-setup'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            FieldModeCard(service: widget.services.fieldMode),
            const SizedBox(height: 12),
            _Metric(
              // Planlanan ziyaret yoksa açık ziyaret gösterilir; web takvimini
              // kullanmayan temsilci sürekli sıfır görmesin.
              label: data.plannedToday > 0 ? l10n.plannedVisit : l10n.openVisit,
              value:
                  '${data.plannedToday > 0 ? data.plannedToday : data.openVisits}',
              icon: Icons.route,
              onTap: () => context.go('/visits'),
            ),
            const SizedBox(height: 12),
            _Metric(
              label: l10n.pendingReview,
              value: '${data.awaitingReview}',
              icon: Icons.rate_review_outlined,
              onTap: () => context.go('/visits'),
            ),
            const SizedBox(height: 12),
            _Metric(
              label: l10n.openFollowUp,
              value: '${data.openTasks}',
              icon: Icons.task_alt,
              onTap: () => context.go('/tasks'),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.quickActions,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.mic, size: 18),
                          label: Text(l10n.visitNote),
                          onPressed: () => context.go('/visits'),
                        ),
                        ActionChip(
                          avatar: const Icon(
                            Icons.camera_alt_outlined,
                            size: 18,
                          ),
                          label: Text(l10n.scanBusinessCard),
                          onPressed: () => context.go('/customers'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.sync, size: 18),
                          label: Text(l10n.sync),
                          onPressed: () => context.push('/offline'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (data.nextVisit != null && nextCompanyId != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.memory),
                  title: Text(l10n.nextVisit),
                  subtitle: Text(
                    '${nextCompany?['name'] ?? l10n.workspace} · ${l10n.viewBriefing}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/briefings/$nextCompanyId'),
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined),
                  title: Text(l10n.firstCustomer),
                  subtitle: Text(l10n.addCustomerNextSteps),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/customers'),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      onTap: onTap,
    ),
  );
}
