import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../models/prototype_models.dart';
import '../../navigation/app_router.dart';
import '../../themes/app_theme.dart';
import '../../themes/theme_manager.dart';
import '../../widgets/prototype_widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.role});
  final AppRole role;
  @override
  Widget build(BuildContext context) {
    final palette = rolePalette(role, isDark: ThemeScope.of(context).isDark);
    return Theme(
        data: buildTheme(palette),
        child: _AuthFrame(
            role: role,
            palette: palette,
            title: 'Welcome back',
            subtitle: 'Demo login only. No auth is performed.',
            children: [
              const TextField(
                  decoration: InputDecoration(labelText: 'Email address')),
              const SizedBox(height: 12),
              const TextField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password')),
              const SizedBox(height: 16),
              AnimatedPrimaryButton(
                  label: 'Enter ${role.label}',
                  icon: Icons.login_rounded,
                  onPressed: () => context.go('/onboarding/${role.slug}')),
              TextButton(
                  onPressed: () => context.go('/forgot/${role.slug}'),
                  child: const Text('Forgot password?')),
              OutlinedButton(
                  onPressed: () => context.go('/signup/${role.slug}'),
                  child: const Text('Create fake account')),
            ]));
  }
}

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key, required this.role});
  final AppRole role;
  @override
  Widget build(BuildContext context) {
    final palette = rolePalette(role, isDark: ThemeScope.of(context).isDark);
    return Theme(
        data: buildTheme(palette),
        child: _AuthFrame(
            role: role,
            palette: palette,
            title: 'Create your profile',
            subtitle: 'A complete fake signup flow for stakeholder demos.',
            children: [
              const TextField(
                  decoration: InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 12),
              TextField(
                  decoration: InputDecoration(
                      labelText: role == AppRole.student
                          ? 'Age / Grade'
                          : 'Organization / School')),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              const TextField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password')),
              const SizedBox(height: 16),
              AnimatedPrimaryButton(
                  label: 'Continue to OTP',
                  icon: Icons.mark_email_read_rounded,
                  onPressed: () => context.go('/otp/${role.slug}')),
            ]));
  }
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key, required this.role});
  final AppRole role;
  @override
  Widget build(BuildContext context) {
    final palette = rolePalette(role, isDark: ThemeScope.of(context).isDark);
    return Theme(
        data: buildTheme(palette),
        child: _AuthFrame(
            role: role,
            palette: palette,
            title: 'Reset access',
            subtitle: 'Fake password reset screen with animated confirmation.',
            children: [
              const TextField(
                  decoration: InputDecoration(labelText: 'Email address')),
              const SizedBox(height: 16),
              AnimatedPrimaryButton(
                  label: 'Send OTP',
                  icon: Icons.send_rounded,
                  onPressed: () => context.go('/otp/${role.slug}')),
              TextButton(
                  onPressed: () => context.go('/login/${role.slug}'),
                  child: const Text('Back to login')),
            ]));
  }
}

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key, required this.role});
  final AppRole role;
  @override
  Widget build(BuildContext context) {
    final palette = rolePalette(role, isDark: ThemeScope.of(context).isDark);
    return Theme(
        data: buildTheme(palette),
        child: _AuthFrame(
            role: role,
            palette: palette,
            title: 'Verify demo OTP',
            subtitle: 'Use any numbers. This is UI only.',
            children: [
              Row(
                  children: List.generate(
                      4,
                      (index) => Expanded(
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: TextField(
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  decoration: const InputDecoration(
                                      counterText: '')))))),
              const SizedBox(height: 16),
              AnimatedPrimaryButton(
                  label: 'Verify and continue',
                  icon: Icons.verified_rounded,
                  onPressed: () => context.go('/onboarding/${role.slug}')),
            ]));
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.role});
  final AppRole role;
  @override
  Widget build(BuildContext context) {
    final palette = rolePalette(role, isDark: ThemeScope.of(context).isDark);
    return Theme(
        data: buildTheme(palette),
        child: AnimatedGradientScaffold(
            palette: palette,
            child: ListView(padding: const EdgeInsets.all(22), children: [
              HeroHeader(
                  palette: palette,
                  kicker: 'Onboarding',
                  title: role == AppRole.student
                      ? 'Set your vibe, privacy, and avatar.'
                      : 'Prepare your ${role.label} workspace.',
                  subtitle: palette.story,
                  actions: [
                    Pill(icon: role.icon, label: role.label),
                    const Pill(
                        icon: Icons.privacy_tip_rounded, label: 'Privacy-first')
                  ]),
              const SizedBox(height: 20),
              ...[
                'Choose avatar',
                'Review privacy',
                'Enable reminders',
                'Preview dashboard'
              ].indexed.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassPanel(
                      palette: palette,
                      onTap: () => entry.$1 == 0
                          ? context.go('/avatar/${role.slug}')
                          : context.go(detailPath(role, entry.$2)),
                      child: Row(children: [
                        CircleAvatar(
                            backgroundColor:
                                palette.primary.withValues(alpha: .14),
                            child: Text('${entry.$1 + 1}')),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Text(entry.$2,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800))),
                        const Icon(Icons.chevron_right_rounded)
                      ])))),
              const SizedBox(height: 10),
              AnimatedPrimaryButton(
                  label: 'Open ${role.label}',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.go(homePath(role))),
            ])));
  }
}

