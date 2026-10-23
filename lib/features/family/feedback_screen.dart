import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/app_version.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import '../../core/auth/family_auth.dart';
import '../../core/sync/admin_link.dart';
import '../../l10n/scoped_localizations.dart';

/// Family › Settings › Send feedback: one text box and "Send". The message
/// goes to `feedback/{autoId}`; the app never reads feedback back.
class FeedbackScreen extends StatefulWidget {
  final AppState state;
  final FamilyAuth? auth;
  const FeedbackScreen({super.key, required this.state, this.auth});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = widget.state;
    final l10n = scopedLocalizations(context, s.locale);
    final message = _text.text.trim();
    if (message.isEmpty || _sending) return;
    setState(() => _sending = true);
    final account = widget.auth?.account;
    try {
      await s.adminLink.feedback({
        'message': message.length > 2000 ? message.substring(0, 2000) : message,
        'createdAt': serverNow(),
        'uid': account?.uid,
        'email': account?.email,
        'installId': s.installId,
        'appVersion': appVersion,
        'locale': s.locale == 'tr' ? 'tr' : 'en',
        'platform': 'android',
      });
      if (!mounted) return;
      showNotice(
        context,
        l10n.feedbackSent,
        icon: Icons.check_circle_rounded,
        color: SegColors.turquoise,
      );
      context.go('/family');
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      showNotice(
        context,
        l10n.feedbackFailed,
        icon: Icons.error_outline_rounded,
        color: SegColors.accent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final l10n = scopedLocalizations(context, s.locale);
    return Listener(
      onPointerDown: (_) => s.touchFamily(),
      child: Scaffold(
        backgroundColor: SegColors.familyCanvas,
        appBar: AppBar(
          title: Text(l10n.feedbackTitle),
          leading: IconButton(
            onPressed: () {
              UiSound.tap();
              context.go('/family');
            },
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SegSpace.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.feedbackIntro,
                  style: SegText.body.copyWith(color: SegColors.inkSoft),
                ),
                const SizedBox(height: SegSpace.s3),
                TextField(
                  key: const ValueKey('feedback-text'),
                  controller: _text,
                  maxLength: 2000,
                  minLines: 5,
                  maxLines: 5,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SegRadius.lg),
                    ),
                  ),
                ),
                const SizedBox(height: SegSpace.s4),
                SegButton(
                  key: const ValueKey('feedback-send'),
                  label: l10n.feedbackSend,
                  onPressed: _text.text.trim().isEmpty || _sending
                      ? null
                      : _send,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
