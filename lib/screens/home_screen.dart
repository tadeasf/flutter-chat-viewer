import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../components/chat/chat_view.dart';
import '../components/conversation_list.dart';
import '../components/search_palette.dart';
import '../components/settings_dialog.dart';
import '../stores/store_provider.dart';
import '../theme.dart';

/// Conversation list and chat side by side; one pane below
/// [twoPaneBreakpoint]. Owns the selection and the global shortcuts.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _chatKey = GlobalKey<ChatViewState>();
  final _filterFocus = FocusNode();
  final _filterController = TextEditingController();
  String? _selected;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _filterFocus.dispose();
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _select(String name, {int? timestamp, String? id}) async {
    final stores = StoreProvider.of(context);
    final messages = stores.messageStore;
    if (name != _selected) {
      setState(() {
        _selected = name;
        _avatarUrl = null;
      });
      _loadAvatar(name);
      await messages.open(name);
      // The opened conversation's hit count changed.
      stores.collectionStore.refreshCollectionsIfNeeded();
    }
    if (timestamp != null && mounted && _selected == name) {
      await messages.jumpTo(timestamp, id: id);
    }
  }

  Future<void> _loadAvatar(String name) async {
    final url = await StoreProvider.of(context)
        .profilePhotoStore
        .getProfilePhotoUrl(name);
    if (mounted && _selected == name) setState(() => _avatarUrl = url);
  }

  void _selectRelative(int delta) {
    final list = StoreProvider.of(context).collectionStore.filteredCollections;
    if (list.isEmpty) return;
    final i = list.indexWhere((c) => c['name'] == _selected);
    final next = (i < 0 ? 0 : i + delta).clamp(0, list.length - 1);
    _select(list[next]['name'] as String);
  }

  Future<void> _searchAll() async {
    final hit = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const SearchPalette(),
    );
    if (hit == null || !mounted) return;
    await _select(hit['collectionName'] as String,
        timestamp: hit['timestamp_ms'] as int?, id: hit['_id'] as String?);
  }

  void _focusFilter() {
    if (MediaQuery.sizeOf(context).width < twoPaneBreakpoint &&
        _selected != null) {
      setState(() => _selected = null);
    }
    _filterFocus.requestFocus();
  }

  ChatViewState? get _chat => _chatKey.currentState;

  /// Global shortcuts. A keyboard handler sees every key, wherever focus is
  /// (focus moves to the route's scope after Esc, above any Shortcuts widget
  /// in this screen). Only active while no dialog or other screen is on top;
  /// keys that also edit text are left to a focused text field.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return false;
    final keys = HardwareKeyboard.instance;
    final key = event.logicalKey;
    final editing = FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>() !=
        null;

    VoidCallback? action;
    if (keys.isControlPressed && !keys.isAltPressed) {
      action = switch (key) {
        LogicalKeyboardKey.keyK => _searchAll,
        LogicalKeyboardKey.keyF => () => _chat?.openFind(),
        LogicalKeyboardKey.keyG => () => _chat?.openJumpToDate(),
        LogicalKeyboardKey.keyP => () => _chat?.openPhotos(),
        _ => null,
      };
    } else if (keys.isAltPressed && !keys.isControlPressed) {
      action = switch (key) {
        LogicalKeyboardKey.arrowUp => () => _selectRelative(-1),
        LogicalKeyboardKey.arrowDown => () => _selectRelative(1),
        _ => null,
      };
    } else if (!editing && !keys.isControlPressed && !keys.isAltPressed) {
      action = switch (key) {
        LogicalKeyboardKey.slash => _focusFilter,
        LogicalKeyboardKey.end => () => _chat?.showNewest(),
        LogicalKeyboardKey.home => () => _chat?.showOldest(),
        LogicalKeyboardKey.pageUp => () => _chat?.pageUp(),
        LogicalKeyboardKey.pageDown => () => _chat?.pageDown(),
        _ => null,
      };
    }
    if (action == null) return false;
    action();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      child: Scaffold(
        body: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= twoPaneBreakpoint;
          final list = ConversationList(
            selected: _selected,
            onSelect: _select,
            onSearchAll: _searchAll,
            onSettings: () => showDialog(
                context: context, builder: (_) => const SettingsDialog()),
            filterFocus: _filterFocus,
            filterController: _filterController,
          );
          final chat = _selected == null
              ? const _NoConversation()
              : Observer(
                  // Rebuild with the message text size setting.
                  builder: (_) {
                    final size = StoreProvider.of(context).themeStore.fontSize;
                    final theme = Theme.of(context);
                    return Theme(
                      data: theme.copyWith(
                        textTheme: theme.textTheme.copyWith(
                          bodyLarge: theme.textTheme.bodyLarge
                              ?.copyWith(fontSize: size),
                        ),
                      ),
                      child: ChatView(
                        key: _chatKey,
                        collection: _selected!,
                        avatarUrl: _avatarUrl,
                        onProfilePhotoChanged: () => _loadAvatar(_selected!),
                        onBack: wide
                            ? null
                            : () => setState(() => _selected = null),
                      ),
                    );
                  },
                );
          if (!wide) return _selected == null ? list : chat;
          return Row(
            children: [
              SizedBox(width: sidebarWidth, child: list),
              const VerticalDivider(width: 1),
              Expanded(child: chat),
            ],
          );
        }),
      ),
    );
  }
}

class _NoConversation extends StatelessWidget {
  const _NoConversation();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined,
              size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: Space.m),
          Text('Choose a conversation', style: theme.textTheme.titleMedium),
          const SizedBox(height: Space.xs),
          Text('Ctrl+K searches every conversation · / filters the list',
              style: monoStyle(context, size: 12)),
        ],
      ),
    );
  }
}
