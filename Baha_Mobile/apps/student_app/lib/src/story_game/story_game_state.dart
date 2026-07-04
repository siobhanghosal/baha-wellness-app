import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../prototype/prototype_models.dart';
import 'game_api.dart';

class WorldLocation {
  const WorldLocation({
    required this.id,
    required this.name,
    required this.emoji,
    required this.subtitle,
    required this.color,
    required this.unlockStars,
    required this.npc,
  });

  final String id;
  final String name;
  final String emoji;
  final String subtitle;
  final Color color;
  final int unlockStars;
  final String npc;
}

const worldLocations = <WorldLocation>[
  WorldLocation(
    id: 'home',
    name: 'Home',
    emoji: '🏡',
    subtitle: 'Family moments, daily routines, and small choices.',
    color: Color(0xFFFF8A65),
    unlockStars: 0,
    npc: 'Ria',
  ),
  WorldLocation(
    id: 'school',
    name: 'School',
    emoji: '🏫',
    subtitle: 'Class, teamwork, and learning one step at a time.',
    color: Color(0xFF42A5F5),
    unlockStars: 0,
    npc: 'Maya',
  ),
  WorldLocation(
    id: 'forest',
    name: 'Friends',
    emoji: '🧑‍🤝‍🧑',
    subtitle: 'Play, friendship, and finding kind ways forward.',
    color: Color(0xFF43A047),
    unlockStars: 0,
    npc: 'Niko',
  ),
  WorldLocation(
    id: 'castle',
    name: 'Confidence',
    emoji: '🏰',
    subtitle: 'Brave choices, speaking up, and believing in yourself.',
    color: Color(0xFFAB47BC),
    unlockStars: 8,
    npc: 'Coach Lina',
  ),
  WorldLocation(
    id: 'park',
    name: 'Fun',
    emoji: '🛝',
    subtitle: 'Games, laughter, and trying new ideas together.',
    color: Color(0xFFEC407A),
    unlockStars: 12,
    npc: 'Zoya',
  ),
  WorldLocation(
    id: 'beach',
    name: 'Calm',
    emoji: '🌊',
    subtitle: 'Feelings, reset moments, and peaceful pauses.',
    color: Color(0xFF00ACC1),
    unlockStars: 16,
    npc: 'Ollie',
  ),
];

class StoryScene {
  const StoryScene({
    required this.chapter,
    required this.title,
    required this.body,
    required this.prompt,
  });

  final int chapter;
  final String title;
  final String body;
  final String prompt;
}

enum PlayerMood { joyful, calm, curious, proud, nervous, frustrated }

extension PlayerMoodX on PlayerMood {
  String get label => switch (this) {
    PlayerMood.joyful => 'Joyful',
    PlayerMood.calm => 'Calm',
    PlayerMood.curious => 'Curious',
    PlayerMood.proud => 'Proud',
    PlayerMood.nervous => 'Nervous',
    PlayerMood.frustrated => 'Frustrated',
  };

  String get emoji => switch (this) {
    PlayerMood.joyful => '😊',
    PlayerMood.calm => '🫧',
    PlayerMood.curious => '🧠',
    PlayerMood.proud => '🌟',
    PlayerMood.nervous => '💓',
    PlayerMood.frustrated => '😖',
  };
}

class StoryAnswerRecord {
  const StoryAnswerRecord({
    required this.locationId,
    required this.locationName,
    required this.npcName,
    required this.answer,
    required this.response,
    required this.memory,
    required this.chapter,
    required this.mood,
    required this.createdAtIso,
  });

  final String locationId;
  final String locationName;
  final String npcName;
  final String answer;
  final String response;
  final String memory;
  final int chapter;
  final PlayerMood mood;
  final String createdAtIso;

  Map<String, dynamic> toJson() => {
    'locationId': locationId,
    'locationName': locationName,
    'npcName': npcName,
    'answer': answer,
    'response': response,
    'memory': memory,
    'chapter': chapter,
    'mood': mood.name,
    'createdAtIso': createdAtIso,
  };

