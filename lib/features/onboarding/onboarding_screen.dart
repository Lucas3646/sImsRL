import 'package:flutter/material.dart';

import 'package:simsrl/core/theme/app_theme.dart';
import 'package:simsrl/features/model/model_setup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _index = 0;

  static const _pages = [
    _OnboardingData(
      title: 'Ton dressing, partout.',
      subtitle: 'Photographie les vêtements que tu possèdes vraiment.',
      icon: Icons.checkroom_rounded,
      color: AppColors.lime,
      kicker: 'AJOUTE TON DRESSING',
    ),
    _OnboardingData(
      title: 'Crée ton modèle.',
      subtitle: 'Une photo en pied suffit pour commencer à tester le concept.',
      icon: Icons.accessibility_new_rounded,
      color: AppColors.lavender,
      kicker: 'TON LOOK, SUR TOI',
    ),
    _OnboardingData(
      title: 'Change. Swipe. Recommence.',
      subtitle:
          'Compose une tenue aussi facilement que dans un créateur de personnage.',
      icon: Icons.swipe_rounded,
      color: AppColors.coral,
      kicker: 'TESTE TES TENUES',
    ),
    _OnboardingData(
      title: 'Trouve ton outfit sans te changer.',
      subtitle:
          'Compare tes idées en quelques secondes et sauvegarde tes meilleurs looks.',
      icon: Icons.auto_awesome_rounded,
      color: AppColors.lime,
      kicker: 'PRÊT À COMMENCER ?',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Row(
                children: [
                  Text('sImsRL', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  Text(
                    '${_index + 1}/${_pages.length}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: _pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: index == _index ? 28 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index == _index
                              ? AppColors.ink
                              : AppColors.line,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () {
                      if (isLast) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ModelSetupScreen(),
                          ),
                        );
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    child: Text(isLast ? 'Créer mon dressing' : 'Continuer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});
  final _OnboardingData data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: constraints.maxHeight < 500 ? 190 : 250,
                height: constraints.maxHeight < 500 ? 190 : 250,
                decoration: BoxDecoration(
                  color: data.color,
                  borderRadius: BorderRadius.circular(42),
                ),
                child: Icon(data.icon, size: 96, color: AppColors.ink),
              ),
            ),
            const SizedBox(height: 34),
            Text(
              data.kicker,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(data.title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 14),
            Text(
              data.subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.kicker,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String kicker;
}
