import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/page_navigation.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';

class OpenSourceLicensesScreen extends StatefulWidget {
  const OpenSourceLicensesScreen({super.key, required this.state});

  final AppState state;

  @override
  State<OpenSourceLicensesScreen> createState() =>
      _OpenSourceLicensesScreenState();
}

class _OpenSourceLicensesScreenState extends State<OpenSourceLicensesScreen> {
  static Future<List<_PackageLicense>>? _licenseCache;
  late final Future<List<_PackageLicense>> _licenses = _licenseCache ??=
      _loadLicenses();
  final PageController _packages = PageController(keepPage: false);
  int _package = 0;

  Future<List<_PackageLicense>> _loadLicenses() async {
    final byPackage = <String, List<_LicenseParagraph>>{};
    await for (final entry in LicenseRegistry.licenses) {
      final paragraphs = entry.paragraphs
          .map(
            (paragraph) => _LicenseParagraph(paragraph.text, paragraph.indent),
          )
          .toList(growable: false);
      for (final name in entry.packages) {
        byPackage
            .putIfAbsent(name, () => <_LicenseParagraph>[])
            .addAll(paragraphs);
      }
    }
    return byPackage.entries
        .map((entry) => _PackageLicense(entry.key, entry.value))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  void dispose() {
    _packages.dispose();
    super.dispose();
  }

  void _movePackage(int delta, int count) {
    final next = _package + delta;
    if (next < 0 || next >= count) return;
    setState(() => _package = next);
    navigatePage(
      context: context,
      controller: _packages,
      page: next,
      reducedMotion: widget.state.reducedMotion,
      duration: SegMotion.pageSlide,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, widget.state.locale);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.creditsOpenSourceLicenses)),
      body: FutureBuilder<List<_PackageLicense>>(
        future: _licenses,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l10n.creditsLicensesLoadFailure));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final packages = snapshot.data!;
          if (packages.isEmpty) {
            return Center(child: Text(l10n.creditsLicensesEmpty));
          }
          _package = _package.clamp(0, packages.length - 1);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SegSpace.s2,
                  vertical: SegSpace.s1,
                ),
                child: Row(
                  children: [
                    _packageButton(
                      key: const ValueKey('license-previous-package'),
                      label: l10n.gamePrevious,
                      enabled: _package > 0,
                      onPressed: () => _movePackage(-1, packages.length),
                    ),
                    Expanded(
                      child: Text(
                        l10n.onboardingStepCount(_package + 1, packages.length),
                        key: const ValueKey('license-package-counter'),
                        textAlign: TextAlign.center,
                        style: SegText.label,
                      ),
                    ),
                    _packageButton(
                      key: const ValueKey('license-next-package'),
                      label: l10n.gameNext,
                      enabled: _package + 1 < packages.length,
                      onPressed: () => _movePackage(1, packages.length),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  key: const ValueKey('license-package-pages'),
                  controller: _packages,
                  itemCount: packages.length,
                  onPageChanged: (index) => setState(() => _package = index),
                  itemBuilder: (context, index) => _PackageLicensePage(
                    key: ValueKey('license-package-${packages[index].name}'),
                    package: packages[index],
                    packageIndex: index,
                    strings: l10n,
                    reducedMotion: widget.state.reducedMotion,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _packageButton({
    required Key key,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) => OutlinedButton(
    key: key,
    onPressed: enabled ? onPressed : null,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(88, 48),
      foregroundColor: SegColors.primaryDeep,
      side: const BorderSide(color: SegColors.primary, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SegRadius.md),
      ),
    ),
    child: Text(label),
  );
}

class _PackageLicensePage extends StatefulWidget {
  const _PackageLicensePage({
    super.key,
    required this.package,
    required this.packageIndex,
    required this.strings,
    required this.reducedMotion,
  });

  final _PackageLicense package;
  final int packageIndex;
  final AppLocalizations strings;
  final bool reducedMotion;

  @override
  State<_PackageLicensePage> createState() => _PackageLicensePageState();
}

class _PackageLicensePageState extends State<_PackageLicensePage> {
  late final PageController _details = PageController(keepPage: false);
  int _detail = 0;
  (double, double, double)? _paginationLayout;
  List<List<_LicenseFragment>>? _pagination;
  bool _pageCorrectionScheduled = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: SegSpace.s2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.package.name,
          key: ValueKey('license-package-name-${widget.packageIndex}'),
          style: SegText.item,
          textAlign: TextAlign.center,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scaler = MediaQuery.textScalerOf(context);
              final licenseTextStyle = _resolvedLicenseTextStyle(context);
              final layout = (
                constraints.maxWidth,
                constraints.maxHeight,
                scaler.scale(SegText.caption.fontSize!),
              );
              if (_pagination == null || _paginationLayout != layout) {
                final layoutChanged = _paginationLayout != null;
                _paginationLayout = layout;
                _pagination = _paginateLicense(
                  widget.package.paragraphs,
                  width: constraints.maxWidth - SegSpace.s4,
                  height:
                      constraints.maxHeight -
                      (SegSpace.s2 * 2) - // Card's vertical margin.
                      SegSpace.s4 - // Card content padding.
                      48, // Detail-page navigation buttons.
                  textScaler: scaler,
                  textStyle: licenseTextStyle,
                  textDirection: Directionality.of(context),
                );
                final targetPage = _detail.clamp(0, _pagination!.length - 1);
                _detail = targetPage;
                if (layoutChanged) _schedulePageCorrection(targetPage);
              }
              final pages = _pagination!;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: SegSpace.s1),
                child: Padding(
                  padding: const EdgeInsets.all(SegSpace.s2),
                  child: PageView.builder(
                    key: ValueKey(
                      'license-text-pages-${widget.package.name}-${pages.length}',
                    ),
                    controller: _details,
                    itemCount: pages.length,
                    onPageChanged: (index) => setState(() => _detail = index),
                    itemBuilder: (context, pageIndex) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final fragment in pages[pageIndex])
                                if (fragment.paragraphEnd)
                                  const SizedBox(height: SegSpace.s2)
                                else
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: fragment.indent > 0
                                          ? fragment.indent * SegSpace.s4
                                          : 0,
                                    ),
                                    child: fragment.horizontalPan
                                        ? SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: _licenseText(
                                              context,
                                              fragment,
                                            ),
                                          )
                                        : _licenseText(context, fragment),
                                  ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _detailButton(
                              key: const ValueKey('license-previous-page'),
                              label: widget.strings.gamePrevious,
                              enabled: _detail > 0,
                              onPressed: () => _moveDetail(-1, pages.length),
                            ),
                            Expanded(
                              child: Text(
                                widget.strings.onboardingStepCount(
                                  _detail + 1,
                                  pages.length,
                                ),
                                key: const ValueKey('license-page-counter'),
                                textAlign: TextAlign.center,
                                style: SegText.caption,
                              ),
                            ),
                            _detailButton(
                              key: const ValueKey('license-next-page'),
                              label: widget.strings.gameNext,
                              enabled: _detail + 1 < pages.length,
                              onPressed: () => _moveDetail(1, pages.length),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  void _moveDetail(int delta, int count) {
    final next = _detail + delta;
    if (next < 0 || next >= count) return;
    setState(() => _detail = next);
    navigatePage(
      context: context,
      controller: _details,
      page: next,
      reducedMotion: widget.reducedMotion,
      duration: SegMotion.pageSlide,
      curve: Curves.easeOutCubic,
    );
  }

  void _schedulePageCorrection(int targetPage) {
    if (_pageCorrectionScheduled) return;
    _pageCorrectionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageCorrectionScheduled = false;
      if (!mounted || !_details.hasClients) return;
      if (_details.page?.round() != targetPage) _details.jumpToPage(targetPage);
    });
  }

  Widget _detailButton({
    required Key key,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) => OutlinedButton(
    key: key,
    onPressed: enabled ? onPressed : null,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(88, 48),
      foregroundColor: SegColors.primaryDeep,
      side: const BorderSide(color: SegColors.primary, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SegRadius.md),
      ),
    ),
    child: Text(label),
  );

  Widget _licenseText(BuildContext context, _LicenseFragment fragment) => Text(
    fragment.text,
    key: ValueKey(
      'license-fragment-${widget.packageIndex}-${fragment.paragraphIndex}-${fragment.fragmentIndex}',
    ),
    style: _resolvedLicenseTextStyle(context),
    textAlign: fragment.centered ? TextAlign.center : TextAlign.start,
    softWrap: !fragment.horizontalPan,
  );
}

