import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shimmer/shimmer.dart';

import '../models/prototype_models.dart';
import '../themes/app_theme.dart';
import '../themes/theme_manager.dart';

class ThemeModeToggle extends StatelessWidget {
  const ThemeModeToggle({super.key, required this.palette});

  final PrototypePalette palette;

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);
    return Semantics(
      button: true,
      label: controller.isDark ? 'Switch to light mode' : 'Switch to dark mode',
      child: GestureDetector(
        onTap: controller.toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          width: 64,
          height: 36,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: controller.isDark
                ? LinearGradient(colors: [
                    palette.primary.withValues(alpha: .85),
                    palette.secondary.withValues(alpha: .75)
                  ])
                : LinearGradient(colors: [
                    palette.accent.withValues(alpha: .9),
                    palette.primary.withValues(alpha: .75)
                  ]),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: .34)),
            boxShadow: [
              BoxShadow(
                  color: palette.primary.withValues(alpha: .20),
                  blurRadius: 18,
                  offset: const Offset(0, 8))
            ],
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            alignment: controller.isDark
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999)),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: Icon(
                  controller.isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  key: ValueKey(controller.isDark),
                  size: 17,
                  color: controller.isDark ? palette.primary : palette.accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({super.key, required this.palette});

  final PrototypePalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Spacer(),
          ThemeModeToggle(palette: palette),
        ],
      ),
    );
  }
}

class AnimatedGradientScaffold extends StatelessWidget {
  const AnimatedGradientScaffold(
      {super.key,
      required this.palette,
      required this.child,
      this.appBar,
      this.floatingActionButton,
      this.bottomNavigationBar});
  final PrototypePalette palette;
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          Positioned.fill(
              child: DecoratedBox(
                  decoration: BoxDecoration(color: palette.background))),
          Positioned(
              top: -120,
              right: -80,
              child: _Orb(color: palette.primary, size: 260)),
          Positioned(
              top: 120,
              left: -90,
              child: _Orb(color: palette.secondary, size: 190)),
          Positioned(
              bottom: -120,
              right: 30,
              child: _Orb(color: palette.accent, size: 220)),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: .14),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: .18),
                  blurRadius: 80,
                  spreadRadius: 20)
            ]));
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel(
      {super.key,
      required this.palette,
      required this.child,
      this.padding = const EdgeInsets.all(20),
      this.onTap});
  final PrototypePalette palette;
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: 280.ms,
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: palette.isDark ? .72 : .84),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: Colors.white.withValues(alpha: palette.isDark ? .12 : .58)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: palette.isDark ? .22 : .08),
              blurRadius: 30,
              offset: const Offset(0, 14))
        ],
      ),
      child: child,
    );
    if (onTap == null) {
      return card.animate().fadeIn(duration: 420.ms).slideY(begin: .06, end: 0);
    }
    return Semantics(
            button: true,
            child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: onTap,
                child: card))
        .animate()
        .fadeIn(duration: 420.ms)
        .slideY(begin: .06, end: 0);
  }
}

class HeroHeader extends StatelessWidget {
  const HeroHeader(
      {super.key,
      required this.palette,
      required this.kicker,
      required this.title,
      required this.subtitle,
      required this.actions});
  final PrototypePalette palette;
  final String kicker;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: palette.gradient,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
                color: palette.primary.withValues(alpha: .34),
                blurRadius: 40,
                offset: const Offset(0, 18))
          ]),
      child: Stack(
        children: [
          Positioned(
              right: -24,
              top: -22,
              child: Icon(palette.heroIcon,
                      size: 138, color: Colors.white.withValues(alpha: .15))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                      begin: const Offset(.96, .96),
                      end: const Offset(1.04, 1.04),
                      duration: 2400.ms)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(kicker,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: Colors.white.withValues(alpha: .86))),
            const SizedBox(height: 8),
            Text(title,
                softWrap: true,
                style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.02)),
            const SizedBox(height: 10),
            Text(subtitle,
                softWrap: true,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: Colors.white.withValues(alpha: .9))),
            const SizedBox(height: 18),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ]),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 650.ms)
        .scale(begin: const Offset(.96, .96), curve: Curves.easeOutBack);
  }
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
            color: (color ?? Colors.white).withValues(alpha: .18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: .22))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Colors.white))
        ]));
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile(
      {super.key,
      required this.palette,
      required this.metric,
      required this.onTap});
  final PrototypePalette palette;
  final UiMetric metric;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      onTap: onTap,
      child: Row(children: [
        CircularPercentIndicator(
            radius: 34,
            lineWidth: 8,
            percent: metric.value.clamp(0, 1).toDouble(),
            progressColor: metric.color,
            backgroundColor: metric.color.withValues(alpha: .14),
            center: Icon(metric.icon, color: metric.color)),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(metric.label,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(metric.detail,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: palette.muted))
        ])),
        Icon(Icons.chevron_right_rounded, color: palette.muted),
      ]),
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard(
      {super.key,
      required this.palette,
      required this.item,
      required this.onTap});
  final PrototypePalette palette;
  final UiCardItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: item.color.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(18)),
              child: Icon(item.icon, color: item.color)),
          const Spacer(),
          Text(item.tag,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: item.color, fontWeight: FontWeight.w900))
        ]),
        const SizedBox(height: 18),
        Text(item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(item.subtitle,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: palette.muted)),
      ]),
    );
  }
}

class AnimatedPrimaryButton extends StatelessWidget {
  const AnimatedPrimaryButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
            onPressed: onPressed, icon: Icon(icon), label: Text(label))
        .animate()
        .shimmer(duration: 1600.ms, delay: 900.ms);
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              softWrap: true,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle,
              softWrap: true, style: Theme.of(context).textTheme.bodyMedium)
        ]));
  }
}

class MiniLineChart extends StatelessWidget {
  const MiniLineChart({super.key, required this.palette});
  final PrototypePalette palette;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
              isCurved: true,
              barWidth: 4,
              color: palette.primary,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                  show: true, color: palette.primary.withValues(alpha: .14)),
              spots: const [
                FlSpot(0, 2),
                FlSpot(1, 2.8),
                FlSpot(2, 2.4),
                FlSpot(3, 3.7),
                FlSpot(4, 3.2),
                FlSpot(5, 4.2),
                FlSpot(6, 4)
              ])
        ],
      )),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: .08, end: 0);
  }
}

class ShimmerBlock extends StatelessWidget {
  const ShimmerBlock({super.key, required this.palette});
  final PrototypePalette palette;
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: palette.primary.withValues(alpha: .12),
        highlightColor: palette.secondary.withValues(alpha: .2),
        child: Container(
            height: 92,
            decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(24))));
  }
}

class FloatingMascot extends StatelessWidget {
  const FloatingMascot({super.key, required this.palette});
  final PrototypePalette palette;
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
            angle: math.sin(DateTime.now().millisecond / 1000) * .02,
            child: CircleAvatar(
                radius: 38,
                backgroundColor: palette.primary.withValues(alpha: .18),
                child:
                    Icon(palette.heroIcon, color: palette.primary, size: 34)))
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -4, end: 6, duration: 1600.ms);
  }
}

int adaptiveGridCount(double width, {int preferred = 2}) {
  if (width < 360) {
    return 1;
  }
  if (width >= 900) {
    return 4;
  }
  if (width >= 620) {
    return 3;
  }
  return preferred;
}
