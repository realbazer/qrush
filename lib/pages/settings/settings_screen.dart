import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ui/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = settingsProvider.themeMode == ThemeMode.dark;
    final isEnabled = settingsProvider.enableSmoke == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Container(
            height: 300,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 100, width: 100),
                const SizedBox(height: 10),
                Text('QRush', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 300,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Dark Theme',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    value: isDark,
                    onChanged: (val) => settingsProvider.toggleTheme(val),
                  ),
                  SwitchListTile(
                    title: Text(
                      'Enable Smoke',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    value: isEnabled,
                    onChanged: (val) => settingsProvider.toggleSmoke(val),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
