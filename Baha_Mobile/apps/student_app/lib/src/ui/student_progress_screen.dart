import 'dart:math';

import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

import '../prototype/app_theme.dart';
import '../prototype/prototype_widgets.dart';
import '../prototype/theme_manager.dart';
import '../wellbeing/student_checkin_logic.dart';
import '../wellbeing/student_profile_logic.dart';

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({
    required this.apiClient,
    required this.identity,
    required this.profile,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final StudentWellbeingProfile? profile;

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  late Future<_StudentProgressData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StudentProgressData> _load() async {
    final results = await Future.wait<Object>([
      widget.apiClient.getStudentWeeklySummary(identity: widget.identity),
      widget.apiClient.listStudentCheckins(
        identity: widget.identity,
        limit: 10,
      ),
    ]);
    final summary = results[0] as StudentWeeklySummary;
    final checkins = results[1] as List<StudentCheckinSummary>;
    final details = <StudentCheckinDetail>[];
    for (final checkin in checkins.take(7)) {
      try {
        final detail = await widget.apiClient.getStudentCheckinDetail(
          identity: widget.identity,
          responseSetId: checkin.id,
        );
        details.add(detail);
      } catch (_) {}
    }
    final points = buildTrendPointsFromDetails(details);
    return _StudentProgressData(
      summary: summary,
      checkins: checkins,
      points: points,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.maybeOf(context);
    final palette = appPaletteForTheme(
      themeController?.colorTheme ?? AppColorTheme.growth,
      isDark: themeController?.isDark ?? false,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<_StudentProgressData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: [ShimmerBlock(palette: palette)],
                );
              }
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    _StudentProgressTopBar(palette: palette),
                    HeroHeader(
                      palette: palette,
                      kicker: 'Your week',
                      title: 'Could not open your progress',
                      subtitle: '${snapshot.error}',
                      actions: const [
                        Pill(icon: Icons.warning_rounded, label: 'Retry'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AnimatedPrimaryButton(
                      label: 'Reload',
                      icon: Icons.refresh_rounded,
                      onPressed: _refresh,
                    ),
                  ],
                );
              }
              final data = snapshot.data!;
              if (data.points.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    _StudentProgressTopBar(palette: palette),
                    HeroHeader(
                      palette: palette,
                      kicker: 'Your week',
                      title: 'This view fills in after a few check-ins',
                      subtitle:
                          'Once you add a few daily check-ins, this page will turn them into simple scores and short trend visuals.',
                      actions: const [
                        Pill(icon: Icons.favorite_rounded, label: 'Daily'),
                      ],
                    ),
                  ],
                );
              }

              final metrics = buildFactorMetrics(
                points: data.points,
                profile: widget.profile,
              );
              final flags = riskFlags(
                points: data.points,
                profile: widget.profile,
              );
              final steadyAreas = metrics
                  .where((metric) => metric.value >= .65)
                  .length;
              final needsCare = metrics
                  .where((metric) => metric.value < .45)
                  .length;
              final keyChanges = _keyChanges(data.points, metrics);
              final overallValues = overallChartValues(data.points);
              final labels = chartLabels(data.points);

              return ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  _StudentProgressTopBar(palette: palette),
                  HeroHeader(
                    palette: palette,
                    kicker: 'Your week',
                    title: 'A clear picture of how things are going',
                    subtitle:
                        'Simple scores built from your recent daily check-ins.',
                    actions: [
                      Pill(
                        icon: Icons.calendar_today_rounded,
                        label:
                            '${data.summary.weekStart.month}/${data.summary.weekStart.day} - ${data.summary.weekEnd.month}/${data.summary.weekEnd.day}',
                      ),
                      Pill(
                        icon: Icons.lock_rounded,
                        label:
                            '${data.summary.sourceWindow['checkins'] ?? data.checkins.length} check-ins',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _ProgressStatCard(
                          palette: palette,
                          title: 'Steady areas',
                          value: '$steadyAreas/6',
                          subtitle: 'Looking stable this week',
                          icon: Icons.trending_up_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProgressStatCard(
                          palette: palette,
                          title: 'Needs care',
                          value: '$needsCare/6',
                          subtitle: 'Worth extra attention',
                          icon: Icons.health_and_safety_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProgressStatCard(
                          palette: palette,
                          title: 'Signals',
                          value: '${flags.length}',
                          subtitle: 'Repeated patterns noticed',
                          icon: Icons.insights_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(
                          title: 'Overall weekly line',
                          subtitle: dailyStateHeadline(data.points),
                        ),
                        MiniLineChart(
                          palette: palette,
                          values: overallValues,
                          labels: labels,
                          lineColor: palette.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'Key changes',
                          subtitle:
                              'Short, number-led takeaways from this week.',
                        ),
                        const SizedBox(height: 8),
                        ...keyChanges.map(
                          (change) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CompactChangeRow(
                              palette: palette,
                              title: change.title,
                              value: change.value,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'Area by area',
                          subtitle:
                              'Higher scores mean that part of the week felt steadier.',
                        ),
                        const SizedBox(height: 8),
                        ...metrics.map(
                          (metric) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ProgressMetricRow(
                              palette: palette,
                              metric: metric,
                              changeLabel: _deltaLabelForMetric(
                                metric.factorKey,
                                data.points,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StudentProgressTopBar extends StatelessWidget {
  const _StudentProgressTopBar({required this.palette});

  final PrototypePalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const Spacer(),
        ThemeModeToggle(palette: palette),
      ],
    );
  }
}

class _ProgressStatCard extends StatelessWidget {
  const _ProgressStatCard({
    required this.palette,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final PrototypePalette palette;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CompactChangeRow extends StatelessWidget {
  const _CompactChangeRow({
    required this.palette,
    required this.title,
    required this.value,
  });

  final PrototypePalette palette;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.primary.withValues(alpha: .12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressMetricRow extends StatelessWidget {
  const _ProgressMetricRow({
    required this.palette,
    required this.metric,
    required this.changeLabel,
  });

  final PrototypePalette palette;
  final WellbeingFactorMetric metric;
  final String changeLabel;

  @override
  Widget build(BuildContext context) {
    final score = (metric.value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(metric.icon, color: metric.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                metric.label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '$score/100',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: metric.value.clamp(0, 1),
            minHeight: 10,
            backgroundColor: metric.color.withValues(alpha: .12),
            valueColor: AlwaysStoppedAnimation<Color>(metric.color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          changeLabel,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.muted),
        ),
      ],
    );
  }
}

class _StudentProgressData {
  const _StudentProgressData({
    required this.summary,
    required this.checkins,
    required this.points,
  });

  final StudentWeeklySummary summary;
  final List<StudentCheckinSummary> checkins;
  final List<WellbeingTrendPoint> points;
}

class _KeyChange {
  const _KeyChange({required this.title, required this.value});

  final String title;
  final String value;
}

List<_KeyChange> _keyChanges(
  List<WellbeingTrendPoint> points,
  List<WellbeingFactorMetric> metrics,
) {
  final entries = <_KeyChange>[];
  final bestMetric = metrics.reduce((a, b) => a.value >= b.value ? a : b);
  final lowestMetric = metrics.reduce((a, b) => a.value <= b.value ? a : b);
  entries.add(
    _KeyChange(
      title: 'Steadiest area',
      value: '${bestMetric.label} at ${(bestMetric.value * 100).round()}/100',
    ),
  );
  entries.add(
    _KeyChange(
      title: 'Most fragile area',
      value:
          '${lowestMetric.label} at ${(lowestMetric.value * 100).round()}/100',
    ),
  );
  final sleepAverage = _averageFactor(points, 'sleep');
  final energyAverage = _averageFactor(points, 'energy');
  if (sleepAverage != null && energyAverage != null) {
    final pairedScore = ((4 - ((sleepAverage + energyAverage) / 2)) / 4 * 100)
        .round();
    entries.add(
      _KeyChange(
        title: 'Sleep + energy pattern',
        value: '$pairedScore/100 combined steadiness',
      ),
    );
  }
  return entries;
}

String _deltaLabelForMetric(
  String factorKey,
  List<WellbeingTrendPoint> points,
) {
  if (points.length < 2) {
    return 'Only one check-in so far';
  }
  final latest = points.last.factorScores[factorKey];
  final earlierPoints = points.take(points.length - 1).toList();
  final earlierAverage = _averageFactor(earlierPoints, factorKey);
  if (latest == null || earlierAverage == null) {
    return 'Not enough data yet';
  }
  final latestDisplay = ((4 - latest) / 4 * 100).round();
  final earlierDisplay = ((4 - earlierAverage) / 4 * 100).round();
  final delta = latestDisplay - earlierDisplay;
  if (delta.abs() < 5) {
    return 'Nearly unchanged from your earlier check-ins';
  }
  final direction = delta > 0 ? 'up' : 'down';
  return '$direction ${delta.abs()} points from your earlier average';
}

double? _averageFactor(List<WellbeingTrendPoint> points, String factorKey) {
  final values = points
      .map((point) => point.factorScores[factorKey])
      .whereType<double>()
      .toList();
  if (values.isEmpty) {
    return null;
  }
  final total = values.fold<double>(0, (sum, value) => sum + value);
  return total / max(1, values.length);
}
