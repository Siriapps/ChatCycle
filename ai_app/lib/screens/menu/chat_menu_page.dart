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
      _sessions = sessions;
      _applyFilters();
    });
  }

  void _applyFilters() {
    // Filter logic will be applied here when filters are set
    setState(() {
      _hasActiveFilters = _filterFrom != null || _filterTo != null;
    });
  }

  List<ChatSession> get _filteredSessions {
    var filtered = _sessions;
    
    if (_filterFrom != null) {
      filtered = filtered.where((s) => s.updatedAt.isAfter(_filterFrom!) || 
        s.updatedAt.isAtSameMomentAs(_filterFrom!)).toList();
    }
    
    if (_filterTo != null) {
      filtered = filtered.where((s) => s.updatedAt.isBefore(_filterTo!.add(const Duration(days: 1))) || 
        s.updatedAt.isAtSameMomentAs(_filterTo!)).toList();
    }
    
    return filtered..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Map<String, List<ChatSession>> get _groupedSessions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final grouped = <String, List<ChatSession>>{
      'Today': [],
      'Yesterday': [],
      'Recent': [],
    };
    
    for (final session in _filteredSessions) {
      final sessionDate = DateTime(session.updatedAt.year, session.updatedAt.month, session.updatedAt.day);
      
      if (sessionDate == today) {
        grouped['Today']!.add(session);
      } else if (sessionDate == yesterday) {
        grouped['Yesterday']!.add(session);
      } else {
        grouped['Recent']!.add(session);
      }
    }
    
    return grouped;
  }

  Future<void> _handleNewChat() async {
    await ChatStorage.createNewSession();
    if (mounted) {
      Navigator.of(context).pop(); // Close drawer
      Navigator.of(context).pushReplacementNamed('/chat').then((_) {
        // Refresh when returning
        _loadSessions();
      });
    }
  }

  Future<void> _handleSessionTap(ChatSession session) async {
    await ChatStorage.setCurrentSessionId(session.id);
    if (mounted) {
      Navigator.of(context).pop(); // Close drawer
      // Navigate to chat page - it will reload the session in initState
      Navigator.of(context).pushReplacementNamed('/chat', arguments: null).then((_) {
        // Refresh when returning
        _loadSessions();
      });
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
    ).then((_) {
      // Refresh when filter panel closes
      _loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedSessions;
    
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
          // Header
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

          // Chat History
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (grouped['Today']!.isNotEmpty) ...[
                    _section("Today"),
                    ...grouped['Today']!.map((session) => _item(session.getPreviewTitle(), () => _handleSessionTap(session))),
                  ],
                  
                  if (grouped['Yesterday']!.isNotEmpty) ...[
                    _section("Yesterday"),
                    ...grouped['Yesterday']!.map((session) => _item(session.getPreviewTitle(), () => _handleSessionTap(session))),
                  ],
                  
                  if (grouped['Recent']!.isNotEmpty) ...[
                    _section("Recent"),
                    ...grouped['Recent']!.map((session) => _item(session.getPreviewTitle(), () => _handleSessionTap(session))),
                  ],
                  
                  if (_filteredSessions.isEmpty)
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

          // New Chat Button
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

  Widget _item(String text, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.grey,
            ),
          ),
        ),
      );
}
