import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:stranger/screens/chat_list_screen.dart';
import 'package:stranger/screens/lobby_screen.dart';
import 'package:stranger/screens/settings_screen.dart';
import 'package:stranger/services/presence_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PresenceService.setUserOnline();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PresenceService.setUserOffline();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PresenceService.setUserOnline();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      PresenceService.setUserOffline();
    }
  }

  Widget _buildPage() {
    switch (currentIndex) {
      case 0:
        return LobbyScreen();
      case 1:
        return ChatListScreen();
      case 2:
        return SettingsScreen();
      default:
        return LobbyScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff121212),
      body: Stack(
        children: [
          _buildPage(),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.home_rounded,
                        label: "Home",
                        selected: currentIndex == 0,
                        onTap: () {
                          setState(() {
                            currentIndex = 0;
                          });
                        },
                      ),
                      _NavItem(
                        icon: Icons.chat_bubble_rounded,
                        label: "Chats",
                        selected: currentIndex == 1,
                        onTap: () {
                          setState(() {
                            currentIndex = 1;
                          });
                        },
                      ),
                      _NavItem(
                        icon: Icons.settings_rounded,
                        label: "Settings",
                        selected: currentIndex == 2,
                        onTap: () {
                          setState(() {
                            currentIndex = 2;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Color(0xff6c63ff).withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.grey.shade400,
              size: 22,
            ),
            if (selected) ...[
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
