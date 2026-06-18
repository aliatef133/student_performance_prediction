import 'package:flutter/material.dart';
import '../core/Home_Page.dart';
import '../core/about_us.dart';
import '../core/guidance.dart';

class Layout extends StatefulWidget {
  final String token;

  const Layout({
    super.key,
    required String title,
    required Map<dynamic, dynamic> previousAnswers,
    required this.token,
  });

  @override
  State<StatefulWidget> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<Layout> {
  int SelectedIndex = 0;

  late List<Widget> tabs;

  @override
  void initState() {
    super.initState();
    tabs = [
      HomePage(token: widget.token),
      const GuidancePage(token: '',),
      AboutUs(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: BottomNavigationBar(
          onTap: (index) {
            SelectedIndex = index;
            setState(() {});
          },
          currentIndex: SelectedIndex,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: false,
          fixedColor: const Color(0xFF5669FF),
          backgroundColor: Colors.white,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: SelectedIndex == 0
                      ? Colors.blue.withOpacity(0.5)
                      : Colors.transparent,
                ),
                child: const ImageIcon(
                    AssetImage("images/assets/Home.png")),
              ),
              label: "Home Page",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: SelectedIndex == 1
                      ? Colors.blue.withOpacity(0.5)
                      : Colors.transparent,
                ),
                child: const ImageIcon(
                    AssetImage("images/assets/guidence.png")),
              ),
              label: "Guidence",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: SelectedIndex == 2
                      ? Colors.blue.withOpacity(0.5)
                      : Colors.transparent,
                ),
                child: const ImageIcon(
                    AssetImage("images/assets/About_us.png")),
              ),
              label: "About us",
            ),
          ],
        ),
        body: tabs[SelectedIndex],
      ),
    );
  }
}