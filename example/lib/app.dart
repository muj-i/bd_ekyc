import 'package:bd_ekyc/bd_ekyc.dart';
import 'package:example/theme/app_theme.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return NidOcrStateManager(
      child: MaterialApp(
        title: 'BD E-Kyc Example',
        theme: AppTheme.appLightTheme,
        themeMode: ThemeMode.light,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child ?? const SizedBox(),
          );
        },
        home: const BdEkyc(),
      ),
    );
  }
}