class AvatarSelectionScreen extends StatelessWidget {
  const AvatarSelectionScreen({super.key, required this.role});
  final AppRole role;
  @override
  Widget build(BuildContext context) {
    final palette = rolePalette(role, isDark: ThemeScope.of(context).isDark);
    final icons = [
      Icons.face_3_rounded,
      Icons.face_4_rounded,
      Icons.pets_rounded,
      Icons.rocket_launch_rounded,
      Icons.spa_rounded,
      Icons.psychology_rounded
    ];
    return Theme(
        data: buildTheme(palette),
        child: AnimatedGradientScaffold(
            palette: palette,
            child: ListView(padding: const EdgeInsets.all(22), children: [
              HeroHeader(
                  palette: palette,
                  kicker: 'Avatar',
                  title: 'Pick a demo identity',
                  subtitle:
                      'Every avatar opens the app. No account is created.',
                  actions: const [
                    Pill(icon: Icons.auto_awesome_rounded, label: 'Animated')
                  ]),
              const SizedBox(height: 18),
              GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: icons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12),
                  itemBuilder: (context, index) => GlassPanel(
                          palette: palette,
                          onTap: () => context.go(homePath(role)),
                          child: Icon(icons[index],
                              size: 38, color: palette.primary))
                      .animate(delay: (index * 70).ms)
                      .scale()),
            ])));
  }
}

class _AuthFrame extends StatelessWidget {
  const _AuthFrame(
      {required this.role,
      required this.palette,
      required this.title,
      required this.subtitle,
      required this.children});
  final AppRole role;
  final PrototypePalette palette;
  final String title;
  final String subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return AnimatedGradientScaffold(
        palette: palette,
        child: ListView(padding: const EdgeInsets.all(22), children: [
          Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                  onPressed: () => context.go('/roles'),
                  icon: const Icon(Icons.arrow_back_rounded))),
          HeroHeader(
              palette: palette,
              kicker: role.label,
              title: title,
              subtitle: subtitle,
              actions: [
                Pill(icon: role.icon, label: 'Fake data'),
                const Pill(
                    icon: Icons.no_encryption_gmailerrorred_rounded,
                    label: 'No backend')
              ]),
          const SizedBox(height: 22),
          GlassPanel(palette: palette, child: Column(children: children))
              .animate()
              .fadeIn()
              .slideY(begin: .08, end: 0),
        ]));
  }
}
