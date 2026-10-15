import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'field_mode_service.dart';

/// Saha modunu başlatan ve durumunu gösteren kart.
///
/// Modun açık olduğu kullanıcıdan gizlenmez: kart açıkken durumu ve bitiş
/// saatini yazar, Android'de ayrıca kalıcı sistem bildirimi, iOS'ta mavi konum
/// göstergesi görünür.
class FieldModeCard extends StatefulWidget {
  const FieldModeCard({super.key, required this.service});

  final FieldModeService service;

  @override
  State<FieldModeCard> createState() => _FieldModeCardState();
}

class _FieldModeCardState extends State<FieldModeCard> {
  bool busy = false;

  Future<void> _toggle() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      if (widget.service.isActive.value) {
        await widget.service.stop(reason: FieldModeMessage.stopped);
      } else {
        await widget.service.start();
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _endsAtLabel() {
    final endsAt = widget.service.endsAt;
    if (endsAt == null) return '';
    final hour = endsAt.hour.toString().padLeft(2, '0');
    final minute = endsAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: widget.service.isActive,
    builder: (context, active, _) {
      final strings = AppLocalizations.of(context)!;
      widget.service.setLocale(strings.localeName);
      final afterHours = !FieldModeService.canStartAt(DateTime.now());
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(active ? Icons.podcasts : Icons.podcasts_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      active ? strings.fieldModeOn : strings.fieldModeOff,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                active
                    ? strings.fieldModeActiveDescription(_endsAtLabel())
                    : strings.fieldModeInactiveDescription,
              ),
              ValueListenableBuilder<FieldModeMessage?>(
                valueListenable: widget.service.lastMessage,
                builder: (context, message, _) =>
                    message == null && !(afterHours && !active)
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _messageText(
                            strings,
                            message ?? FieldModeMessage.afterHours,
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: busy || (!active && afterHours) ? null : _toggle,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          active
                              ? Icons.stop_circle_outlined
                              : Icons.play_arrow,
                        ),
                  label: Text(
                    active ? strings.stopFieldMode : strings.startFieldMode,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  String _messageText(AppLocalizations strings, FieldModeMessage message) =>
      switch (message) {
        FieldModeMessage.locationServiceOff => strings.locationServiceOff,
        FieldModeMessage.locationPermission =>
          strings.fieldModeLocationPermission,
        FieldModeMessage.afterHours => strings.fieldModeAfterHours,
        FieldModeMessage.notificationPermission =>
          strings.fieldModeNotificationPermission,
        FieldModeMessage.locationUnavailable =>
          strings.fieldModeLocationUnavailable,
        FieldModeMessage.sessionExpired => strings.fieldModeSessionExpired,
        FieldModeMessage.accessRequired => strings.fieldModeAccessRequired,
        FieldModeMessage.startFailed => strings.fieldModeStartFailed,
        FieldModeMessage.locationCheckFailed =>
          strings.fieldModeLocationCheckFailed,
        FieldModeMessage.nearbyCustomersUpdateFailed =>
          strings.nearbyCustomersUpdateFailed,
        FieldModeMessage.sessionEnded => strings.fieldModeExpired,
        FieldModeMessage.stopped => strings.fieldModeStopped,
        FieldModeMessage.workspaceChanged => strings.fieldModeWorkspaceChanged,
      };
}
