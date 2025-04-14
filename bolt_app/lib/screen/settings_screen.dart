import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(themeNotifier.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            const SizedBox(width: 10),
            CupertinoSwitch(
              value: themeNotifier.isDarkMode,
              onChanged: (value) {
                themeNotifier.toggleTheme(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
