import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../core/mobile_services.dart';

class DebriefScreen extends StatefulWidget {
  const DebriefScreen({
    super.key,
    required this.services,
    required this.visitId,
  });
  final MobileServices services;
  final String visitId;
  @override
  State<DebriefScreen> createState() => _DebriefScreenState();
}

class _DebriefScreenState extends State<DebriefScreen> {
  final recorder = AudioRecorder();
  final transcript = TextEditingController();
  bool recording = false;
  bool busy = false;
  String? audioPath;
  String? message;

  Future<void> toggleRecording() async {
    if (recording) {
      audioPath = await recorder.stop();
      setState(() => recording = false);
      return;
    }
    if (!await recorder.hasPermission()) {
      setState(
        () => message = 'Mikrofon izni verilmedi. Metinle devam edebilirsiniz.',
      );
      return;
    }
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(
      directory.path,
      'debrief-${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    await recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 16000,
      ),
      path: path,
    );
    setState(() {
      recording = true;
      audioPath = path;
      message = null;
    });
  }

  Future<void> save() async {
    if (recording) audioPath = await recorder.stop();
    setState(() {
      busy = true;
      recording = false;
    });
    await widget.services.queue.enqueueVisitDebrief(
      ownerId: widget.services.ownerId,
      workspaceId: widget.services.workspaceId,
      visitId: widget.visitId,
      transcript: transcript.text.trim(),
      audioPath: audioPath,
    );
    try {
      await widget.services.refreshContext();
    } catch (_) {
      // Kayıt zaten güvenli çevrimdışı kuyrukta; oturum veya ağ yeniden
      // kullanılabilir olduğunda eşitleme merkezinden tekrar gönderilir.
    }
    final result = await widget.services.sync.run(
      ownerId: widget.services.ownerId,
    );
    if (!mounted) return;
    setState(() {
      busy = false;
      message = result.synced > 0
          ? 'Not gönderildi; AI özeti kullanıcı incelemesine hazırlandığında görünecek.'
          : 'Not cihazda güvenle kuyruklandı. Bağlantı gelince otomatik gönderilecek.';
    });
  }

  @override
  void dispose() {
    recorder.dispose();
    transcript.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ziyaret sonrası not')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Bu kayıt müşteri görüşmesi değildir. Yalnızca ziyaret sonrası kişisel değerlendirmeniz kaydedilir.',
        ),
        const SizedBox(height: 18),
        Card(
          color: recording
              ? Theme.of(context).colorScheme.errorContainer
              : null,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Icon(recording ? Icons.graphic_eq : Icons.mic_none, size: 46),
                const SizedBox(height: 8),
                Text(
                  recording
                      ? 'Kayıt sürüyor'
                      : audioPath != null
                      ? 'Sesli not hazır'
                      : '60–90 saniyelik debrief',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: busy ? null : toggleRecording,
                  icon: Icon(recording ? Icons.stop : Icons.mic),
                  label: Text(recording ? 'Kaydı bitir' : 'Sesli not kaydet'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: transcript,
          onChanged: (_) => setState(() {}),
          minLines: 5,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Manuel not veya transkript',
            hintText: 'İhtiyaç, verilen söz ve sonraki adım…',
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed:
              busy || (transcript.text.trim().isEmpty && audioPath == null)
              ? null
              : save,
          child: Text(
            busy ? 'Gönderiliyor…' : 'Güvenli kuyruğa ekle ve gönder',
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(message!),
          ),
        if (audioPath != null)
          TextButton(
            onPressed: () async {
              await File(
                audioPath!,
              ).delete().catchError((_) => File(audioPath!));
              setState(() => audioPath = null);
            },
            child: const Text('Sesli notu sil'),
          ),
      ],
    ),
  );
}
