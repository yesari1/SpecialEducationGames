import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/ui/components.dart';
import '../../app/ui/page_navigation.dart';
import '../../core/config/announcement_repository.dart';
import '../../core/config/parent_announcement.dart';
import '../../l10n/scoped_localizations.dart';

/// Parent-only plain text. Construction and absent IDs never initiate a fetch.
class ParentAnnouncementCard extends StatefulWidget {
  final AppState state;
  final AnnouncementRepository? repository;
  const ParentAnnouncementCard({
    super.key,
    required this.state,
    this.repository,
  });

  @override
  State<ParentAnnouncementCard> createState() => _ParentAnnouncementCardState();
}

class _ParentAnnouncementCardState extends State<ParentAnnouncementCard> {
  late final AnnouncementRepository _repository;
  final PageController _pages = PageController();
  ParentAnnouncement? _announcement;
  String? _id;
  String? _locale;
  bool _authorized = false;
  int _generation = 0;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AnnouncementRepository(widget.state.db);
    widget.state.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _changed();
    });
  }

  bool _valid(int generation, String id) =>
      mounted &&
      generation == _generation &&
      widget.state.familyUnlocked &&
      widget.state.configuration.announcementId == id;

  void _changed() {
    final id = widget.state.configuration.announcementId;
    final authorized = widget.state.familyUnlocked;
    final locale = widget.state.locale;
    if (_locale != locale) {
      _locale = locale;
      if (_page != 0) _resetPage();
    }
    if (id != _id || authorized != _authorized) {
      _id = id;
      _authorized = authorized;
      _generation++;
      _announcement = null;
      _resetPage();
      if (authorized && id != null) unawaited(_load(id, _generation));
    }
    if (mounted) setState(() {});
  }

  Future<void> _load(String id, int generation) async {
    try {
      final cached = await _repository.load(id);
      if (!_valid(generation, id)) return;
      setState(() => _announcement = cached);
      final refreshed = await _repository.refresh(id);
      if (_valid(generation, id)) setState(() => _announcement = refreshed);
    } catch (_) {
      // Unavailable news must never interrupt local play or expose SDK errors.
    }
  }

  @override
  void dispose() {
    _generation++;
    _pages.dispose();
    widget.state.removeListener(_changed);
    super.dispose();
  }

  void _resetPage() {
    _page = 0;
    if (_pages.hasClients) _pages.jumpToPage(0);
  }

  List<_AnnouncementTextPage> _textPages({
    required String title,
    required String body,
    required TextStyle titleStyle,
    required TextStyle bodyStyle,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required double width,
    required double maxTextHeight,
  }) => [
    ..._splitText(
      title,
      style: titleStyle,
      textDirection: textDirection,
      textScaler: textScaler,
      width: width,
      maxHeight: maxTextHeight,
    ).map((text) => _AnnouncementTextPage(text, titleStyle, isTitle: true)),
    ..._splitText(
      body,
      style: bodyStyle,
      textDirection: textDirection,
      textScaler: textScaler,
      width: width,
      maxHeight: maxTextHeight,
    ).map((text) => _AnnouncementTextPage(text, bodyStyle, isTitle: false)),
  ];

  List<String> _splitText(
    String text, {
    required TextStyle style,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required double width,
    required double maxHeight,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
    );
    try {
      painter.layout(maxWidth: width);
      final metrics = painter.computeLineMetrics();
      if (metrics.isEmpty) return [text];

      final lineEnds = <int>[];
      var lineOffset = 0;
      while (lineOffset < text.length) {
        final boundary = painter.getLineBoundary(
          TextPosition(offset: lineOffset, affinity: TextAffinity.downstream),
        );
        var end = boundary.end;
        if (end <= lineOffset) end = lineOffset + 1;
        if (end < text.length && text.codeUnitAt(end) == 0x0a) end++;
        lineEnds.add(end);
        lineOffset = end;
      }

      final chunks = <String>[];
      var firstLine = 0;
      var offset = 0;
      while (firstLine < lineEnds.length) {
        var lastLine = firstLine;
        var height =
            metrics[firstLine < metrics.length ? firstLine : metrics.length - 1]
                .height;
        while (lastLine + 1 < lineEnds.length &&
            height +
                    metrics[lastLine + 1 < metrics.length
                            ? lastLine + 1
                            : metrics.length - 1]
                        .height <=
                maxHeight) {
          lastLine++;
          height +=
              metrics[lastLine < metrics.length ? lastLine : metrics.length - 1]
                  .height;
        }

        // Keep explicit newline characters in a neighboring chunk so joining
        // the pages reconstructs the source exactly.
        final end = lineEnds[lastLine];
        chunks.add(text.substring(offset, end));
        offset = end;
        firstLine = lastLine + 1;
      }
      if (offset < text.length) chunks.add(text.substring(offset));
      return chunks;
    } finally {
      painter.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final title = _announcement?.localizedTitle(state.locale);
    final body = _announcement?.localizedBody(state.locale);
    if (!state.familyUnlocked || _id == null || title == null || body == null) {
      return const SizedBox.shrink();
    }
    if (_locale != state.locale) {
      _locale = state.locale;
      _resetPage();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox.expand(
        child: SegCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final theme = Theme.of(context);
              final headingStyle = theme.textTheme.labelLarge;
              final heading = scopedLocalizations(
                context,
                state.locale,
              ).familyNewsHeading;
              final titleStyle =
                  theme.textTheme.titleLarge ?? const TextStyle();
              final bodyStyle = theme.textTheme.bodyMedium ?? const TextStyle();
              final textScaler = MediaQuery.textScalerOf(context);
              final direction = Directionality.of(context);
              final headingPainter = TextPainter(
                text: TextSpan(text: heading, style: headingStyle),
                textDirection: direction,
                textScaler: textScaler,
              );
              late final double headingHeight;
              try {
                headingPainter.layout(maxWidth: constraints.maxWidth);
                headingHeight = headingPainter.height;
              } finally {
                headingPainter.dispose();
              }
              final textHeight =
                  (constraints.maxHeight - headingHeight - 8 - 56)
                      .clamp(1.0, math.max(1.0, constraints.maxHeight))
                      .toDouble();
              final textPages = _textPages(
                title: title,
                body: body,
                titleStyle: titleStyle,
                bodyStyle: bodyStyle,
                textDirection: direction,
                textScaler: textScaler,
                width: constraints.maxWidth,
                maxTextHeight: textHeight,
              );
              if (_page >= textPages.length) {
                _page = textPages.length - 1;
                final clampedPage = _page;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _pages.hasClients) {
                    _pages.jumpToPage(clampedPage);
                  }
                });
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(heading, style: headingStyle),
                  const SizedBox(height: 8),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: textPages.length,
                      onPageChanged: (index) => setState(() => _page = index),
                      itemBuilder: (context, index) => Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          textPages[index].text,
                          style: textPages[index].style,
                          key: ValueKey(
                            'announcement-${textPages[index].isTitle ? 'title' : 'body'}-page-$index',
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).previousPageTooltip,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: _page == 0
                            ? null
                            : () => navigatePage(
                                context: context,
                                controller: _pages,
                                page: _page - 1,
                                reducedMotion: state.reducedMotion,
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                              ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${_page + 1} / ${textPages.length}',
                            key: const ValueKey('announcement-page-indicator'),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).nextPageTooltip,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: _page >= textPages.length - 1
                            ? null
                            : () => navigatePage(
                                context: context,
                                controller: _pages,
                                page: _page + 1,
                                reducedMotion: state.reducedMotion,
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                              ),
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AnnouncementTextPage {
  final String text;
  final TextStyle style;
  final bool isTitle;
  const _AnnouncementTextPage(this.text, this.style, {required this.isTitle});
}
