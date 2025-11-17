import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../services/chat_storage.dart';
import '../../models/chat_session.dart';
import '../filters/filter_panel.dart';

class ChatMenuPage extends StatefulWidget {
  const ChatMenuPage({super.key});

  @override
  State<ChatMenuPage> createState() => _ChatMenuPageState();
}

class _ChatMenuPageState extends State<ChatMenuPage> with WidgetsBindingObserver {
  List<ChatSession> _sessions = [];
  DateTime? _filterFrom;
  DateTime? _filterTo;
  bool _hasActiveFilters = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSessions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSessions();
    }
  }

  Future<void> _loadSessions() async {
    final sessions = await ChatStorage.loadSessions();
    setState(() {
      _sessions = sessions..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _isLoading = false;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _hasActiveFilters = _filterFrom != null || _filterTo != null;
    });
  }

  List<ChatSession> get _filteredChats {
    var filtered = _sessions;
    
    if (_filterFrom != null) {
      filtered = filtered.where((chat) {
        final updatedAt = chat.updatedAt;
        return updatedAt.isAfter(_filterFrom!) || updatedAt.isAtSameMomentAs(_filterFrom!);
      }).toList();
    }
    
    if (_filterTo != null) {
      filtered = filtered.where((chat) {
        final updatedAt = chat.updatedAt;
        return updatedAt.isBefore(_filterTo!.add(const Duration(days: 1))) || 
               updatedAt.isAtSameMomentAs(_filterTo!);
      }).toList();
    }
    
    return filtered;
  }

  Map<String, List<ChatSession>> get _groupedChats {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final grouped = <String, List<ChatSession>>{
      'Today': [],
      'Yesterday': [],
      'Recent': [],
    };
    
    for (final chat in _filteredChats) {
      final chatDate = DateTime(chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
      if (chatDate == today) {
        grouped['Today']!.add(chat);
      } else if (chatDate == yesterday) {
        grouped['Yesterday']!.add(chat);
      } else {
        grouped['Recent']!.add(chat);
      }
    }
    
    return grouped;
  }

  Future<void> _handleNewChat() async {
    final newSession = await ChatStorage.createNewSession();
    await ChatStorage.setCurrentSessionId(newSession.id);
    await _loadSessions();
    if (mounted) {
      Navigator.of(context).pop(); // Close drawer
      Navigator.of(context).pushReplacementNamed('/chat', arguments: null);
    }
  }

  Future<void> _handleChatTap(ChatSession chat) async {
    await ChatStorage.setCurrentSessionId(chat.id);
    if (mounted) {
      Navigator.of(context).pop(); // Close drawer
      Navigator.of(context).pushReplacementNamed('/chat', arguments: null);
    }
  }

  Future<void> _handleDeleteChat(ChatSession chat) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chat?'),
        content: Text('Delete "${chat.getPreviewTitle()}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await ChatStorage.deleteSession(chat.id);
      final currentId = await ChatStorage.getCurrentSessionId();
      if (currentId == chat.id) {
        await ChatStorage.setCurrentSessionId(null);
      }
      await _loadSessions();
    }
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterPanel(
        fromDate: _filterFrom,
        toDate: _filterTo,
        onApply: (from, to) {
          setState(() {
            _filterFrom = from;
            _filterTo = to;
            _applyFilters();
          });
        },
        onReset: () {
          setState(() {
            _filterFrom = null;
            _filterTo = null;
            _applyFilters();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  "ChatCycle",
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.purple,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _showFilterPanel,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _hasActiveFilters ? AppColors.purple : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.filter_list,
                      color: _hasActiveFilters ? Colors.white : AppColors.purple,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: AppColors.purple),
                ),
              ],
            ),
          ),
          const Divider(),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_groupedChats['Today']!.isNotEmpty) ...[
                          _section("Today"),
                          ..._groupedChats['Today']!.map(
                            (chat) => _item(chat),
                          ),
                        ],
                        if (_groupedChats['Yesterday']!.isNotEmpty) ...[
                          _section("Yesterday"),
                          ..._groupedChats['Yesterday']!.map(
                            (chat) => _item(chat),
                          ),
                        ],
                        if (_groupedChats['Recent']!.isNotEmpty) ...[
                          _section("Recent"),
                          ..._groupedChats['Recent']!.map(
                            (chat) => _item(chat),
                          ),
                        ],
                        if (_filteredChats.isEmpty && !_isLoading)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                "No chats found",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.grey,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.lightPurple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/robot.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.smart_toy, color: AppColors.purple, size: 20);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _handleNewChat,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "New Chat",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(left: 20, top: 20, bottom: 6),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _item(ChatSession chat) => InkWell(
        onTap: () => _handleChatTap(chat),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  chat.getPreviewTitle(),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.grey,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.grey),
                onPressed: () => _handleDeleteChat(chat),
                tooltip: 'Delete chat',
              ),
            ],
          ),
        ),
      );
}