TextStyle _resolvedLicenseTextStyle(BuildContext context) =>
    DefaultTextStyle.of(context).style.merge(
      SegText.caption.copyWith(fontFamily: 'Nunito', color: SegColors.ink),
    );

List<List<_LicenseFragment>> _paginateLicense(
  List<_LicenseParagraph> paragraphs, {
  required double width,
  required double height,
  required TextScaler textScaler,
  required TextStyle textStyle,
  required TextDirection textDirection,
}) {
  const paragraphGap = SegSpace.s2;
  final pages = <List<_LicenseFragment>>[<_LicenseFragment>[]];
  var usedHeight = 0.0;
  for (
    var paragraphIndex = 0;
    paragraphIndex < paragraphs.length;
    paragraphIndex++
  ) {
    final paragraph = paragraphs[paragraphIndex];
    final indent = paragraph.indent > 0 ? paragraph.indent * SegSpace.s4 : 0.0;
    final availableWidth = (width - indent).clamp(1.0, width);
    final tokens = RegExp(r'\s+|\S+').allMatches(paragraph.text);
    var buffer = '';
    var fragmentIndex = 0;
    var paragraphHasContent = false;

    void startNewPage() {
      if (pages.last.isNotEmpty) pages.add(<_LicenseFragment>[]);
      usedHeight = 0;
    }

    void commitBuffer() {
      if (buffer.isEmpty) return;
      pages.last.add(
        _LicenseFragment(
          paragraphIndex: paragraphIndex,
          fragmentIndex: fragmentIndex++,
          text: buffer,
          indent: paragraph.indent,
          centered: paragraph.indent == LicenseParagraph.centeredIndent,
          paragraphEnd: false,
        ),
      );
      usedHeight += _measureTextHeight(
        buffer,
        textStyle,
        availableWidth,
        textScaler,
        textDirection: textDirection,
      );
      buffer = '';
      paragraphHasContent = true;
    }

    for (final token in tokens) {
      final tokenText = token.group(0)!;
      if (tokenText.length > 128 && !RegExp(r'\s').hasMatch(tokenText)) {
        commitBuffer();
        final lineHeight = _measureTextHeight(
          tokenText,
          textStyle,
          availableWidth,
          textScaler,
          softWrap: false,
          textDirection: textDirection,
        );
        if (usedHeight + lineHeight > height && pages.last.isNotEmpty) {
          startNewPage();
        }
        pages.last.add(
          _LicenseFragment(
            paragraphIndex: paragraphIndex,
            fragmentIndex: fragmentIndex++,
            text: tokenText,
            indent: paragraph.indent,
            centered: paragraph.indent == LicenseParagraph.centeredIndent,
            horizontalPan: true,
            paragraphEnd: false,
          ),
        );
        usedHeight += lineHeight;
        paragraphHasContent = true;
        continue;
      }
      final candidate = '$buffer$tokenText';
      final candidateHeight = _measureTextHeight(
        candidate,
        textStyle,
        availableWidth,
        textScaler,
        textDirection: textDirection,
      );
      if (buffer.isEmpty &&
          usedHeight > 0 &&
          usedHeight + candidateHeight > height) {
        startNewPage();
      }
      if (buffer.isNotEmpty && usedHeight + candidateHeight > height) {
        commitBuffer();
        startNewPage();
      }
      buffer += tokenText;
      if (usedHeight +
                  _measureTextHeight(
                    buffer,
                    textStyle,
                    availableWidth,
                    textScaler,
                    textDirection: textDirection,
                  ) >
              height &&
          buffer.length > 1) {
        final lastSpace = buffer.lastIndexOf(RegExp(r'\s'));
        if (lastSpace > 0) {
          final tail = buffer.substring(lastSpace + 1);
          buffer = buffer.substring(0, lastSpace + 1);
          commitBuffer();
          startNewPage();
          buffer = tail;
        }
      }
    }
    commitBuffer();
    if (paragraphIndex + 1 < paragraphs.length && paragraphHasContent) {
      if (usedHeight + paragraphGap > height && pages.last.isNotEmpty) {
        startNewPage();
      } else {
        usedHeight += paragraphGap;
      }
      pages.last.add(
        _LicenseFragment(
          paragraphIndex: paragraphIndex,
          fragmentIndex: fragmentIndex,
          text: '',
          indent: 0,
          centered: false,
          paragraphEnd: true,
        ),
      );
    }
  }
  if (pages.length > 1 && pages.last.isEmpty) pages.removeLast();
  if (pages.isEmpty || (pages.length == 1 && pages.single.isEmpty)) {
    return [<_LicenseFragment>[]];
  }
  return pages;
}

double _measureTextHeight(
  String text,
  TextStyle style,
  double width,
  TextScaler textScaler, {
  bool softWrap = true,
  TextDirection textDirection = TextDirection.ltr,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    textScaler: textScaler,
  );
  try {
    painter.layout(maxWidth: softWrap ? width : double.infinity);
    return painter.height;
  } finally {
    painter.dispose();
  }
}

class _LicenseParagraph {
  const _LicenseParagraph(this.text, this.indent);
  final String text;
  final int indent;
}

class _PackageLicense {
  const _PackageLicense(this.name, this.paragraphs);
  final String name;
  final List<_LicenseParagraph> paragraphs;
}

class _LicenseFragment {
  const _LicenseFragment({
    required this.paragraphIndex,
    required this.fragmentIndex,
    required this.text,
    required this.indent,
    required this.centered,
    this.horizontalPan = false,
    required this.paragraphEnd,
  });
  final int paragraphIndex;
  final int fragmentIndex;
  final String text;
  final int indent;
  final bool centered;
  final bool horizontalPan;
  final bool paragraphEnd;
}
