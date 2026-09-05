import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:simsrl/core/theme/app_theme.dart';
import 'package:simsrl/features/onboarding/onboarding_screen.dart';
import 'package:simsrl/features/shell/app_shell.dart';
import 'package:simsrl/state/app_scope.dart';
import 'package:simsrl/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final state = AppState();
  await state.initialize();
  runApp(SimsRlApp(state: state));
}

class SimsRlApp extends StatelessWidget {
  const SimsRlApp({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
    state: state,
    child: MaterialApp(
      title: 'sImsRL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AppEntry(),
    ),
  );
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: state.onboardingComplete
          ? const AppShell(key: ValueKey('shell'))
          : const OnboardingScreen(key: ValueKey('onboarding')),
    );
  }
}
