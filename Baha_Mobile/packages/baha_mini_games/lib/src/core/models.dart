import 'dart:convert';

import 'package:flutter/material.dart';

typedef MiniGameBuilder =
    Widget Function(
      BuildContext context,
      dynamic controller,
      MiniGameDefinition definition,
    );

class MiniGameDefinition {
  const MiniGameDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.expectedMinutes,
    required this.builder,
    this.difficultyLabel = 'Skill based',
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final int expectedMinutes;
  final String difficultyLabel;
  final MiniGameBuilder builder;
}

class MiniGameSettings {
  const MiniGameSettings({
    required this.soundEnabled,
    required this.musicEnabled,
    required this.hapticsEnabled,
    required this.darkMode,
  });

  final bool soundEnabled;
  final bool musicEnabled;
  final bool hapticsEnabled;
  final bool darkMode;

  MiniGameSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? hapticsEnabled,
    bool? darkMode,
  }) {
    return MiniGameSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'soundEnabled': soundEnabled,
    'musicEnabled': musicEnabled,
    'hapticsEnabled': hapticsEnabled,
    'darkMode': darkMode,
  };

  static MiniGameSettings fromJson(Map<String, dynamic>? json) {
    return MiniGameSettings(
      soundEnabled: json?['soundEnabled'] as bool? ?? true,
      musicEnabled: json?['musicEnabled'] as bool? ?? true,
      hapticsEnabled: json?['hapticsEnabled'] as bool? ?? true,
      darkMode: json?['darkMode'] as bool? ?? false,
    );
  }
}

class MiniGameTelemetryRecord {
  const MiniGameTelemetryRecord({
    required this.gameId,
    required this.timestampIso,
    required this.score,
    required this.highScore,
    required this.completionRate,
    required this.retryCount,
    required this.reactionTimeMs,
    required this.sessionDurationMs,
    required this.accuracy,
    required this.averageDecisionTimeMs,
    required this.difficultyPlayed,
    required this.levelReached,
    required this.improvementCurve,
    required this.consecutiveWins,
    required this.consecutiveLosses,
    required this.completed,
    this.moves = 0,
    this.mistakes = 0,
    this.comboCount = 0,
    this.longestCombo = 0,
    this.hintsUsed = 0,
    this.quitBeforeFinish = false,
    this.averageTimePerMoveMs = 0,
    this.metadata = const <String, dynamic>{},
  });

