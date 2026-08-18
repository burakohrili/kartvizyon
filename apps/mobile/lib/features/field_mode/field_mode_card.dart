import 'package:flutter/material.dart';

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
        await widget.service.stop(reason: 'Saha modu kapatıldı.');
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
    return '$hour:$minute itibarıyla kendiliğinden kapanır';
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: widget.service.isActive,
    builder: (context, active, _) => Card(
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
                    active ? 'Saha modu açık' : 'Saha modu kapalı',
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
                  ? 'Yakınından geçtiğin müşteriler hatırlatılıyor. '
                        '${_endsAtLabel()}'
                  : 'Açtığınızda, yakınından geçtiğiniz müşteriyi ve en son ne '
                        'zaman ziyaret ettiğinizi hatırlatır. Konumunuz '
                        'kaydedilmez; mod kapalıyken hiç çalışmaz.',
            ),
            ValueListenableBuilder<String?>(
              valueListenable: widget.service.lastMessage,
              builder: (context, message, _) => message == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        message,
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
                onPressed: busy ? null : _toggle,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        active ? Icons.stop_circle_outlined : Icons.play_arrow,
                      ),
                label: Text(
                  active ? 'Saha modunu bitir' : 'Saha modunu başlat',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
