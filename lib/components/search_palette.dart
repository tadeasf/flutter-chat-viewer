import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../utils/api_db/api_service.dart';
import '../utils/text_match.dart';
import 'avatar.dart';

/// Search across all conversations (Ctrl+K). Pops with the chosen hit
/// (`collectionName`, `timestamp_ms`, `_id`).
///
/// Substring is the default: the chats are Czech and whole-word search
/// misses other word forms. Whole words is faster and ranked, max 500.
class SearchPalette extends StatefulWidget {
  const SearchPalette({super.key});

  @override
  State<SearchPalette> createState() => _SearchPaletteState();
}

class _SearchPaletteState extends State<SearchPalette> {
  static const _headerHeight = 30.0;
  static const _hitHeight = 44.0;

  final _query = TextEditingController();
  final _scroll = ScrollController();
  bool _fast = false;
  bool _loading = false;
  String? _error;
  String? _searched;
  bool _searchedFast = false;
  Duration? _took;

  /// All hits of the last search; the filters below narrow them locally.
  List<Map<String, dynamic>> _all = [];
  int? _fromYear;
  int? _toYear;
  String? _chat;

  static int _year(Map<String, dynamic> h) =>
      DateTime.fromMillisecondsSinceEpoch(h['timestamp_ms'] as int? ?? 0).year;