  final String gameId;
  final String timestampIso;
  final int score;
  final int highScore;
  final double completionRate;
  final int retryCount;
  final int reactionTimeMs;
  final int sessionDurationMs;
  final double accuracy;
  final int averageDecisionTimeMs;
  final String difficultyPlayed;
  final int levelReached;
  final double improvementCurve;
  final int consecutiveWins;
  final int consecutiveLosses;
  final bool completed;
  final int moves;
  final int mistakes;
  final int comboCount;
  final int longestCombo;
  final int hintsUsed;
  final bool quitBeforeFinish;
  final int averageTimePerMoveMs;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'gameId': gameId,
    'timestampIso': timestampIso,
    'score': score,
    'highScore': highScore,
    'completionRate': completionRate,
    'retryCount': retryCount,
    'reactionTimeMs': reactionTimeMs,
    'sessionDurationMs': sessionDurationMs,
    'accuracy': accuracy,
    'averageDecisionTimeMs': averageDecisionTimeMs,
    'difficultyPlayed': difficultyPlayed,
    'levelReached': levelReached,
    'improvementCurve': improvementCurve,
    'consecutiveWins': consecutiveWins,
    'consecutiveLosses': consecutiveLosses,
    'completed': completed,
    'moves': moves,
    'mistakes': mistakes,
    'comboCount': comboCount,
    'longestCombo': longestCombo,
    'hintsUsed': hintsUsed,
    'quitBeforeFinish': quitBeforeFinish,
    'averageTimePerMoveMs': averageTimePerMoveMs,
    'metadata': metadata,
  };

  static MiniGameTelemetryRecord fromJson(Map<String, dynamic> json) {
    return MiniGameTelemetryRecord(
      gameId: json['gameId'] as String? ?? 'unknown',
      timestampIso:
          json['timestampIso'] as String? ?? DateTime.now().toIso8601String(),
      score: (json['score'] as num?)?.round() ?? 0,
      highScore: (json['highScore'] as num?)?.round() ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
      retryCount: (json['retryCount'] as num?)?.round() ?? 0,
      reactionTimeMs: (json['reactionTimeMs'] as num?)?.round() ?? 0,
      sessionDurationMs: (json['sessionDurationMs'] as num?)?.round() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      averageDecisionTimeMs:
          (json['averageDecisionTimeMs'] as num?)?.round() ?? 0,
      difficultyPlayed: json['difficultyPlayed'] as String? ?? 'normal',
      levelReached: (json['levelReached'] as num?)?.round() ?? 0,
      improvementCurve: (json['improvementCurve'] as num?)?.toDouble() ?? 0,
      consecutiveWins: (json['consecutiveWins'] as num?)?.round() ?? 0,
      consecutiveLosses: (json['consecutiveLosses'] as num?)?.round() ?? 0,
      completed: json['completed'] as bool? ?? false,
      moves: (json['moves'] as num?)?.round() ?? 0,
      mistakes: (json['mistakes'] as num?)?.round() ?? 0,
      comboCount: (json['comboCount'] as num?)?.round() ?? 0,
      longestCombo: (json['longestCombo'] as num?)?.round() ?? 0,
      hintsUsed: (json['hintsUsed'] as num?)?.round() ?? 0,
      quitBeforeFinish: json['quitBeforeFinish'] as bool? ?? false,
      averageTimePerMoveMs:
          (json['averageTimePerMoveMs'] as num?)?.round() ?? 0,
      metadata:
          json['metadata'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );
  }

  static List<MiniGameTelemetryRecord> decodeList(String? jsonValue) {
    if (jsonValue == null || jsonValue.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(jsonValue) as List<dynamic>;
    return decoded
        .map(
          (value) =>
              MiniGameTelemetryRecord.fromJson(value as Map<String, dynamic>),
        )
        .toList();
  }

  static String encodeList(List<MiniGameTelemetryRecord> records) {
    return jsonEncode(records.map((record) => record.toJson()).toList());
  }
}

class MiniGameProgressSnapshot {
  const MiniGameProgressSnapshot({
    required this.bestScore,
    required this.personalBestTimeMs,
    required this.coins,
    required this.xp,
    required this.highestLevelReached,
    required this.playCount,
    required this.retryCount,
    required this.lastPlayedIso,
  });

  final int bestScore;
  final int personalBestTimeMs;
  final int coins;
  final int xp;
  final int highestLevelReached;
  final int playCount;
  final int retryCount;
  final String? lastPlayedIso;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'bestScore': bestScore,
    'personalBestTimeMs': personalBestTimeMs,
    'coins': coins,
    'xp': xp,
    'highestLevelReached': highestLevelReached,
    'playCount': playCount,
    'retryCount': retryCount,
    'lastPlayedIso': lastPlayedIso,
  };

  static MiniGameProgressSnapshot fromJson(Map<String, dynamic>? json) {
    return MiniGameProgressSnapshot(
      bestScore: (json?['bestScore'] as num?)?.round() ?? 0,
      personalBestTimeMs: (json?['personalBestTimeMs'] as num?)?.round() ?? 0,
      coins: (json?['coins'] as num?)?.round() ?? 0,
      xp: (json?['xp'] as num?)?.round() ?? 0,
      highestLevelReached: (json?['highestLevelReached'] as num?)?.round() ?? 0,
      playCount: (json?['playCount'] as num?)?.round() ?? 0,
      retryCount: (json?['retryCount'] as num?)?.round() ?? 0,
      lastPlayedIso: json?['lastPlayedIso'] as String?,
    );
  }

  MiniGameProgressSnapshot copyWith({
    int? bestScore,
    int? personalBestTimeMs,
    int? coins,
    int? xp,
    int? highestLevelReached,
    int? playCount,
    int? retryCount,
    String? lastPlayedIso,
  }) {
    return MiniGameProgressSnapshot(
      bestScore: bestScore ?? this.bestScore,
      personalBestTimeMs: personalBestTimeMs ?? this.personalBestTimeMs,
      coins: coins ?? this.coins,
      xp: xp ?? this.xp,
      highestLevelReached: highestLevelReached ?? this.highestLevelReached,
      playCount: playCount ?? this.playCount,
      retryCount: retryCount ?? this.retryCount,
      lastPlayedIso: lastPlayedIso ?? this.lastPlayedIso,
    );
  }
}

