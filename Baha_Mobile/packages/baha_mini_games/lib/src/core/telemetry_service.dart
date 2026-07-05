import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class TelemetryService {
  static const _databaseName = 'baha_mini_games_telemetry.db';
  static const _databaseVersion = 1;
  static const _eventsTable = 'telemetry_events';

  Database? _database;

  Future<void> initialize() async {
    if (_database != null) {
      return;
    }
    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(databasesPath, _databaseName);
    _database = await openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_eventsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            gameId TEXT NOT NULL,
            timestampIso TEXT NOT NULL,
            score INTEGER NOT NULL,
            highScore INTEGER NOT NULL,
            completionRate REAL NOT NULL,
            retryCount INTEGER NOT NULL,
            reactionTimeMs INTEGER NOT NULL,
            sessionDurationMs INTEGER NOT NULL,
            accuracy REAL NOT NULL,
            averageDecisionTimeMs INTEGER NOT NULL,
            difficultyPlayed TEXT NOT NULL,
            levelReached INTEGER NOT NULL,
            improvementCurve REAL NOT NULL,
            consecutiveWins INTEGER NOT NULL,
            consecutiveLosses INTEGER NOT NULL,
            completed INTEGER NOT NULL,
            moves INTEGER NOT NULL,
            mistakes INTEGER NOT NULL,
            comboCount INTEGER NOT NULL,
            longestCombo INTEGER NOT NULL,
            hintsUsed INTEGER NOT NULL,
            quitBeforeFinish INTEGER NOT NULL,
            averageTimePerMoveMs INTEGER NOT NULL,
            metadataJson TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<MiniGameTelemetryRecord>> loadRecords() async {
    await initialize();
    final rows = await _database!.query(
      _eventsTable,
      orderBy: 'timestampIso ASC, id ASC',
    );
    return rows
        .map(
          (row) => MiniGameTelemetryRecord.fromJson(
            Map<String, dynamic>.from(row)
              ..['completed'] = row['completed'] == 1
              ..['quitBeforeFinish'] = row['quitBeforeFinish'] == 1
              ..['metadata'] = _decodeMetadata(row['metadataJson'] as String?),
          ),
        )
        .toList();
  }

  Future<void> record(MiniGameTelemetryRecord record) async {
    await initialize();
    await _database!.insert(
      _eventsTable,
      <String, Object?>{
        ...record.toJson(),
        'completed': record.completed ? 1 : 0,
        'quitBeforeFinish': record.quitBeforeFinish ? 1 : 0,
        'metadataJson': jsonEncode(record.metadata),
      }..remove('metadata'),
    );
  }

  Future<String> exportJson() async {
    final records = await loadRecords();
    return jsonEncode(records.map((record) => record.toJson()).toList());
  }

  Map<String, dynamic> _decodeMetadata(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic>
        ? decoded
        : const <String, dynamic>{};
  }
}
