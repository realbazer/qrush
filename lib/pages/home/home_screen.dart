import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrush/pages/create/create_qr_screen.dart';
import 'package:qrush/pages/scan/scan_qr_screen.dart';
import 'package:qrush/pages/settings/settings_screen.dart';
import 'package:qrush/ui/settings_provider.dart';
import 'package:qrush/ui/widgets/bottom_navigation_widget.dart';
import 'package:smoke_effect/smoke_effect.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> screens = const [ScannerScreen(), GeneratorScreen()];

  @override
  Widget build(BuildContext context) {
    final enableSmoke = Provider.of<SettingsProvider>(context).enableSmoke;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Stack(
        children: [
          if (enableSmoke && ThemeMode == ThemeMode.dark)
            SmokeEffect(
              gradientSmoke: false,
              singleSmokeColor: Theme.of(context).colorScheme.secondary,
            ),
          screens[_currentIndex],
          BottomNavigationButtons(
            selectedIndex: _currentIndex,
            onItemTapped: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  alignment: Alignment.topRight,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(CupertinoIcons.gear),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