  static StoryAnswerRecord? fromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    return StoryAnswerRecord(
      locationId: raw['locationId'] as String? ?? '',
      locationName: raw['locationName'] as String? ?? '',
      npcName: raw['npcName'] as String? ?? '',
      answer: raw['answer'] as String? ?? '',
      response: raw['response'] as String? ?? '',
      memory: raw['memory'] as String? ?? '',
      chapter: raw['chapter'] as int? ?? 1,
      mood: PlayerMood.values.firstWhere(
        (item) => item.name == raw['mood'],
        orElse: () => PlayerMood.curious,
      ),
      createdAtIso: raw['createdAtIso'] as String? ?? '',
    );
  }
}

class StoryTurnResult {
  const StoryTurnResult({required this.record, required this.scene});

  final StoryAnswerRecord record;
  final StoryScene scene;
}

class StoryGameState extends ChangeNotifier {
  static const _storageKey = 'baha.story_world.v1';
  static const _playerKeyStorageKey = 'baha.story_world.player_key.v1';

  SharedPreferences? _preferences;
  GameApi? _api;

  bool _isLoaded = false;
  bool _isLoadingScene = false;
  bool _isSubmitting = false;
  bool _backendOnline = false;
  String? _errorMessage;

  StudentAgeGroup _ageGroup = StudentAgeGroup.child;
  StudentGender _gender = StudentGender.female;
  String _playerName = 'Adventurer';
  String _playerKey = '';
  int _ageYears = 10;
  int _xp = 0;
  int _coins = 0;
  int _stars = 0;
  int _day = 1;
  PlayerMood _selfReportedMood = PlayerMood.curious;
  String _selectedLocationId = worldLocations.first.id;
  final Map<String, int> _chapterByLocation = {
    for (final location in worldLocations) location.id: 1,
  };
  final Map<String, String> _lastChoiceByLocation = {};
  final Map<String, StoryScene> _sceneByLocation = {};
  final List<StoryAnswerRecord> _records = [];

  bool get isLoaded => _isLoaded;
  bool get isLoadingScene => _isLoadingScene;
  bool get isSubmitting => _isSubmitting;
  bool get backendOnline => _backendOnline;
  String? get errorMessage => _errorMessage;
  StudentAgeGroup get ageGroup => _ageGroup;
  StudentGender get gender => _gender;
  String get playerName => _playerName;
  int get ageYears => _ageYears;
  int get xp => _xp;
  int get coins => _coins;
  int get stars => _stars;
  int get day => _day;
  PlayerMood get selfReportedMood => _selfReportedMood;
  String get selectedLocationId => _selectedLocationId;
  WorldLocation get selectedLocation => worldLocations.firstWhere(
    (location) => location.id == _selectedLocationId,
    orElse: () => worldLocations.first,
  );
  StoryScene? get currentScene => _sceneByLocation[_selectedLocationId];
  List<StoryAnswerRecord> get allRecords => List.unmodifiable(_records);

  String get styleTitle {
    if (_ageGroup == StudentAgeGroup.child && _gender == StudentGender.female) {
      return 'Princess Story World';
    }
    if (_ageGroup == StudentAgeGroup.child && _gender == StudentGender.male) {
      return 'Adventure Blue Story World';
    }
    if (_gender == StudentGender.female) {
      return 'Glow Quest Story World';
    }
    return 'Quest Mode Story World';
  }

  String get styleHint {
    if (_ageGroup == StudentAgeGroup.child && _gender == StudentGender.female) {
      return 'Kind princess energy, brave choices, and sparkling wins.';
    }
    if (_ageGroup == StudentAgeGroup.child && _gender == StudentGender.male) {
      return 'Bright blue adventure vibes with teamwork and fun choices.';
    }
    if (_gender == StudentGender.female) {
      return 'Warm, confident storytelling with bright magical style.';
    }
    return 'Friendly, game-like storytelling with bold blue energy.';
  }

  int get level => (_xp ~/ 12) + 1;

  double get levelProgress => ((_xp % 12) / 12).clamp(0, 1);

  bool isUnlocked(WorldLocation location) => _stars >= location.unlockStars;

  int chapterFor(String locationId) => _chapterByLocation[locationId] ?? 1;

  String? lastChoiceFor(String locationId) => _lastChoiceByLocation[locationId];

