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
  _ProgressTimeframe _timeframe = _ProgressTimeframe.sevenDays;
  String _selectedFactor = 'overall';
  static const _minimumCheckinsForAnalytics = 3;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StudentProgressData> _load() async {
    final checkins = await widget.apiClient.listStudentCheckins(
      identity: widget.identity,
      limit: 40,
    );
    final completedCheckins = checkins
        .where((item) => item.submittedAt != null)
        .toList();
    final summary = await _loadWeeklySummaryOrFallback(
      apiClient: widget.apiClient,
      identity: widget.identity,
      completedCheckinCount: completedCheckins.length,
    );
    final details = <StudentCheckinDetail>[];
    for (final checkin in completedCheckins) {
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
      completedCheckinCount: completedCheckins.length,
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
                      kicker: 'Your patterns',
                      title: 'Could not open your analytics',
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
              if (data.completedCheckinCount < _minimumCheckinsForAnalytics ||
                  data.points.length < 2) {
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    _StudentProgressTopBar(palette: palette),
                    HeroHeader(
                      palette: palette,
                      kicker: 'Your patterns',
                      title: 'Your analysis will appear after a few check-ins',
                      subtitle:
                          data.completedCheckinCount == 0
                          ? 'Complete your first few daily check-ins and this page will turn them into simple trend views and evidence-backed pattern notes.'
                          : data.completedCheckinCount == 1
                          ? 'You have 1 completed check-in so far. Add at least 2 more so BAHA can compare patterns over time.'
                          : 'You have ${data.completedCheckinCount} completed check-ins so far. Add ${_minimumCheckinsForAnalytics - data.completedCheckinCount} more to unlock a clearer analysis view.',
                      actions: [
                        const Pill(
                          icon: Icons.favorite_rounded,
                          label: 'Daily check-ins',
                        ),
                        Pill(
                          icon: Icons.insights_rounded,
                          label:
                              '${data.completedCheckinCount}/$_minimumCheckinsForAnalytics ready',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GlassPanel(
                      palette: palette,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(
                            title: 'Why nothing is shown yet',
                            subtitle:
                                'BAHA waits for repeated check-ins before it tries to show patterns.',
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'With only one or two check-ins, it is too early to tell whether something is a real trend or just one difficult day.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 14),
                          AnimatedPrimaryButton(
                            label: 'Refresh analysis',
                            icon: Icons.refresh_rounded,
                            onPressed: _refresh,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              final filteredPoints = _filterPoints(data.points, _timeframe);
              final effectivePoints = filteredPoints.isEmpty
                  ? data.points
                  : filteredPoints;
              final metrics = buildFactorMetrics(
                points: effectivePoints,
                profile: widget.profile,
              );
              final factorOptions = <_FactorOption>[
                const _FactorOption(
                  key: 'overall',
                  label: 'Overall',
                  icon: Icons.insights_rounded,
                  color: Color(0xFF14B8A6),
                ),
                ...metrics.map(
                  (metric) => _FactorOption(
                    key: metric.factorKey,
                    label: metric.label,
                    icon: metric.icon,
                    color: metric.color,
                  ),
                ),
              ];
              if (!factorOptions.any(
                (option) => option.key == _selectedFactor,
              )) {
                _selectedFactor = 'overall';
              }
              final selectedOption = factorOptions.firstWhere(
                (option) => option.key == _selectedFactor,
                orElse: () => factorOptions.first,
              );
              final values = _selectedFactor == 'overall'
                  ? overallChartValues(effectivePoints)
                  : chartValuesForFactor(effectivePoints, _selectedFactor);
              final labels = chartLabels(effectivePoints);
              final insights = _buildInsights(
                points: effectivePoints,
                summary: data.summary,
                profile: widget.profile,
              );
              final steadyCount = metrics
                  .where((metric) => _steadyDayCount(
                        effectivePoints,
                        metric.factorKey,
                      ) >= max(1, effectivePoints.length ~/ 2))
                  .length;
              final watchCount = metrics
                  .where((metric) => _elevatedDayCount(
                        effectivePoints,
                        metric.factorKey,
                      ) >= max(2, effectivePoints.length ~/ 3))
                  .length;

              return ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  _StudentProgressTopBar(palette: palette),
                  HeroHeader(
                    palette: palette,
                    kicker: 'Your patterns',
                    title: 'A clearer view of how your days have been going',
                    subtitle:
                        'This page shows trends from your check-ins. It highlights repeated patterns, not diagnoses.',
                    actions: [
                      Pill(
                        icon: Icons.calendar_today_rounded,
                        label: _timeframe.label,
                      ),
                      Pill(
                        icon: Icons.lock_rounded,
                        label: '${effectivePoints.length} check-ins in view',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'Choose a time window',
                          subtitle:
                              'Switch views to compare recent patterns with the longer picture.',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _ProgressTimeframe.values.map((frame) {
                            return ChoiceChip(
                              label: Text(frame.shortLabel),
                              selected: _timeframe == frame,
                              onSelected: (_) =>
                                  setState(() => _timeframe = frame),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        const SectionTitle(
                          title: 'Choose a focus',
                          subtitle:
                              'Open one area at a time or stay on the overall picture.',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: factorOptions.map((option) {
                            return ChoiceChip(
                              avatar: Icon(
                                option.icon,
                                size: 16,
                                color: option.color,
                              ),
                              label: Text(option.label),
                              selected: _selectedFactor == option.key,
                              onSelected: (_) => setState(
                                () => _selectedFactor = option.key,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _SignalCountCard(
                          palette: palette,
                          title: 'Check-ins in view',
                          value: '${effectivePoints.length}',
                          subtitle: _timeframe.countLabel,
                          icon: Icons.event_note_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SignalCountCard(
                          palette: palette,
                          title: 'Steadier areas',
                          value: '$steadyCount',
                          subtitle: 'Showing more stable days',
                          icon: Icons.trending_up_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SignalCountCard(
                          palette: palette,
                          title: 'Watch areas',
                          value: '$watchCount',
                          subtitle: 'Showing repeated strain',
                          icon: Icons.visibility_rounded,
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
                          title: '${selectedOption.label} over time',
                          subtitle: _selectedFactorSubtitle(
                            factorKey: _selectedFactor,
                            points: effectivePoints,
                          ),
                        ),
                        MiniLineChart(
                          palette: palette,
                          values: values,
                          labels: labels,
                          lineColor: selectedOption.color,
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
                          title: 'What BAHA is noticing',
                          subtitle:
                              'Each note below includes the evidence behind it.',
                        ),
                        const SizedBox(height: 8),
                        ...insights.map(
                          (insight) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NarrativeInsightCard(
                              palette: palette,
                              insight: insight,
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
                          title: 'Pattern evidence',
                          subtitle:
                              'These counts are the concrete signals behind the current view.',
                        ),
                        const SizedBox(height: 10),
                        ...metrics.map(
                          (metric) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _EvidenceRow(
                              palette: palette,
                              label: metric.label,
                              icon: metric.icon,
                              color: metric.color,
                              evidence: _factorEvidence(
                                effectivePoints,
                                metric.factorKey,
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

class _SignalCountCard extends StatelessWidget {
  const _SignalCountCard({
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

class _NarrativeInsightCard extends StatelessWidget {
  const _NarrativeInsightCard({
    required this.palette,
    required this.insight,
  });

  final PrototypePalette palette;
  final _NarrativeInsight insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: insight.color.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: insight.color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(insight.icon, color: insight.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Why BAHA says this: ${insight.evidence}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({
    required this.palette,
    required this.label,
    required this.icon,
    required this.color,
    required this.evidence,
  });

  final PrototypePalette palette;
  final String label;
  final IconData icon;
  final Color color;
  final String evidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: .52),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(evidence, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentProgressData {
  const _StudentProgressData({
    required this.summary,
    required this.checkins,
    required this.points,
    required this.completedCheckinCount,
  });

  final StudentWeeklySummary summary;
  final List<StudentCheckinSummary> checkins;
  final List<WellbeingTrendPoint> points;
  final int completedCheckinCount;
}

class _NarrativeInsight {
  const _NarrativeInsight({
    required this.title,
    required this.body,
    required this.evidence,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final String evidence;
  final IconData icon;
  final Color color;
}

class _FactorOption {
  const _FactorOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String key;
  final String label;
  final IconData icon;
  final Color color;
}

enum _ProgressTimeframe {
  sevenDays('Last 7 days', '7D', 7),
  fourteenDays('Last 14 days', '14D', 14),
  thirtyDays('Last 30 days', '30D', 30),
  all('All available check-ins', 'All', null);

  const _ProgressTimeframe(this.label, this.shortLabel, this.days);

  final String label;
  final String shortLabel;
  final int? days;

  String get countLabel {
    return switch (this) {
      _ProgressTimeframe.sevenDays => 'Most recent week',
      _ProgressTimeframe.fourteenDays => 'Two-week view',
      _ProgressTimeframe.thirtyDays => 'Month view',
      _ProgressTimeframe.all => 'All saved history',
    };
  }
}

List<WellbeingTrendPoint> _filterPoints(
  List<WellbeingTrendPoint> points,
  _ProgressTimeframe timeframe,
) {
  if (timeframe.days == null || points.isEmpty) {
    return points;
  }
  final end = points.last.date;
  final cutoff = end.subtract(Duration(days: timeframe.days! - 1));
  return points.where((point) => !point.date.isBefore(cutoff)).toList();
}

List<_NarrativeInsight> _buildInsights({
  required List<WellbeingTrendPoint> points,
  required StudentWeeklySummary summary,
  required StudentWellbeingProfile? profile,
}) {
  final metrics = buildFactorMetrics(points: points, profile: profile);
  if (metrics.isEmpty) {
    return const <_NarrativeInsight>[];
  }
  final insights = <_NarrativeInsight>[];
  final watchMetric = metrics.reduce((a, b) => a.value <= b.value ? a : b);
  final steadyMetric = metrics.reduce((a, b) => a.value >= b.value ? a : b);
  final improvingMetric = _mostImprovingMetric(metrics, points, profile);

  insights.add(
    _NarrativeInsight(
      title: 'What needs extra care',
      body: _watchBodyForFactor(watchMetric.factorKey),
      evidence: _factorEvidence(points, watchMetric.factorKey),
      icon: Icons.visibility_rounded,
      color: const Color(0xFFD97706),
    ),
  );

  insights.add(
    _NarrativeInsight(
      title: 'What looks steadier',
      body: _steadyBodyForFactor(steadyMetric.factorKey),
      evidence: _steadyEvidence(points, steadyMetric.factorKey),
      icon: Icons.trending_up_rounded,
      color: const Color(0xFF239B72),
    ),
  );

  if (improvingMetric != null) {
    insights.add(
      _NarrativeInsight(
        title: 'What changed over this view',
        body: _improvingBodyForFactor(improvingMetric.factorKey),
        evidence: _changeEvidence(points, improvingMetric.factorKey),
        icon: Icons.sync_alt_rounded,
        color: improvingMetric.color,
      ),
    );
  } else if (_pairedLowDays(points, 'sleep', 'energy') >= 2) {
    insights.add(
      _NarrativeInsight(
        title: 'Pattern worth noticing',
        body: 'Sleep and energy have been moving together.',
        evidence:
            'On ${_pairedLowDays(points, 'sleep', 'energy')} recent check-ins, harder sleep and lower energy showed up on the same day.',
        icon: Icons.bedtime_rounded,
        color: const Color(0xFF0F766E),
      ),
    );
  } else if (_pairedLowDays(points, 'mood', 'connectedness') >= 2) {
    insights.add(
      _NarrativeInsight(
        title: 'Pattern worth noticing',
        body: 'Mood and support seem linked in this view.',
        evidence:
            'On ${_pairedLowDays(points, 'mood', 'connectedness')} recent check-ins, lower mood and lower support showed up together.',
        icon: Icons.groups_rounded,
        color: const Color(0xFF7C3AED),
      ),
    );
  }

  insights.add(
    _NarrativeInsight(
      title: 'Best next step',
      body: _nextStepBody(watchMetric.factorKey, summary),
      evidence: _nextStepEvidence(watchMetric.factorKey, points),
      icon: Icons.arrow_forward_rounded,
      color: const Color(0xFF0F766E),
    ),
  );
  return insights;
}

WellbeingFactorMetric? _mostImprovingMetric(
  List<WellbeingFactorMetric> metrics,
  List<WellbeingTrendPoint> points,
  StudentWellbeingProfile? profile,
) {
  WellbeingFactorMetric? best;
  var bestDelta = 0.0;
  for (final metric in metrics) {
    final delta = _trendDelta(points, metric.factorKey);
    if (delta < bestDelta) {
      bestDelta = delta;
      best = metric;
    }
  }
  if (bestDelta <= -0.35) {
    return best;
  }
  return null;
}

double _trendDelta(List<WellbeingTrendPoint> points, String factorKey) {
  final values = points
      .map((point) => point.factorScores[factorKey])
      .whereType<double>()
      .toList();
  if (values.length < 3) {
    return 0;
  }
  final splitIndex = max(1, values.length ~/ 2);
  final first = values.take(splitIndex).toList();
  final second = values.skip(splitIndex).toList();
  if (first.isEmpty || second.isEmpty) {
    return 0;
  }
  return _average(second) - _average(first);
}

String _selectedFactorSubtitle({
  required String factorKey,
  required List<WellbeingTrendPoint> points,
}) {
  if (factorKey == 'overall') {
    return dailyStateHeadline(points);
  }
  return _factorEvidence(points, factorKey);
}

String _factorEvidence(List<WellbeingTrendPoint> points, String factorKey) {
  final count = points.length;
  final elevated = _elevatedDayCount(points, factorKey);
  final steady = _steadyDayCount(points, factorKey);
  if (count == 0) {
    return 'No check-ins are available for this view yet.';
  }
  return '${_factorLabel(factorKey)} felt strained on $elevated of $count check-ins and steadier on $steady of $count.';
}

String _steadyEvidence(List<WellbeingTrendPoint> points, String factorKey) {
  final count = points.length;
  final steady = _steadyDayCount(points, factorKey);
  final average = _displayPercent(_averageFactor(points, factorKey));
  return '${_factorLabel(factorKey)} looked steadier on $steady of $count check-ins, with an average steadiness of $average.';
}

String _changeEvidence(List<WellbeingTrendPoint> points, String factorKey) {
  final delta = _trendDelta(points, factorKey);
  final firstAverage = _averageFirstHalf(points, factorKey);
  final secondAverage = _averageSecondHalf(points, factorKey);
  if (firstAverage == null || secondAverage == null) {
    return _factorEvidence(points, factorKey);
  }
  final direction = delta < 0 ? 'improved' : 'got harder';
  return '${_factorLabel(factorKey)} $direction from ${_displayPercent(firstAverage)} to ${_displayPercent(secondAverage)} between the earlier and later part of this view.';
}

String _watchBodyForFactor(String factorKey) {
  return switch (factorKey) {
    'sleep' => 'Sleep has felt heavier lately.',
    'energy' => 'Energy has been dipping more often.',
    'mood' => 'Mood has been lower on several recent days.',
    'stress' => 'Pressure has been showing up often.',
    'physical_wellbeing' => 'Body signals have been showing up more often.',
    'connectedness' => 'Support has felt harder to reach lately.',
    _ => 'This area has been carrying more strain recently.',
  };
}

String _steadyBodyForFactor(String factorKey) {
  return switch (factorKey) {
    'sleep' => 'Sleep looks like one of the steadier parts of this period.',
    'energy' => 'Energy has held up better than the other areas.',
    'mood' => 'Mood has looked steadier than the other areas.',
    'stress' => 'Pressure has stayed more manageable here.',
    'physical_wellbeing' =>
      'Body signals have looked relatively settled in this view.',
    'connectedness' => 'Support has felt more present here.',
    _ => 'This area looks steadier than the rest right now.',
  };
}

String _improvingBodyForFactor(String factorKey) {
  return switch (factorKey) {
    'sleep' => 'Sleep has been trending in a better direction.',
    'energy' => 'Energy has been picking back up.',
    'mood' => 'Mood has been lifting compared with the earlier part of this view.',
    'stress' => 'Pressure looks a little lighter than before.',
    'physical_wellbeing' => 'Body-related discomfort has eased a little.',
    'connectedness' => 'Feeling supported has been improving.',
    _ => 'This area has been moving in a steadier direction.',
  };
}

String _nextStepBody(String factorKey, StudentWeeklySummary summary) {
  final recommendation = _recommendedThemeForFactor(factorKey);
  final nudge = summary.summary['support_nudge']?.toString();
  if (nudge != null && nudge.trim().isNotEmpty) {
    return nudge.trim();
  }
  return switch (factorKey) {
    'sleep' =>
      'Open the sleep lane next so you can try one small rest reset rather than changing everything at once.',
    'energy' =>
      'Open the sleep or stress lane next and look for one habit that could help your energy recover.',
    'mood' =>
      'Use Buddy or Journal next so you can name what has been sitting with you and decide on one next step.',
    'stress' =>
      'Open the stress lane or Calm Breathing next so the pressure does not keep stacking up.',
    'physical_wellbeing' =>
      'Keep the next step simple: body rest, hydration, and asking for support earlier if this keeps repeating.',
    'connectedness' =>
      'Buddy, Journal, or one support-focused lesson would be the best next step here.',
    _ => 'Open $recommendation next and keep the next step small.',
  };
}

String _nextStepEvidence(String factorKey, List<WellbeingTrendPoint> points) {
  final elevated = _elevatedDayCount(points, factorKey);
  final count = points.length;
  return 'This recommendation is based on ${_factorLabel(factorKey).toLowerCase()} showing strain on $elevated of $count check-ins in this view.';
}

String _recommendedThemeForFactor(String factorKey) {
  return switch (factorKey) {
    'sleep' => 'Sleep Reset',
    'energy' => 'Sleep Reset',
    'mood' => 'Journal or Buddy',
    'stress' => 'Stress Reset',
    'physical_wellbeing' => 'a body-care support step',
    'connectedness' => 'Buddy or support lessons',
    _ => 'the most relevant support lane',
  };
}

int _elevatedDayCount(List<WellbeingTrendPoint> points, String factorKey) {
  return points
      .map((point) => point.factorScores[factorKey])
      .whereType<double>()
      .where((value) => value >= 2.6)
      .length;
}

int _steadyDayCount(List<WellbeingTrendPoint> points, String factorKey) {
  return points
      .map((point) => point.factorScores[factorKey])
      .whereType<double>()
      .where((value) => value <= 1.5)
      .length;
}

int _pairedLowDays(
  List<WellbeingTrendPoint> points,
  String firstFactor,
  String secondFactor,
) {
  var count = 0;
  for (final point in points) {
    final first = point.factorScores[firstFactor];
    final second = point.factorScores[secondFactor];
    if (first != null && second != null && first >= 2.6 && second >= 2.6) {
      count += 1;
    }
  }
  return count;
}

double? _averageFactor(List<WellbeingTrendPoint> points, String factorKey) {
  final values = points
      .map((point) => point.factorScores[factorKey])
      .whereType<double>()
      .toList();
  if (values.isEmpty) {
    return null;
  }
  return _average(values);
}

double? _averageFirstHalf(List<WellbeingTrendPoint> points, String factorKey) {
  final values = points
      .map((point) => point.factorScores[factorKey])
      .whereType<double>()
      .toList();
  if (values.length < 2) {
    return null;
  }
  final split = max(1, values.length ~/ 2);
  return _average(values.take(split).toList());
}

double? _averageSecondHalf(List<WellbeingTrendPoint> points, String factorKey) {
  final values = points
      .map((point) => point.factorScores[factorKey])
      .whereType<double>()
      .toList();
  if (values.length < 2) {
    return null;
  }
  final split = max(1, values.length ~/ 2);
  final second = values.skip(split).toList();
  if (second.isEmpty) {
    return null;
  }
  return _average(second);
}

double _average(List<double> values) {
  final total = values.fold<double>(0, (sum, value) => sum + value);
  return total / max(1, values.length);
}

String _displayPercent(double? rawValue) {
  if (rawValue == null) {
    return '-';
  }
  final percent = (((4 - rawValue) / 4) * 100).round();
  return '$percent%';
}

String _factorLabel(String factorKey) {
  return switch (factorKey) {
    'sleep' => 'Sleep',
    'energy' => 'Energy',
    'mood' => 'Mood',
    'stress' => 'Stress',
    'physical_wellbeing' => 'Physical wellbeing',
    'connectedness' => 'Support',
    _ => factorKey,
  };
}

Future<StudentWeeklySummary> _loadWeeklySummaryOrFallback({
  required BahaApiClient apiClient,
  required DevelopmentIdentity identity,
  required int completedCheckinCount,
}) async {
  try {
    return await apiClient.getStudentWeeklySummary(identity: identity);
  } on BahaApiException catch (error) {
    if (error.statusCode != 404) {
      rethrow;
    }
    return _buildEmptyWeeklySummary(
      identity: identity,
      completedCheckinCount: completedCheckinCount,
    );
  }
}

StudentWeeklySummary _buildEmptyWeeklySummary({
  required DevelopmentIdentity identity,
  required int completedCheckinCount,
}) {
  final now = DateTime.now();
  final weekStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));
  return StudentWeeklySummary(
    id: 'local-empty-summary-${identity.externalAuthId}',
    studentProfileId: '',
    weekStart: weekStart,
    weekEnd: weekEnd,
    privacyTierApplied: 'private',
    summaryStatus: 'not_started',
    summary: <String, dynamic>{
      'headline': completedCheckinCount == 0
          ? 'Complete your first few daily check-ins to unlock your analysis view.'
          : 'Keep going. BAHA needs a few more check-ins before it can show real patterns.',
      'is_placeholder': true,
    },
    sourceWindow: <String, dynamic>{'checkins': completedCheckinCount},
    generationVersion: 'first-use-placeholder',
    generatedAt: now,
  );
}