class MiniGameAchievement {
  const MiniGameAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
}

class MiniGameResult {
  const MiniGameResult({
    required this.score,
    required this.completed,
    required this.durationMs,
    this.retryCount = 0,
    this.reactionTimeMs = 0,
    this.accuracy = 0,
    this.averageDecisionTimeMs = 0,
    this.levelReached = 0,
    this.difficultyPlayed = 'normal',
    this.improvementCurve = 0,
    this.consecutiveWins = 0,
    this.consecutiveLosses = 0,
    this.moves = 0,
    this.mistakes = 0,
    this.comboCount = 0,
    this.longestCombo = 0,
    this.hintsUsed = 0,
    this.quitBeforeFinish = false,
    this.metadata = const <String, dynamic>{},
  });

  final int score;
  final bool completed;
  final int durationMs;
  final int retryCount;
  final int reactionTimeMs;
  final double accuracy;
  final int averageDecisionTimeMs;
  final int levelReached;
  final String difficultyPlayed;
  final double improvementCurve;
  final int consecutiveWins;
  final int consecutiveLosses;
  final int moves;
  final int mistakes;
  final int comboCount;
  final int longestCombo;
  final int hintsUsed;
  final bool quitBeforeFinish;
  final Map<String, dynamic> metadata;
}

class MiniGameDailyChallenge {
  const MiniGameDailyChallenge({
    required this.label,
    required this.targetScore,
    required this.seed,
  });

  final String label;
  final int targetScore;
  final String seed;
}

class MiniGameStatistics {
  const MiniGameStatistics({
    required this.sessionsPlayed,
    required this.completions,
    required this.bestScore,
    required this.averageScore,
    required this.averageAccuracy,
    required this.averageDurationMs,
    required this.totalCoins,
    required this.totalXp,
    required this.lastPlayedIso,
  });

  final int sessionsPlayed;
  final int completions;
  final int bestScore;
  final double averageScore;
  final double averageAccuracy;
  final int averageDurationMs;
  final int totalCoins;
  final int totalXp;
  final String? lastPlayedIso;
}

class BehaviourIndicator {
  const BehaviourIndicator({
    required this.label,
    required this.score,
    required this.confidence,
  });

  final String label;
  final double score;
  final double confidence;
}

class DashboardGameSnapshot {
  const DashboardGameSnapshot({
    required this.gameId,
    required this.title,
    required this.sessions,
    required this.bestScore,
    required this.averageScore,
    required this.totalPlayTimeMs,
    required this.completionRate,
  });

  final String gameId;
  final String title;
  final int sessions;
  final int bestScore;
  final double averageScore;
  final int totalPlayTimeMs;
  final double completionRate;
}

class DashboardSummary {
  const DashboardSummary({
    required this.totalSessions,
    required this.totalPlayTimeMs,
    required this.averageSessionMs,
    required this.bestScore,
    required this.recentActivity,
    required this.favouriteGames,
    required this.weeklyActivity,
    required this.monthlyActivity,
    required this.behaviourIndicators,
    required this.personalBests,
    required this.summaryLines,
  });

  final int totalSessions;
  final int totalPlayTimeMs;
  final int averageSessionMs;
  final int bestScore;
  final List<MiniGameTelemetryRecord> recentActivity;
  final List<DashboardGameSnapshot> favouriteGames;
  final Map<String, int> weeklyActivity;
  final Map<String, int> monthlyActivity;
  final List<BehaviourIndicator> behaviourIndicators;
  final Map<String, int> personalBests;
  final List<String> summaryLines;
}
