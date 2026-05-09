import "package:flutter/material.dart";

import "root_navigation_shell.dart";

class MoneyHeroApp extends StatelessWidget {
  const MoneyHeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Money Hero",
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const RootNavigationShell(),
    );
  }
}
