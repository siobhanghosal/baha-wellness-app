import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'telemetry_service.dart';

class MiniGamesController extends ChangeNotifier {
  MiniGamesController({this._preferences, TelemetryService? telemetryService})
    : _telemetryService = telemetryService ?? TelemetryService();

  static const _settingsKey = 'baha_mini_games.settings';
  static const _progressKey = 'baha_mini_games.progress';
  static const _unlockedKey = 'baha_mini_games.achievements';

  final TelemetryService _telemetryService;
  SharedPreferences? _preferences;
  bool _isLoading = true;
  MiniGameSettings _settings = const MiniGameSettings(
    soundEnabled: true,
    musicEnabled: true,
    hapticsEnabled: true,
    darkMode: false,
  );
  final Map<String, MiniGameProgressSnapshot> _progress =
      <String, MiniGameProgressSnapshot>{};
  final List<MiniGameTelemetryRecord> _telemetry = <MiniGameTelemetryRecord>[];
  final Set<String> _unlockedAchievements = <String>{};

  bool get isLoading => _isLoading;
  MiniGameSettings get settings => _settings;
  List<MiniGameTelemetryRecord> get telemetry => List.unmodifiable(_telemetry);

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    _settings = MiniGameSettings.fromJson(_readMap(_settingsKey));
    _progress
      ..clear()
      ..addAll(
        _readMap(_progressKey).map(
          (key, value) => MapEntry(
            key,
            MiniGameProgressSnapshot.fromJson(value as Map<String, dynamic>?),
          ),
        ),
      );
    _telemetry
      ..clear()
      ..addAll(await _telemetryService.loadRecords());
    _unlockedAchievements
      ..clear()
      ..addAll((_preferences?.getStringList(_unlockedKey) ?? const <String>[]));
    _isLoading = false;
    notifyListeners();
  }

  MiniGameProgressSnapshot progressFor(String gameId) {
    return _progress[gameId] ??
        const MiniGameProgressSnapshot(
          bestScore: 0,
          personalBestTimeMs: 0,
          coins: 0,
          xp: 0,
          highestLevelReached: 0,
          playCount: 0,
          retryCount: 0,
          lastPlayedIso: null,
        );
  }

  MiniGameDailyChallenge dailyChallengeFor(MiniGameDefinition definition) {
    final date = DateTime.now().toUtc();
    final seed = '${definition.id}-${date.year}-${date.month}-${date.day}';
    final hash = seed.codeUnits.fold<int>(
      0,
      (value, codeUnit) => value + codeUnit,
    );
    return MiniGameDailyChallenge(
      label: 'Daily challenge: ${definition.title}',
      targetScore: 100 + (hash % 250),
      seed: seed,
    );
  }

  List<MiniGameAchievement> achievementsFor(String gameId) {
    final progress = progressFor(gameId);
    return <MiniGameAchievement>[
      MiniGameAchievement(
        id: '$gameId.first-play',
        title: 'First Start',
        description: 'Play the game once.',
        icon: Icons.play_arrow_rounded,
        unlocked: progress.playCount > 0,
      ),
      MiniGameAchievement(
        id: '$gameId.scorer',
        title: 'Score Builder',
        description: 'Reach 250 points.',
        icon: Icons.emoji_events_rounded,
        unlocked: progress.bestScore >= 250,
      ),
      MiniGameAchievement(
        id: '$gameId.grinder',
        title: 'Practice Pays Off',
        description: 'Complete 5 sessions.',
        icon: Icons.repeat_rounded,
        unlocked: progress.playCount >= 5,
      ),
      MiniGameAchievement(
        id: '$gameId.master',
        title: 'Arcade Master',
        description: 'Hit 1000 points or more.',
        icon: Icons.stars_rounded,
        unlocked: progress.bestScore >= 1000,
      ),
    ];
  }

  MiniGameStatistics statisticsFor(String gameId) {
    final sessions = _telemetry
        .where((event) => event.gameId == gameId)
        .toList();
    if (sessions.isEmpty) {
      return const MiniGameStatistics(
        sessionsPlayed: 0,
        completions: 0,
        bestScore: 0,
        averageScore: 0,
        averageAccuracy: 0,
        averageDurationMs: 0,
        totalCoins: 0,
        totalXp: 0,
        lastPlayedIso: null,
      );
    }
    final completions = sessions.where((event) => event.completed).length;
    final scores = sessions.map((event) => event.score).toList();
    final averageScore = scores.fold<int>(0, (a, b) => a + b) / sessions.length;
    final averageAccuracy =
        sessions
            .map((event) => event.accuracy)
            .fold<double>(0, (a, b) => a + b) /
        sessions.length;
    final averageDurationMs =
        sessions
            .map((event) => event.sessionDurationMs)
            .fold<int>(0, (a, b) => a + b) ~/
        sessions.length;
    final totalCoins = _progress[gameId]?.coins ?? 0;
    final totalXp = _progress[gameId]?.xp ?? 0;
    return MiniGameStatistics(
      sessionsPlayed: sessions.length,
      completions: completions,
      bestScore: scores.reduce(math.max),
      averageScore: averageScore,
      averageAccuracy: averageAccuracy,
      averageDurationMs: averageDurationMs,
      totalCoins: totalCoins,
      totalXp: totalXp,
      lastPlayedIso: sessions.last.timestampIso,
    );
  }

  Future<void> updateSettings(MiniGameSettings settings) async {
    _settings = settings;
    await _writeJson(_settingsKey, settings.toJson());
    notifyListeners();
  }

  Future<void> toggleSound() =>
      updateSettings(_settings.copyWith(soundEnabled: !_settings.soundEnabled));
  Future<void> toggleMusic() =>
      updateSettings(_settings.copyWith(musicEnabled: !_settings.musicEnabled));
  Future<void> toggleHaptics() => updateSettings(
    _settings.copyWith(hapticsEnabled: !_settings.hapticsEnabled),
  );
  Future<void> toggleDarkMode() =>
      updateSettings(_settings.copyWith(darkMode: !_settings.darkMode));

  Future<void> recordSession({
    required String gameId,
    required MiniGameResult result,
  }) async {
    final previous = progressFor(gameId);
    final bestScore = math.max(previous.bestScore, result.score);
    final bestTime = previous.personalBestTimeMs == 0
        ? result.durationMs
        : math.min(previous.personalBestTimeMs, result.durationMs);
    final updated = previous.copyWith(
      bestScore: bestScore,
      personalBestTimeMs: bestTime,
      coins: previous.coins + math.max(1, result.score ~/ 25),
      xp: previous.xp + math.max(10, result.score ~/ 10),
      highestLevelReached: math.max(
        previous.highestLevelReached,
        result.levelReached,
      ),
      playCount: previous.playCount + 1,
      retryCount: previous.retryCount + result.retryCount,
      lastPlayedIso: DateTime.now().toIso8601String(),
    );
    _progress[gameId] = updated;
    final telemetryRecord = MiniGameTelemetryRecord(
      gameId: gameId,
      timestampIso: DateTime.now().toIso8601String(),
      score: result.score,
      highScore: updated.bestScore,
      completionRate: result.completed ? 1 : 0,
      retryCount: result.retryCount,
      reactionTimeMs: result.reactionTimeMs,
      sessionDurationMs: result.durationMs,
      accuracy: result.accuracy,
      averageDecisionTimeMs: result.averageDecisionTimeMs,
      difficultyPlayed: result.difficultyPlayed,
      levelReached: result.levelReached,
      improvementCurve: result.improvementCurve,
      consecutiveWins: result.consecutiveWins,
      consecutiveLosses: result.consecutiveLosses,
      completed: result.completed,
      moves: result.moves,
      mistakes: result.mistakes,
      comboCount: result.comboCount,
      longestCombo: result.longestCombo,
      hintsUsed: result.hintsUsed,
      quitBeforeFinish: result.quitBeforeFinish,
      averageTimePerMoveMs: result.moves == 0
          ? 0
          : result.durationMs ~/ result.moves,
      metadata: result.metadata,
    );
    _telemetry.add(telemetryRecord);
    while (_telemetry.length > 200) {
      _telemetry.removeAt(0);
    }
    await _telemetryService.record(telemetryRecord);
    _unlockedAchievements.addAll(
      achievementsFor(gameId)
          .where((achievement) => achievement.unlocked)
          .map((achievement) => achievement.id),
    );
    await _writeJson(
      _progressKey,
      _progress.map((key, value) => MapEntry(key, value.toJson())),
    );
    await _writeStringList(
      _unlockedKey,
      _unlockedAchievements.toList()..sort(),
    );
    notifyListeners();
  }

  bool isAchievementUnlocked(String id) => _unlockedAchievements.contains(id);

  Future<String> exportTelemetryJson() => _telemetryService.exportJson();

  DashboardSummary dashboardSummary(List<MiniGameDefinition> definitions) {
    final sessions = List<MiniGameTelemetryRecord>.from(_telemetry)
      ..sort((a, b) => b.timestampIso.compareTo(a.timestampIso));
    final totalPlayTimeMs = sessions.fold<int>(
      0,
      (sum, session) => sum + session.sessionDurationMs,
    );
    final averageSessionMs = sessions.isEmpty
        ? 0
        : totalPlayTimeMs ~/ sessions.length;
    final bestScore = sessions.isEmpty
        ? 0
        : sessions.map((session) => session.score).reduce(math.max);
    final weeklyActivity = <String, int>{
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };
    final monthlyActivity = <String, int>{};
    for (final session in sessions) {
      final timestamp = DateTime.tryParse(session.timestampIso)?.toLocal();
      if (timestamp == null) {
        continue;
      }
      const weekdays = <String>[
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ];
      weeklyActivity[weekdays[timestamp.weekday - 1]] =
          (weeklyActivity[weekdays[timestamp.weekday - 1]] ?? 0) + 1;
      final monthKey =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
      monthlyActivity[monthKey] = (monthlyActivity[monthKey] ?? 0) + 1;
    }
    final definitionById = {
      for (final definition in definitions) definition.id: definition,
    };
    final grouped = <String, List<MiniGameTelemetryRecord>>{};
    for (final session in sessions) {
      grouped
          .putIfAbsent(session.gameId, () => <MiniGameTelemetryRecord>[])
          .add(session);
    }
    final favouriteGames = grouped.entries.map((entry) {
      final title = definitionById[entry.key]?.title ?? entry.key;
      final gameSessions = entry.value;
      final totalTime = gameSessions.fold<int>(
        0,
        (sum, session) => sum + session.sessionDurationMs,
      );
      final completionRate =
          gameSessions.where((session) => session.completed).length /
          gameSessions.length;
      return DashboardGameSnapshot(
        gameId: entry.key,
        title: title,
        sessions: gameSessions.length,
        bestScore: gameSessions
            .map((session) => session.score)
            .reduce(math.max),
        averageScore:
            gameSessions.fold<int>(0, (sum, session) => sum + session.score) /
            gameSessions.length,
        totalPlayTimeMs: totalTime,
        completionRate: completionRate,
      );
    }).toList()..sort((a, b) => b.sessions.compareTo(a.sessions));
    final behaviourIndicators = _buildBehaviourIndicators(sessions, grouped);
    final personalBests = {
      for (final game in favouriteGames) game.title: game.bestScore,
    };
    final summaryLines = _buildSummaryLines(
      behaviourIndicators,
      favouriteGames,
    );
    return DashboardSummary(
      totalSessions: sessions.length,
      totalPlayTimeMs: totalPlayTimeMs,
      averageSessionMs: averageSessionMs,
      bestScore: bestScore,
      recentActivity: sessions.take(6).toList(),
      favouriteGames: favouriteGames.take(6).toList(),
      weeklyActivity: weeklyActivity,
      monthlyActivity: monthlyActivity,
      behaviourIndicators: behaviourIndicators,
      personalBests: personalBests,
      summaryLines: summaryLines,
    );
  }

  List<BehaviourIndicator> _buildBehaviourIndicators(
    List<MiniGameTelemetryRecord> sessions,
    Map<String, List<MiniGameTelemetryRecord>> grouped,
  ) {
    if (sessions.isEmpty) {
      const emptyConfidence = 0.0;
      return const <BehaviourIndicator>[
        BehaviourIndicator(
          label: 'Persistence',
          score: 0,
          confidence: emptyConfidence,
        ),
        BehaviourIndicator(
          label: 'Attention',
          score: 0,
          confidence: emptyConfidence,
        ),
        BehaviourIndicator(
          label: 'Planning',
          score: 0,
          confidence: emptyConfidence,
        ),
        BehaviourIndicator(
          label: 'Adaptability',
          score: 0,
          confidence: emptyConfidence,
        ),
        BehaviourIndicator(
          label: 'Precision',
          score: 0,
          confidence: emptyConfidence,
        ),
        BehaviourIndicator(
          label: 'Reaction Speed',
          score: 0,
          confidence: emptyConfidence,
        ),
      ];
    }
    final confidence = (sessions.length / 12).clamp(0.1, 1.0).toDouble();
    final averageAccuracy =
        sessions.fold<double>(0, (sum, session) => sum + session.accuracy) /
        sessions.length;
    final completionRate =
        sessions.where((session) => session.completed).length / sessions.length;
    final averageRetries =
        sessions.fold<int>(0, (sum, session) => sum + session.retryCount) /
        sessions.length;
    final averageMistakes =
        sessions.fold<int>(0, (sum, session) => sum + session.mistakes) /
        sessions.length;
    final averageReactionMs =
        sessions.fold<int>(0, (sum, session) => sum + session.reactionTimeMs) /
        sessions.length;
    final improvement =
        sessions.fold<double>(
          0,
          (sum, session) => sum + session.improvementCurve,
        ) /
        sessions.length;
    final uniqueGames = grouped.keys.length;
    final persistence =
        ((completionRate * 65) + (math.min(averageRetries, 6) / 6 * 20) + 15)
            .clamp(0.0, 100.0);
    final attention =
        ((averageAccuracy * 80) +
                ((1 - (averageMistakes / 6)).clamp(0.0, 1.0) * 20))
            .clamp(0.0, 100.0);
    final planning =
        ((completionRate * 55) + (improvement * 25) + ((uniqueGames / 10) * 20))
            .clamp(0.0, 100.0);
    final adaptability = ((improvement * 60) + ((uniqueGames / 10) * 40)).clamp(
      0.0,
      100.0,
    );
    final precision =
        ((averageAccuracy * 70) +
                ((1 - (averageMistakes / 8)).clamp(0.0, 1.0) * 30))
            .clamp(0.0, 100.0);
    final reactionSpeed =
        ((1 - (averageReactionMs / 1400)).clamp(0.0, 1.0) * 100).clamp(
          0.0,
          100.0,
        );
    return <BehaviourIndicator>[
      BehaviourIndicator(
        label: 'Persistence',
        score: persistence,
        confidence: confidence,
      ),
      BehaviourIndicator(
        label: 'Attention',
        score: attention,
        confidence: confidence,
      ),
      BehaviourIndicator(
        label: 'Planning',
        score: planning,
        confidence: confidence,
      ),
      BehaviourIndicator(
        label: 'Adaptability',
        score: adaptability,
        confidence: confidence,
      ),
      BehaviourIndicator(
        label: 'Precision',
        score: precision,
        confidence: confidence,
      ),
      BehaviourIndicator(
        label: 'Reaction Speed',
        score: reactionSpeed,
        confidence: confidence,
      ),
    ];
  }

  List<String> _buildSummaryLines(
    List<BehaviourIndicator> indicators,
    List<DashboardGameSnapshot> favouriteGames,
  ) {
    if (indicators.isEmpty) {
      return const <String>['Play a few games to unlock behaviour summaries.'];
    }
    final sorted = List<BehaviourIndicator>.from(indicators)
      ..sort((a, b) => b.score.compareTo(a.score));
    final topGame = favouriteGames.isEmpty ? null : favouriteGames.first.title;
    return <String>[
      'Strong ${sorted.first.label.toLowerCase()} across recent sessions.',
      'Most played game: ${topGame ?? 'No favourite yet'}',
      if (sorted.length > 1)
        'Latest telemetry shows improving ${sorted[1].label.toLowerCase()} with more play.',
    ];
  }

  Map<String, dynamic> _readMap(String key) {
    final raw = _preferences?.getString(key);
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  Future<void> _writeJson(String key, Object value) async {
    await _writeString(key, jsonEncode(value));
  }

  Future<void> _writeString(String key, String value) async {
    await _preferences?.setString(key, value);
  }

  Future<void> _writeStringList(String key, List<String> values) async {
    await _preferences?.setStringList(key, values);
  }
}

class MiniGamesScope extends InheritedNotifier<MiniGamesController> {
  const MiniGamesScope({
    super.key,
    required MiniGamesController controller,
    required super.child,
  }) : super(notifier: controller);

  static MiniGamesController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MiniGamesScope>();
    assert(scope != null, 'MiniGamesScope was not found above this context.');
    return scope!.notifier!;
  }
}
