import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../app/ui/page_navigation.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';
import 'open_source_licenses_screen.dart';

class CreditsScreen extends StatefulWidget {
  final AppState state;
  final AssetBundle? assetBundle;
  const CreditsScreen({super.key, required this.state, this.assetBundle});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  late final Future<({List<_CreditRecord> sounds, List<_CreditRecord> photos})>
  _credits = _loadCredits();
  final PageController _details = PageController(keepPage: false);
  int _group = 0;
  int _record = 0;
  int _detailPage = 0;

  Future<({List<_CreditRecord> sounds, List<_CreditRecord> photos})>
  _loadCredits() async {
    final bundle = widget.assetBundle ?? rootBundle;
    final sounds =
        jsonDecode(await bundle.loadString('assets/sfx/sources.json')) as List;
    final photoManifest =
        jsonDecode(
              await bundle.loadString(
                'assets/content/real_photo_manifest.json',
              ),
            )
            as Map<String, dynamic>;
    final photoEntries = flattenRealPhotoCreditEntries(
      photoManifest['assets'] as List,
    );
    return (
      sounds: sounds.map((item) => _CreditRecord.fromSound(item)).toList(),
      photos: photoEntries
          .map((item) => _CreditRecord.fromPhoto(item))
          .toList(),
    );
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  void _resetDetails() {
    _detailPage = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _details.hasClients) _details.jumpToPage(0);
    });
  }

  void _setGroup(int group) {
    if (group == _group) return;
    setState(() {
      _group = group;
      _record = 0;
      _resetDetails();
    });
  }

  void _moveRecord(int delta, int count) {
    final next = _record + delta;
    if (next < 0 || next >= count) return;
    setState(() {
      _record = next;
      _resetDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, widget.state.locale);
    return Scaffold(
      backgroundColor: SegColors.familyCanvas,
      appBar: AppBar(
        backgroundColor: SegColors.familyCanvas,
        title: Text(l10n.creditsTitle),
        actions: [
          IconButton(
            key: const ValueKey('credits-open-source-licenses'),
            tooltip: l10n.creditsOpenSourceLicenses,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OpenSourceLicensesScreen(state: widget.state),
              ),
            ),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body:
          FutureBuilder<
            ({List<_CreditRecord> sounds, List<_CreditRecord> photos})
          >(
            future: _credits,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(l10n.creditsLoadFailure));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final records = _group == 0
                  ? snapshot.data!.sounds
                  : snapshot.data!.photos;
              if (records.isEmpty) return const SizedBox.shrink();
              _record = _record.clamp(0, records.length - 1);
              final selected = records[_record];
              final pages = _detailGroups(
                selected,
                l10n: l10n,
                splitDetails:
                    MediaQuery.textScalerOf(context).scale(1) >= 1.6 ||
                    MediaQuery.sizeOf(context).height <= 400,
              );
              _detailPage = _detailPage.clamp(0, pages.length - 1);
              final groupRow = Padding(
                padding: const EdgeInsets.symmetric(horizontal: SegSpace.s2),
                child: PillToggle<int>(
                  values: const [0, 1],
                  selected: _group,
                  label: (g) => g == 0
                      ? l10n.creditsAnimalRecordings
                      : l10n.creditsRealPhotographs,
                  icon: (g) =>
                      g == 0 ? Icons.graphic_eq_rounded : Icons.photo_rounded,
                  onChanged: _setGroup,
                ),
              );
              // Upright: every attribution in one scrolling list.
              if (MediaQuery.orientationOf(context) == Orientation.portrait) {
                return Column(
                  children: [
                    const SizedBox(height: SegSpace.s2),
                    groupRow,
                    Expanded(
                      child: ListView.separated(
                        key: ValueKey('credits-list-$_group'),
                        padding: const EdgeInsets.all(SegSpace.s4),
                        itemCount: records.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: SegSpace.s3),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final fields = _detailGroups(
                            record,
                            l10n: l10n,
                            splitDetails: false,
                          ).expand((group) => group);
                          return SegCard(
                            padding: const EdgeInsets.all(SegSpace.s4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.title,
                                  key: ValueKey(
                                    'credits-record-title-$_group-$index',
                                  ),
                                  style: SegText.item,
                                ),
                                const SizedBox(height: SegSpace.s2),
                                for (final field in fields)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: SegSpace.s1,
                                    ),
                                    child: _creditField(
                                      field,
                                      recordIndex: index,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SegSpace.s2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _groupButton(
                            key: const ValueKey('credits-group-sounds'),
                            label: l10n.creditsAnimalRecordings,
                            selected: _group == 0,
                            onPressed: () => _setGroup(0),
                          ),
                        ),
                        const SizedBox(width: SegSpace.s2),
                        Expanded(
                          child: _groupButton(
                            key: const ValueKey('credits-group-photos'),
                            label: l10n.creditsRealPhotographs,
                            selected: _group == 1,
                            onPressed: () => _setGroup(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SegSpace.s2,
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: PageView.builder(
                          key: const ValueKey('credits-detail-pages'),
                          controller: _details,
                          itemCount: pages.length,
                          onPageChanged: (index) =>
                              setState(() => _detailPage = index),
                          itemBuilder: (context, pageIndex) => Padding(
                            // Keep more of a short landscape viewport for the
                            // complete attribution page while retaining the
                            // standard horizontal card inset.
                            padding: const EdgeInsets.symmetric(
                              horizontal: SegSpace.s2,
                              vertical: SegSpace.s1,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected.title,
                                  key: ValueKey(
                                    'credits-record-title-$_group-$_record',
                                  ),
                                  style: SegText.item,
                                ),
                                const SizedBox(height: SegSpace.s1),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (
                                        var fieldIndex = 0;
                                        fieldIndex < pages[pageIndex].length;
                                        fieldIndex++
                                      )
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: SegSpace.s1,
                                          ),
                                          child: _creditField(
                                            pages[pageIndex][fieldIndex],
                                            recordIndex: _record,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _navigation(
                    recordCount: records.length,
                    pageCount: pages.length,
                    l10n: l10n,
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _groupButton({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onPressed,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: SegSpace.s1),
    child: OutlinedButton(
      key: key,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: selected ? SegColors.primary : SegColors.surface,
        foregroundColor: selected ? Colors.white : SegColors.ink,
        side: BorderSide(
          color: selected ? SegColors.primary : SegColors.line,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SegRadius.md),
        ),
      ),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );

  List<List<_CreditField>> _detailGroups(
    _CreditRecord record, {
    required AppLocalizations l10n,
    required bool splitDetails,
  }) {
    final attribution = <_CreditField>[
      _CreditField('author', l10n.creditsAuthor, record.author),
      _CreditField('license', l10n.creditsLicense, record.license),
      if (record.adaptationLicense case final value?)
        _CreditField(
          'adaptation-license',
          l10n.creditsAdaptationLicense,
          value,
        ),
      if (record.previousAuthor case final value?)
        _CreditField('previous-author', l10n.creditsPreviousImageCredit, value),
    ];
    final source = <_CreditField>[
      _CreditField('source', l10n.creditsSource, record.source, isUrl: true),
      _CreditField(
        'license-url',
        l10n.creditsLicenseLink,
        record.licenseUrl,
        isUrl: true,
      ),
    ];
    final changes = _CreditField(
      'changes',
      l10n.creditsChanges,
      record.isPhoto
          ? l10n.creditsImagePreparedForAppUse
          : l10n.creditsAudioEditedForInAppPlayback,
    );
    if (splitDetails) {
      return [
        ...attribution.map((field) => [field]),
        ...source.map((field) => [field]),
        [changes],
      ];
    }
    return [
      [...attribution, ...source, changes],
    ];
  }

  Widget _creditField(_CreditField field, {required int recordIndex}) {
    final content = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${field.label}: ',
            style: SegText.caption.copyWith(fontWeight: FontWeight.w800),
          ),
          TextSpan(text: field.value, style: SegText.caption),
        ],
      ),
      key: ValueKey('credits-field-$recordIndex-${field.keyName}'),
      softWrap: !field.isUrl,
    );
    return field.isUrl
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: content,
          )
        : content;
  }

  Widget _navigation({
    required int recordCount,
    required int pageCount,
    required AppLocalizations l10n,
  }) => Row(
    children: [
      IconButton(
        key: const ValueKey('credits-previous-record'),
        tooltip: l10n.creditsPreviousRecord,
        onPressed: _record == 0 ? null : () => _moveRecord(-1, recordCount),
        icon: const Icon(Icons.skip_previous_rounded),
      ),
      IconButton(
        key: const ValueKey('credits-previous-detail'),
        tooltip: l10n.gamePreviousPage,
        onPressed: _detailPage == 0
            ? null
            : () => navigatePage(
                context: context,
                controller: _details,
                page: _detailPage - 1,
                reducedMotion: widget.state.reducedMotion,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
              ),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      Expanded(
        child: Center(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${_record + 1} / $recordCount',
                  children: [
                    const TextSpan(text: '  ·  '),
                    TextSpan(text: '${_detailPage + 1} / $pageCount'),
                  ],
                ),
              ],
            ),
            key: const ValueKey('credits-record-counter'),
            textAlign: TextAlign.center,
            semanticsLabel: l10n.creditsRecordDetailProgress(
              _record + 1,
              recordCount,
              _detailPage + 1,
              pageCount,
            ),
          ),
        ),
      ),
      IconButton(
        key: const ValueKey('credits-next-detail'),
        tooltip: l10n.gameNextPage,
        onPressed: _detailPage == pageCount - 1
            ? null
            : () => navigatePage(
                context: context,
                controller: _details,
                page: _detailPage + 1,
                reducedMotion: widget.state.reducedMotion,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
              ),
        icon: const Icon(Icons.arrow_forward_rounded),
      ),
      IconButton(
        key: const ValueKey('credits-next-record'),
        tooltip: l10n.creditsNextRecord,
        onPressed: _record == recordCount - 1
            ? null
            : () => _moveRecord(1, recordCount),
        icon: const Icon(Icons.skip_next_rounded),
      ),
    ],
  );
}

List<Map<String, dynamic>> flattenRealPhotoCreditEntries(List entries) {
  final flattened = <Map<String, dynamic>>[];
  for (final value in entries) {
    final entry = Map<String, dynamic>.from(value as Map);
    final additional = entry['additionalVariants'] as List? ?? const [];
    final primary = Map<String, dynamic>.from(entry)
      ..remove('additionalVariants');
    if (additional.isEmpty) {
      flattened.add(primary);
      continue;
    }
    flattened.add({...primary, 'id': '${entry['id']} #1'});
    for (var index = 0; index < additional.length; index++) {
      final variant = Map<String, dynamic>.from(additional[index] as Map);
      flattened.add({...variant, 'id': '${entry['id']} #${index + 2}'});
    }
  }
  return flattened;
}

class _CreditField {
  final String keyName;
  final String label;
  final String value;
  final bool isUrl;
  const _CreditField(
    this.keyName,
    this.label,
    this.value, {
    this.isUrl = false,
  });
}

class _CreditRecord {
  final String title;
  final String author;
  final String license;
  final String source;
  final String licenseUrl;
  final String? adaptationLicense;
  final String? previousAuthor;
  final bool isPhoto;

  const _CreditRecord({
    required this.title,
    required this.author,
    required this.license,
    required this.source,
    required this.licenseUrl,
    required this.isPhoto,
    this.adaptationLicense,
    this.previousAuthor,
  });

  factory _CreditRecord.fromSound(dynamic item) => _CreditRecord(
    title: item['title'].toString(),
    author: item['author'].toString(),
    license: item['license'].toString(),
    source: item['source'].toString(),
    licenseUrl: item['licenseUrl'].toString(),
    isPhoto: false,
  );

  factory _CreditRecord.fromPhoto(dynamic item) => _CreditRecord(
    title: item['id'].toString(),
    author: item['author'].toString(),
    license: item['license'].toString(),
    source: item['source'].toString(),
    licenseUrl: item['licenseUrl'].toString(),
    isPhoto: true,
    adaptationLicense: item['adaptationLicense']?.toString(),
    previousAuthor: item['existingBackgroundRemoval']?.toString(),
  );
}
