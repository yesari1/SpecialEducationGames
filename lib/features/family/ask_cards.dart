import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../app/app_state.dart';
import '../../app/app_version.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import '../../core/auth/family_auth.dart';
import '../../core/sync/admin_link.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';

/// Shows [card] as a pop-up in the middle of the screen; it closes only
/// through its own buttons.
Future<void> showAskDialog(BuildContext context, Widget card) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      // The rounded pop-up stays put; a tall survey scrolls inside it.
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SegRadius.xl),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: SegSpace.s4,
          vertical: SegSpace.s6,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(child: card),
        ),
      ),
    );

/// Family area, once after a little play (anket-tasarimi.md): satisfaction
/// (five faces), who uses the app, what to improve, and a note. Sent to
/// `feedback/{autoId}` with `kind: 'survey'`; every answer is also written
/// as readable Turkish text in `message`, the improvements as `choices` ids.
class SurveyCard extends StatefulWidget {
  final AppState state;
  final FamilyAuth? auth;
  const SurveyCard({super.key, required this.state, this.auth});
  @override
  State<SurveyCard> createState() => _SurveyCardState();
}

/// Improvement ids (Firestore `choices`) with the Turkish text for `message`.
const _improvements = [
  ('more_games', 'Daha fazla oyun'),
  ('more_themes', 'Daha fazla tema/kategori'),
  ('lower_price', 'Daha uygun fiyat'),
  ('better_voices', 'Seslendirme'),
  ('better_reports', 'Daha detaylı raporlar'),
];

const _users = ['Ebeveyn', 'Öğretmen', 'Özel eğitim uzmanı/terapist', 'Diğer'];

const _faces = [
  Icons.sentiment_very_dissatisfied_rounded,
  Icons.sentiment_dissatisfied_rounded,
  Icons.sentiment_neutral_rounded,
  Icons.sentiment_satisfied_rounded,
  Icons.sentiment_very_satisfied_rounded,
];

const _faceColors = [
  Color(0xFFE5533D),
  Color(0xFFF08A3C),
  Color(0xFFF2B636),
  Color(0xFF7CC04B),
  Color(0xFF2EAD6B),
];

class _SurveyCardState extends State<SurveyCard> {
  int? _rating; // 1..5
  int? _user;
  final _picked = <int>{};
  final _note = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<String> _options(AppLocalizations l10n) => [
    l10n.askSurveyMoreGames,
    l10n.askSurveyMoreThemes,
    l10n.askSurveyPrice,
    l10n.askSurveyVoices,
    l10n.askSurveyReports,
  ];

  List<String> _userOptions(AppLocalizations l10n) => [
    l10n.askSurveyUserParent,
    l10n.askSurveyUserTeacher,
    l10n.askSurveyUserSpecialist,
    l10n.askSurveyUserOther,
  ];

  Future<void> _send() async {
    final s = widget.state;
    final l10n = scopedLocalizations(context, s.locale);
    final note = _note.text.trim();
    final picked = _picked.toList()..sort();
    final message = [
      if (_rating != null) 'Memnuniyet: $_rating/5',
      if (_user != null) 'Kullanan: ${_users[_user!]}',
      if (picked.isNotEmpty)
        'Geliştirilsin: ${picked.map((i) => _improvements[i].$2).join(', ')}',
      if (note.isNotEmpty) 'Not: $note',
    ].join('\n');
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
        'kind': 'survey',
        if (picked.isNotEmpty)
          'choices': [for (final i in picked) _improvements[i].$1],
      });
      if (!mounted) return;
      showNotice(
        context,
        l10n.feedbackSent,
        icon: Icons.check_circle_rounded,
        color: SegColors.turquoise,
      );
      await s.closeSurvey();
      if (mounted) Navigator.of(context).maybePop();
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

  Widget _question(String text) => Padding(
    padding: const EdgeInsets.only(top: SegSpace.s3, bottom: SegSpace.s1),
    child: Text(text, style: SegText.item.copyWith(color: SegColors.ink)),
  );

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final l10n = scopedLocalizations(context, s.locale);
    final options = _options(l10n);
    final users = _userOptions(l10n);
    final canSend =
        !_sending &&
        (_rating != null ||
            _user != null ||
            _picked.isNotEmpty ||
            _note.text.trim().isNotEmpty);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: double.infinity),
      child: SegCard(
        key: const ValueKey('survey-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Satisfaction.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: SegSpace.s2),
                    child: Text(
                      l10n.askSurveySatisfaction,
                      style: SegText.heading,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('survey-close'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () {
                    UiSound.tap();
                    s.closeSurvey();
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: SegSpace.s1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 5; i++)
                  Semantics(
                    button: true,
                    selected: _rating == i + 1,
                    label: '${i + 1}/5',
                    child: InkResponse(
                      key: ValueKey('survey-face-${i + 1}'),
                      radius: 30,
                      onTap: () {
                        UiSound.tap();
                        setState(() => _rating = i + 1);
                      },
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 150),
                        scale: _rating == i + 1 ? 1.25 : 1,
                        child: Icon(
                          _faces[i],
                          size: 42,
                          color: _rating == i + 1
                              ? _faceColors[i]
                              : _rating == null
                              ? _faceColors[i].withValues(alpha: .4)
                              : SegColors.line,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // 2. Who uses it.
            _question(l10n.askSurveyWho),
            Wrap(
              spacing: SegSpace.s2,
              runSpacing: SegSpace.s2,
              children: [
                for (var i = 0; i < users.length; i++)
                  ChoiceChip(
                    key: ValueKey('survey-user-$i'),
                    label: Text(users[i]),
                    visualDensity: VisualDensity.compact,
                    selected: _user == i,
                    showCheckmark: false,
                    selectedColor: SegColors.primarySoft,
                    side: BorderSide(
                      color: _user == i ? SegColors.primary : SegColors.line,
                    ),
                    labelStyle: SegText.body.copyWith(
                      color: _user == i ? SegColors.primaryDeep : SegColors.ink,
                      fontWeight: _user == i ? FontWeight.w800 : null,
                    ),
                    onSelected: (_) {
                      UiSound.tap();
                      setState(() => _user = i);
                    },
                  ),
              ],
            ),
            // 3. What to improve.
            _question(l10n.askSurveyImprove),
            for (var i = 0; i < options.length; i++)
              CheckboxListTile(
                key: ValueKey('survey-option-$i'),
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _picked.contains(i),
                title: Text(options[i], style: SegText.body),
                onChanged: (v) {
                  UiSound.tap();
                  setState(() {
                    if (v == true) {
                      _picked.add(i);
                    } else {
                      _picked.remove(i);
                    }
                  });
                },
              ),
            const SizedBox(height: SegSpace.s2),
            TextField(
              key: const ValueKey('survey-note'),
              controller: _note,
              maxLength: 1000,
              minLines: 1,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.askSurveyNote,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SegRadius.lg),
                ),
              ),
            ),
            const SizedBox(height: SegSpace.s2),
            SegButton(
              key: const ValueKey('survey-send'),
              label: l10n.feedbackSend,
              onPressed: canSend ? _send : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Google Play's own in-app rating card (In-App Review), shown directly
/// with no question before it (Play's rules). Play decides whether it
/// appears; the app asks again after a month at the earliest.
Future<void> requestPlayReview(AppState state) async {
  await state.closeRating(later: true);
  try {
    final review = InAppReview.instance;
    if (await review.isAvailable()) await review.requestReview();
  } catch (_) {
    // Play is not reachable; the next try is a month later.
  }
}
