import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../../core/mobile_services.dart';
import '../../l10n/app_localizations.dart';

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

  /// Not başına tek kimlik. Daha önce her gönderimde yenisi üretiliyordu;
  /// kullanıcı "gönderildi" yazısını görüp düğmeye bir kez daha bastığında
  /// kuyruğa ikinci bir kayıt giriyor ve aynı ziyaret iki kez işleniyordu.
  final clientMutationId = const Uuid().v4();

  bool recording = false;
  bool busy = false;

  /// Kayıt süresi. Ekran "60–90 saniyelik debrief" diyor ama sayaç yoktu;
  /// kullanıcı 20. saniyede mi 5. dakikada mı olduğunu bilemiyor, sunucudaki
  /// 25 MB sınırına ancak gönderirken çarpıyordu.
  Duration elapsed = Duration.zero;
  Timer? _tick;

  /// Hangi ziyaret için not yazıldığı; başlık yalnız "Ziyaret sonrası not"
  /// diyordu ve iki ziyaret açıkken ayırt edilemiyordu.
  String? companyName;

  /// Not bir kez kuyruğa alındıktan sonra ekran yeniden gönderim kabul etmez.
  bool submitted = false;
  String transcriptLanguage = 'tr';
  String? audioPath;
  String? message;

  @override
  void initState() {
    super.initState();
    loadCompany();
  }

  Future<void> loadCompany() async {
    try {
      final response =
          await widget.services.api.get('/api/visits/${widget.visitId}')
              as Map<String, dynamic>;
      final company = (response['data'] as Map?)?['company'] as Map?;
      if (!mounted) return;
      setState(() => companyName = company?['name']?.toString());
    } catch (_) {
      // Ad gösterilemezse not almaya engel değil; başlık genel kalır.
    }
  }

  Future<void> toggleRecording() async {
    final l10n = AppLocalizations.of(context)!;
    if (recording) {
      audioPath = await recorder.stop();
      _tick?.cancel();
      setState(() => recording = false);
      return;
    }
    try {
      await widget.services.requireWriteAccess();
    } on MobileApiException catch (_) {
      if (mounted) setState(() => message = l10n.writeAccessRequired);
      return;
    }
    if (!await recorder.hasPermission()) {
      setState(() => message = l10n.microphonePermissionDenied);
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
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!widget.services.canWrite) {
        recorder.stop().then((path) {
          if (mounted) {
            setState(() {
              audioPath = path;
              recording = false;
              message = l10n.accessExpiredDraftSaved;
            });
          }
        });
        _tick?.cancel();
        return;
      }
      setState(() => elapsed += const Duration(seconds: 1));
    });
    setState(() {
      recording = true;
      audioPath = path;
      elapsed = Duration.zero;
      message = null;
    });
  }

  static String _clock(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> save() async {
    final l10n = AppLocalizations.of(context)!;
    if (busy || submitted) return;
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
      language: transcriptLanguage,
      audioPath: audioPath,
      clientMutationId: clientMutationId,
    );
    submitted = true;
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
    if (result.synced > 0) {
      // Gönderim başarılıysa kullanıcı burada bekletilmez; sunucu ziyareti
      // `needs_review` yapıp inceleme adresini döndürüyor. Önce ekranda tek
      // satırlık bir mesaj yazıp duruyorduk ve kullanıcı ne olduğunu
      // anlamıyordu.
      transcript.clear();
      audioPath = null;
      context.pushReplacement('/visits/${widget.visitId}/review');
      return;
    }
    setState(() {
      busy = false;
      message = l10n.debriefQueuedOffline;
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    recorder.dispose();
    transcript.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.debriefTitle),
        bottom: companyName == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(companyName!),
                ),
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.debriefPrivacyNotice),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: transcriptLanguage,
            decoration: InputDecoration(labelText: l10n.noteAndAudioLanguage),
            items: [
              DropdownMenuItem(value: 'tr', child: Text(l10n.turkish)),
              DropdownMenuItem(value: 'en', child: Text(l10n.english)),
            ],
            onChanged: busy || submitted
                ? null
                : (value) => setState(
                    () => transcriptLanguage = value == 'en' ? 'en' : 'tr',
                  ),
          ),
          const SizedBox(height: 12),
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
                        ? l10n.recordingDuration(_clock(elapsed))
                        : audioPath != null
                        ? l10n.voiceNoteReady(_clock(elapsed))
                        : l10n.debriefDurationHint,
                  ),
                  // Uzun kayıt sunucunun 25 MB sınırına takılır; kullanıcı bunu
                  // gönderdikten sonra değil, kaydederken öğrenmeli.
                  if (recording && elapsed.inMinutes >= 5)
                    Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(l10n.longRecordingWarning),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: busy ? null : toggleRecording,
                    icon: Icon(recording ? Icons.stop : Icons.mic),
                    label: Text(
                      recording ? l10n.stopRecording : l10n.recordVoiceNote,
                    ),
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
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: l10n.manualNoteTranscript,
              hintText: l10n.notePrompt,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed:
                busy ||
                    submitted ||
                    (transcript.text.trim().isEmpty && audioPath == null)
                ? null
                : save,
            child: Text(busy ? l10n.sending : l10n.queueAndSend),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(message!),
            ),
          // Kuyrukta kalan not için çıkış yolu. Önce ekranda tek bir cümle
          // kalıyor ve kullanıcı sistem geri tuşunu bulmak zorundaydı.
          if (submitted)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: OutlinedButton(
                onPressed: () => context.go('/visits'),
                child: Text(l10n.backToVisits),
              ),
            ),
          if (audioPath != null)
            TextButton(
              onPressed: () async {
                await File(
                  audioPath!,
                ).delete().catchError((_) => File(audioPath!));
                setState(() => audioPath = null);
              },
              child: Text(l10n.deleteVoiceNote),
            ),
        ],
      ),
    );
  }
}