  List<StoryAnswerRecord> recordsFor(String locationId) {
    return _records
        .where((record) => record.locationId == locationId)
        .toList(growable: false);
  }

  List<StoryAnswerRecord> get recentRecordsForSelected {
    final items = recordsFor(_selectedLocationId);
    final start = max(0, items.length - 6);
    return items.sublist(start);
  }

  String get favoriteLocationLabel {
    if (_records.isEmpty) {
      return 'Just getting started';
    }
    final counts = <String, int>{};
    for (final record in _records) {
      counts.update(
        record.locationName,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  List<String> get safeSignals {
    final combined = _records
        .map((record) => record.answer.toLowerCase())
        .join(' ');
    final signals = <String>[];
    if (_containsAny(combined, ['help', 'together', 'share', 'friend'])) {
      signals.add('Teamwork');
    }
    if (_containsAny(combined, ['try', 'ask', 'join', 'speak', 'tell'])) {
      signals.add('Brave steps');
    }
    if (_containsAny(combined, ['plan', 'idea', 'solve', 'organize'])) {
      signals.add('Problem solving');
    }
    if (_containsAny(combined, ['calm', 'breathe', 'pause', 'rest'])) {
      signals.add('Self-regulation');
    }
    if (_containsAny(combined, ['kind', 'sorry', 'thank', 'include'])) {
      signals.add('Kindness');
    }
    if (signals.isEmpty) {
      signals.add('Exploring choices');
    }
    return signals;
  }

  List<String> get contextGraphLines {
    if (_records.isEmpty) {
      return const ['You → Home → Curious beginning'];
    }
    final items = _records.reversed.take(5).toList().reversed;
    return items
        .map(
          (record) =>
              'You → ${record.locationName} → ${record.mood.label} → ${record.memory}',
        )
        .toList(growable: false);
  }

  Future<void> load({
    required String baseUrl,
    StudentAgeGroup? hostAgeGroup,
    StudentGender? hostGender,
  }) async {
    _preferences = await SharedPreferences.getInstance();
    _restoreLocalState(hostAgeGroup: hostAgeGroup, hostGender: hostGender);
    final trimmedBaseUrl = baseUrl.trim();
    if (trimmedBaseUrl.isNotEmpty) {
      _api = GameApi(baseUrl: trimmedBaseUrl, playerKey: _playerKey);
      await _bootstrapRemote();
    }
    _isLoaded = true;
    notifyListeners();
    await selectLocation(_selectedLocationId, forceRefresh: true);
  }

  Future<void> selectLocation(
    String locationId, {
    bool forceRefresh = false,
  }) async {
    _selectedLocationId = locationId;
    notifyListeners();
    if (_sceneByLocation.containsKey(locationId) && !forceRefresh) {
      return;
    }
    final location = worldLocations.firstWhere(
      (item) => item.id == locationId,
      orElse: () => worldLocations.first,
    );
    await _loadScene(location, forceRefresh: forceRefresh);
  }

  Future<StoryTurnResult?> submitAnswer(String rawAnswer) async {
    final answer = rawAnswer.trim();
    if (answer.isEmpty) {
      return null;
    }
    final location = selectedLocation;
    final chapter = chapterFor(location.id);
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    String message;
    String memory;
    int xpEarned;
    int coinsEarned;
    int starsEarned;

    try {
      if (_api != null) {
        final remote = await _api!.submitChoice(
          locationId: location.id,
          answer: answer,
          expectedChapter: chapter,
        );
        _backendOnline = true;
        _applyRemoteState(remote['state'] as Map<String, dynamic>? ?? {});
        message =
            remote['message']?.toString() ?? _localMessage(location, answer);
        memory = remote['memory']?.toString() ?? _memoryFor(location, answer);
        xpEarned = _asInt(remote['xp_earned'], fallback: 2);
        coinsEarned = _asInt(remote['coins_earned'], fallback: 1);
        starsEarned = _asInt(remote['stars_earned'], fallback: 1);
      } else {
        throw const GameApiException('Offline mode');
      }
    } catch (_) {
      _backendOnline = false;
      xpEarned =
          2 +
          min(
            3,
            answer.split(' ').where((word) => word.isNotEmpty).length ~/ 6,
          );
      coinsEarned = 1 + (answer.length > 40 ? 1 : 0);
      starsEarned = answer.length > 55 ? 2 : 1;
      _xp += xpEarned;
      _coins += coinsEarned;
      _stars += starsEarned;
      _day += 1;
      _chapterByLocation[location.id] = chapter + 1;
      _lastChoiceByLocation[location.id] = answer;
      message = _localMessage(location, answer);
      memory = _memoryFor(location, answer);
    }

    final mood = _guessMood(answer);
    _selfReportedMood = mood;
    final record = StoryAnswerRecord(
      locationId: location.id,
      locationName: location.name,
      npcName: location.npc,
      answer: answer,
      response: message,
      memory: memory,
      chapter: chapter,
      mood: mood,
      createdAtIso: DateTime.now().toIso8601String(),
    );
    _records.add(record);
    await _persist();
    await _loadScene(location, forceRefresh: true);
    _isSubmitting = false;
    notifyListeners();
    return StoryTurnResult(
      record: record,
      scene: _sceneByLocation[location.id] ?? _fallbackScene(location),
    );
  }

  Future<void> _bootstrapRemote() async {
    if (_api == null) {
      return;
    }
    try {
      final state = await _api!.bootstrap(
        displayName: _playerName,
        ageYears: _ageYears,
      );
      _backendOnline = true;
      _applyRemoteState(state);
      await _persist();
    } catch (_) {
      _backendOnline = false;
    }
  }

  Future<void> _loadScene(
    WorldLocation location, {
    bool forceRefresh = false,
  }) async {
    if (_isLoadingScene && !forceRefresh) {
      return;
    }
    _isLoadingScene = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (_api != null) {
        final remote = await _api!.getScene(location.id);
        _backendOnline = true;
        _sceneByLocation[location.id] = StoryScene(
          chapter: _asInt(remote['chapter'], fallback: chapterFor(location.id)),
          title: remote['title']?.toString() ?? '${location.name} story',
          body: remote['body']?.toString() ?? _fallbackScene(location).body,
          prompt:
              remote['prompt']?.toString() ?? _fallbackScene(location).prompt,
        );
      } else {
        throw const GameApiException('Offline mode');
      }
    } catch (error) {
      _backendOnline = false;
      _sceneByLocation[location.id] = _fallbackScene(location);
      if (error is GameApiException && error.statusCode == 500) {
        _errorMessage =
            'Backend returned an internal error, so Story World switched to offline mode.';
      }
    } finally {
      _isLoadingScene = false;
      notifyListeners();
    }
  }

  StoryScene _fallbackScene(WorldLocation location) {
    final chapter = chapterFor(location.id);
    final stage = (chapter - 1) % 3;
    final lastChoice = lastChoiceFor(location.id);
    final worldFlavor = switch ((_ageGroup, _gender)) {
      (StudentAgeGroup.child, StudentGender.female) =>
        'a bright princess-style adventure with brave, kind choices',
      (StudentAgeGroup.child, StudentGender.male) =>
        'a playful blue quest world full of teamwork and fun',
      (_, StudentGender.female) => 'a warm, glowing story world',
      _ => 'a friendly blue adventure world',
    };
    final reminder = lastChoice == null
        ? ''
        : ' ${location.npc} still remembers that last time you chose to ${_lowerFirst(lastChoice)}.';
    final beats = _sceneBeats[location.id] ?? _sceneBeats['home']!;
    final beat = beats[stage];
    return StoryScene(
      chapter: chapter,
      title: '${location.name} • Chapter $chapter',
      body:
          'You step into ${location.name.toLowerCase()}, a place inside $worldFlavor. '
          '${location.npc} waves and says, "${beat['setup']}"$reminder',
      prompt: beat['prompt']!,
    );
  }

  String _localMessage(WorldLocation location, String answer) {
    final stage = ((chapterFor(location.id) - 1) % 3) + 1;
    final beginning = switch (_guessMood(answer)) {
      PlayerMood.joyful => '${location.npc} grins. ',
      PlayerMood.calm => '${location.npc} nods slowly. ',
      PlayerMood.curious => '${location.npc} leans in. ',
      PlayerMood.proud => '${location.npc} beams. ',
      PlayerMood.nervous => '${location.npc} speaks gently. ',
      PlayerMood.frustrated => '${location.npc} takes a breath with you. ',
    };
    final ending = switch (stage) {
      1 => 'That helps the day begin in a better way.',
      2 => 'Now the next part of the story can open up.',
      _ => 'That choice changes what happens next in your world.',
    };
    return '$beginning'
        'You decide to ${_lowerFirst(answer)}, and the moment softens a little. '
        '$ending';
  }

  String _memoryFor(WorldLocation location, String answer) {
    return '${location.npc} remembers that you chose to ${_lowerFirst(answer)}.';
  }

  PlayerMood _guessMood(String answer) {
    final text = answer.toLowerCase();
    if (_containsAny(text, ['happy', 'yay', 'fun', 'great', 'awesome'])) {
      return PlayerMood.joyful;
    }
    if (_containsAny(text, ['calm', 'breathe', 'pause', 'rest', 'quiet'])) {
      return PlayerMood.calm;
    }
    if (_containsAny(text, ['nervous', 'worried', 'scared', 'shy'])) {
      return PlayerMood.nervous;
    }
    if (_containsAny(text, [
      'angry',
      'mad',
      'annoyed',
      'upset',
      'frustrated',
    ])) {
      return PlayerMood.frustrated;
    }
    if (_containsAny(text, ['proud', 'did it', 'finished', 'won'])) {
      return PlayerMood.proud;
    }
    return PlayerMood.curious;
  }

  void _applyRemoteState(Map<String, dynamic> state) {
    _playerName = state['display_name']?.toString() ?? _playerName;
    _ageYears = _asInt(state['age_years'], fallback: _ageYears);
    _xp = _asInt(state['xp'], fallback: _xp);
    _coins = _asInt(state['coins'], fallback: _coins);
    _stars = _asInt(state['stars'], fallback: _stars);
    _day = _asInt(state['current_day'], fallback: _day);
    final locations = state['locations'];
    if (locations is List) {
      for (final item in locations.whereType<Map<String, dynamic>>()) {
        final id = item['location_id']?.toString();
        if (id == null || id.isEmpty) {
          continue;
        }
        _chapterByLocation[id] = _asInt(item['chapter'], fallback: 1);
        final lastChoice = item['last_choice']?.toString();
        if (lastChoice != null && lastChoice.isNotEmpty) {
          _lastChoiceByLocation[id] = lastChoice;
        }
      }
    }
  }

  void _restoreLocalState({
    StudentAgeGroup? hostAgeGroup,
    StudentGender? hostGender,
  }) {
    final prefs = _preferences;
    _ageGroup = hostAgeGroup ?? _ageGroup;
    _gender = hostGender ?? _gender;
    _ageYears = _defaultAgeYears(_ageGroup);
    _playerKey = prefs?.getString(_playerKeyStorageKey) ?? _generatePlayerKey();
    final raw = prefs?.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    _playerName = decoded['playerName']?.toString() ?? _playerName;
    _xp = _asInt(decoded['xp'], fallback: _xp);
    _coins = _asInt(decoded['coins'], fallback: _coins);
    _stars = _asInt(decoded['stars'], fallback: _stars);
    _day = _asInt(decoded['day'], fallback: _day);
    _selectedLocationId =
        decoded['selectedLocationId']?.toString() ?? _selectedLocationId;
    _selfReportedMood = PlayerMood.values.firstWhere(
      (item) => item.name == decoded['mood'],
      orElse: () => _selfReportedMood,
    );
    final chapters = decoded['chapters'];
    if (chapters is Map<String, dynamic>) {
      for (final entry in chapters.entries) {
        _chapterByLocation[entry.key] = _asInt(entry.value, fallback: 1);
      }
    }
    final lastChoices = decoded['lastChoices'];
    if (lastChoices is Map<String, dynamic>) {
      for (final entry in lastChoices.entries) {
        final value = entry.value?.toString();
        if (value != null && value.isNotEmpty) {
          _lastChoiceByLocation[entry.key] = value;
        }
      }
    }
    final records = decoded['records'];
    if (records is List) {
      _records
        ..clear()
        ..addAll(
          records
              .map(StoryAnswerRecord.fromJson)
              .whereType<StoryAnswerRecord>(),
        );
    }
  }

  Future<void> _persist() async {
    await _preferences?.setString(_playerKeyStorageKey, _playerKey);
    final encoded = jsonEncode({
      'playerName': _playerName,
      'xp': _xp,
      'coins': _coins,
      'stars': _stars,
      'day': _day,
      'mood': _selfReportedMood.name,
      'selectedLocationId': _selectedLocationId,
      'chapters': _chapterByLocation,
      'lastChoices': _lastChoiceByLocation,
      'records': _records.map((item) => item.toJson()).toList(),
    });
    await _preferences?.setString(_storageKey, encoded);
  }

  @override
  void dispose() {
    _api?.close();
    super.dispose();
  }
}

int _defaultAgeYears(StudentAgeGroup ageGroup) => switch (ageGroup) {
  StudentAgeGroup.child => 10,
  StudentAgeGroup.teen => 14,
  StudentAgeGroup.youngAdult => 17,
};

int _asInt(Object? value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _containsAny(String text, List<String> patterns) {
  return patterns.any(text.contains);
}

String _lowerFirst(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }
  return trimmed[0].toLowerCase() + trimmed.substring(1);
}

String _generatePlayerKey() {
  const alphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random.secure();
  return List.generate(
    32,
    (_) => alphabet[random.nextInt(alphabet.length)],
  ).join();
}

const _sceneBeats = <String, List<Map<String, String>>>{
  'home': [
    {
      'setup':
          'A tiny home problem popped up, and everyone is looking your way.',
      'prompt': 'What would you say or do first?',
    },
    {
      'setup': 'The first idea helped a bit, but now someone feels left out.',
      'prompt': 'How do you keep things kind and fair?',
    },
    {
      'setup':
          'The home challenge is almost solved, but one last choice matters.',
      'prompt': 'What is your final move?',
    },
  ],
  'school': [
    {
      'setup': 'A school task feels tricky, and your team needs a calm plan.',
      'prompt': 'What would you do or say?',
    },
    {
      'setup': 'Your idea got everyone moving, but now the clock is ticking.',
      'prompt': 'How do you keep the group focused?',
    },
    {
      'setup': 'The class is ready to present, and confidence matters most.',
      'prompt': 'What do you do next?',
    },
  ],
  'forest': [
    {
      'setup':
          'A friendship moment got awkward, and no one knows how to start again.',
      'prompt': 'How do you open the conversation?',
    },
    {
      'setup':
          'The group is listening now, but different ideas are bumping into each other.',
      'prompt': 'How do you help everyone feel included?',
    },
    {
      'setup':
          'You can feel the friendship getting stronger, if you choose wisely.',
      'prompt': 'What do you do?',
    },
  ],
  'castle': [
    {
      'setup': 'A brave moment is waiting, and your voice could help.',
      'prompt': 'What do you say or do?',
    },
    {
      'setup': 'You started strong, but now you need one more confident step.',
      'prompt': 'How do you keep going?',
    },
    {
      'setup': 'The castle crowd is watching with hopeful eyes.',
      'prompt': 'What is your bold final move?',
    },
  ],
  'park': [
    {
      'setup': 'Everyone wants to play, but nobody agrees on the game.',
      'prompt': 'How do you get the fun started?',
    },
    {
      'setup':
          'The game began, but somebody feels they are not getting a turn.',
      'prompt': 'What would you do?',
    },
    {
      'setup':
          'The park is buzzing and you can turn the day into a great memory.',
      'prompt': 'How do you finish the moment?',
    },
  ],
  'beach': [
    {
      'setup':
          'A big feeling rolls in like a wave, and you need a calm choice.',
      'prompt': 'What helps first?',
    },
    {
      'setup': 'You are steadier now, but one thought is still bothering you.',
      'prompt': 'What do you tell yourself or someone else?',
    },
    {
      'setup':
          'The beach is peaceful again, and you can choose how to carry that calm with you.',
      'prompt': 'What do you do next?',
    },
  ],
};
