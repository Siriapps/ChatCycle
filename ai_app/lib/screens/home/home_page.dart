import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../services/chat_storage.dart';
import '../menu/chat_menu_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.80,
        child: const ChatMenuPage(),
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/icon.png',
          height: 40,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'ChatCycle',
              style: TextStyle(
                color: AppColors.purple,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.purple, size: 28),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      bottomNavigationBar: _navBar(),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),

            _robotCircle(),

            const SizedBox(height: 25),

            Text(
              "Ask me anything",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "I can help you with anything from creative writing to solving your math homework",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
            ),

            const Spacer(),

            _inputField(context),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _robotCircle() {
    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.pink.withOpacity(0.75),
              AppColors.blue.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 40,
              color: AppColors.purple.withOpacity(0.25),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Image.asset("assets/robot.png"),
        ),
      ),
    );
  }

  Widget _inputField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.grey.withOpacity(0.25)),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Start typing...",
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (value) async {
                  await _handleSend();
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.purple,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSend() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;
    
    // Create a new session when navigating from home
    await ChatStorage.createNewSession();
    if (mounted) {
      _textController.clear(); // Clear the input
      Navigator.pushNamed(
        context,
        "/chat",
        arguments: message,
      );
    }
  }

  Widget _navBar() {
    return BottomNavigationBar(
      currentIndex: 1,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedItemColor: AppColors.purple,
      unselectedItemColor: AppColors.grey,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
        const BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
        BottomNavigationBarItem(
          icon: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.purple,
                  AppColors.purple.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Purple half circle background
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 50,
                    height: 25,
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(50),
                        bottomRight: Radius.circular(50),
                      ),
                    ),
                  ),
                ),
                // Plus icon
                const Icon(Icons.add, color: Colors.white, size: 24),
              ],
            ),
          ),
          label: "Create",
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.book), label: "Library"),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}