  /// Applies the filters and groups the hits by conversation.
  void _regroup() {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final h in _all) {
      final name = h['collectionName'] as String? ?? '?';
      final year = _year(h);
      if (_chat != null && name != _chat) continue;
      if (_fromYear != null && year < _fromYear!) continue;
      if (_toYear != null && year > _toYear!) continue;
      groups.putIfAbsent(name, () => []).add(h);
    }
    final rows = <Object>[];
    final hitRows = <int>[];
    for (final MapEntry(key: name, value: list) in groups.entries) {
      if (!_searchedFast) {
        list.sort((a, b) => (b['timestamp_ms'] as int? ?? 0)
            .compareTo(a['timestamp_ms'] as int? ?? 0));
      }
      rows.add('$name · ${list.length}');
      for (final h in list) {
        hitRows.add(rows.length);
        rows.add(h);
      }
    }
    _rows = rows;
    _hitRows = hitRows;
    _selected = 0;
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Widget _filters(BuildContext context) {
    final years = {for (final h in _all) _year(h)}.toList()..sort();
    final chats = {for (final h in _all) h['collectionName'] as String? ?? '?'}
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    DropdownMenuItem<T?> item<T>(T? value, String label) =>
        DropdownMenuItem<T?>(value: value, child: Text(label));
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
      child: Wrap(
        spacing: Space.m,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('From', style: style),
          DropdownButton<int?>(
            value: _fromYear,
            isDense: true,
            items: [
              item(null, 'any year'),
              for (final y in years) item(y, '$y')
            ],
            onChanged: (v) => setState(() {
              _fromYear = v;
              _regroup();
            }),
          ),
          Text('to', style: style),
          DropdownButton<int?>(
            value: _toYear,
            isDense: true,
            items: [
              item(null, 'any year'),
              for (final y in years) item(y, '$y')
            ],
            onChanged: (v) => setState(() {
              _toYear = v;
              _regroup();
            }),
          ),
          Text('in', style: style),
          DropdownButton<String?>(
            value: _chat,
            isDense: true,
            items: [item(null, 'all chats'), for (final c in chats) item(c, c)],
            onChanged: (v) => setState(() {
              _chat = v;
              _regroup();
            }),
          ),
        ],
      ),
    );
  }

  /// Display rows: a conversation header (String) or a hit (Map).
  List<Object> _rows = [];
  List<int> _hitRows = [];
  int _selected = 0;

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    final watch = Stopwatch()..start();
    setState(() {
      _loading = true;
      _error = null;
      _searched = q;
      _searchedFast = _fast;
    });
    try {
      final hits = await ApiService.search(q, fast: _fast);
      if (!mounted || _searched != q) return;
      setState(() {
        _all = hits;
        _fromYear = null;
        _toYear = null;
        _chat = null;
        _loading = false;
        _took = watch.elapsed;
        _regroup();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  void _submit() {
    final q = _query.text.trim();
    if (q != _searched || _fast != _searchedFast || _hitRows.isEmpty) {
      _search();
    } else {
      _open(_selected);
    }
  }

  void _open(int hitIndex) {
    if (hitIndex < 0 || hitIndex >= _hitRows.length) return;
    Navigator.of(context)
        .pop(_rows[_hitRows[hitIndex]] as Map<String, dynamic>);
  }

  void _move(int delta) {
    if (_hitRows.isEmpty) return;
    setState(
        () => _selected = (_selected + delta).clamp(0, _hitRows.length - 1));
    // Keep the selection visible.
    double top = 0;
    for (var r = 0; r < _hitRows[_selected]; r++) {
      top += _rows[r] is String ? _headerHeight : _hitHeight;
    }
    final p = _scroll.position;
    if (top < p.pixels) {
      _scroll.jumpTo(top);
    } else if (top + _hitHeight > p.pixels + p.viewportDimension) {
      _scroll.jumpTo(top + _hitHeight - p.viewportDimension);
    }
  }

  String _snippet(String text, String query) {
    final i = fold(text).indexOf(fold(query));
    if (i <= 40) return text;
    return '…${text.substring(i - 30)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = ChatColors.of(context);
    final hitCount = _hitRows.length;
    final chats = _rows.length - hitCount;

    return Dialog(
      alignment: const Alignment(0, -0.6),
      insetPadding: const EdgeInsets.all(Space.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
            const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
            const SingleActivator(LogicalKeyboardKey.tab): () =>
                setState(() => _fast = !_fast),
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, 0),
                child: TextField(
                  controller: _query,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submit(),
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Search all conversations, then Enter',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.l, vertical: Space.s),
                child: Row(
                  children: [
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                          visualDensity: VisualDensity.compact),
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Substring'),
                          tooltip: 'Parts of words and phrases, 4–5 s',
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Whole words'),
                          tooltip: 'Whole words only, ranked, max 500, ~1 s',
                        ),
                      ],
                      selected: {_fast},
                      onSelectionChanged: (s) =>
                          setState(() => _fast = s.first),
                    ),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Text(
                        _loading
                            ? 'Searching…'
                            : _error != null
                                ? 'Search failed'
                                : _searched == null
                                    ? ''
                                    : '${formatCount(hitCount)} messages in $chats chats'
                                        ' · ${(_took!.inMilliseconds / 1000).toStringAsFixed(1)} s',
                        style: monoStyle(context, size: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (_all.length > 1 && !_loading) _filters(context),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              const Divider(),
              Flexible(
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(Space.xl),
                        child: Text(_error!),
                      )
                    : _searched != null && !_loading && _rows.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(Space.xl),
                            child: Text(
                                _fast
                                    ? 'No whole-word match. Try Substring.'
                                    : 'No message contains “$_searched”.',
                                style: theme.textTheme.bodyMedium),
                          )
                        : Scrollbar(
                            controller: _scroll,
                            child: ListView.builder(
                              controller: _scroll,
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(6),
                              itemCount: _rows.length,
                              itemBuilder: (context, r) {
                                final row = _rows[r];
                                if (row is String) {
                                  return SizedBox(
                                    height: _headerHeight,
                                    child: Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: Space.s, bottom: 4),
                                        child: Text(row.toUpperCase(),
                                            style: monoStyle(context)),
                                      ),
                                    ),
                                  );
                                }
                                final hit = row as Map<String, dynamic>;
                                final index = _hitRows.indexOf(r);
                                final selected = index == _selected;
                                final text =
                                    (hit['content'] as String?) ?? '(media)';
                                return SizedBox(
                                  height: _hitHeight,
                                  child: Material(
                                    color: selected
                                        ? scheme.primaryContainer
                                        : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(Radii.s),
                                    child: InkWell(
                                      borderRadius:
                                          BorderRadius.circular(Radii.s),
                                      onTap: () => _open(index),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: Space.s),
                                        child: Row(
                                          children: [
                                            Avatar(
                                                name: hit['collectionName']
                                                        as String? ??
                                                    '?',
                                                size: 26),
                                            const SizedBox(width: Space.s),
                                            Expanded(
                                              child: Text.rich(
                                                TextSpan(
                                                  children: highlightSpans(
                                                    _snippet(text, _searched!),
                                                    _searchedFast
                                                        ? null
                                                        : _searched,
                                                    TextStyle(
                                                        backgroundColor:
                                                            colors.highlight),
                                                  ),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: selected
                                                            ? scheme
                                                                .onPrimaryContainer
                                                            : null),
                                              ),
                                            ),
                                            const SizedBox(width: Space.s),
                                            Text(
                                              formatShortDate(
                                                  hit['timestamp_ms'] as int? ??
                                                      0),
                                              style: monoStyle(context),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.l, vertical: Space.s),
                child: Text(
                  '↑↓ select · Enter search / open at message · Tab switch mode · Esc close',
                  style: monoStyle(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
