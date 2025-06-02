import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qrush/pages/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:qrush/ui/theme.dart';
import 'ui/settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    runApp(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(),
        child: const QRushApp(),
      ),
    );
  });
}

class QRushApp extends StatelessWidget {
  const QRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRush',
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: Provider.of<SettingsProvider>(context).themeMode,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
