class StoryWorldLocationState {
  const StoryWorldLocationState({
    required this.locationId,
    required this.displayName,
    required this.subtitle,
    required this.npcId,
    required this.npcName,
    required this.unlockStars,
    required this.chapter,
    required this.unlocked,
    required this.completed,
    required this.progressPercent,
    required this.sessionStatus,
    this.lastChoice,
  });

  final String locationId;
  final String displayName;
  final String subtitle;
  final String npcId;
  final String npcName;
  final int unlockStars;
  final int chapter;
  final String? lastChoice;
  final bool unlocked;
  final bool completed;
  final double progressPercent;
  final String sessionStatus;

  factory StoryWorldLocationState.fromJson(Map<String, dynamic> json) {
    return StoryWorldLocationState(
      locationId: json['location_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      npcId: json['npc_id'] as String? ?? '',
      npcName: json['npc_name'] as String? ?? '',
      unlockStars: (json['unlock_stars'] as num?)?.toInt() ?? 0,
      chapter: (json['chapter'] as num?)?.toInt() ?? 1,
      lastChoice: json['last_choice'] as String?,
      unlocked: json['unlocked'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
      sessionStatus: json['session_status'] as String? ?? 'started',
    );
  }
}

class StoryWorldNpcState {
  const StoryWorldNpcState({
    required this.npcId,
    required this.npcName,
    required this.friendshipLevel,
    required this.currentMood,
    required this.memories,
  });

  final String npcId;
  final String npcName;
  final int friendshipLevel;
  final String currentMood;
  final List<String> memories;

  factory StoryWorldNpcState.fromJson(Map<String, dynamic> json) {
    return StoryWorldNpcState(
      npcId: json['npc_id'] as String? ?? '',
      npcName: json['npc_name'] as String? ?? '',
      friendshipLevel: (json['friendship_level'] as num?)?.toInt() ?? 0,
      currentMood: json['current_mood'] as String? ?? 'curious',
      memories: (json['memories'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
    );
  }
}

class StoryWorldState {
  const StoryWorldState({
    required this.studentProfileId,
    required this.displayName,
    required this.themeVariant,
    required this.petName,
    required this.xp,
    required this.coins,
    required this.stars,
    required this.currentDay,
    required this.currentLocationId,
    required this.completedQuestCount,
    required this.locations,
    required this.npcs,
    this.ageCohort,
  });

  final String studentProfileId;
  final String displayName;
  final String? ageCohort;
  final String themeVariant;
  final String petName;
  final int xp;
  final int coins;
  final int stars;
  final int currentDay;
  final String currentLocationId;
  final int completedQuestCount;
  final List<StoryWorldLocationState> locations;
  final List<StoryWorldNpcState> npcs;

  factory StoryWorldState.fromJson(Map<String, dynamic> json) {
    return StoryWorldState(
      studentProfileId: json['student_profile_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      ageCohort: json['age_cohort'] as String?,
      themeVariant: json['theme_variant'] as String? ?? 'guided_adventure',
      petName: json['pet_name'] as String? ?? 'Comet',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      currentDay: (json['current_day'] as num?)?.toInt() ?? 1,
      currentLocationId: json['current_location_id'] as String? ?? '',
      completedQuestCount:
          (json['completed_quest_count'] as num?)?.toInt() ?? 0,
      locations: (json['locations'] as List<dynamic>? ?? const [])
          .map(
            (value) => StoryWorldLocationState.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(),
      npcs: (json['npcs'] as List<dynamic>? ?? const [])
          .map(
            (value) => StoryWorldNpcState.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(),
    );
  }
}

class StoryWorldScene {
  const StoryWorldScene({
    required this.locationId,
    required this.chapter,
    required this.title,
    required this.body,
    required this.prompt,
    required this.npcId,
    required this.npcName,
  });

  final String locationId;
  final int chapter;
  final String title;
  final String body;
  final String prompt;
  final String npcId;
  final String npcName;

  factory StoryWorldScene.fromJson(Map<String, dynamic> json) {
    return StoryWorldScene(
      locationId: json['location_id'] as String? ?? '',
      chapter: (json['chapter'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      npcId: json['npc_id'] as String? ?? '',
      npcName: json['npc_name'] as String? ?? '',
    );
  }
}

class StoryWorldTurnRequest {
  const StoryWorldTurnRequest({
    required this.locationId,
    required this.answer,
    required this.expectedChapter,
  });

  final String locationId;
  final String answer;
  final int expectedChapter;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'location_id': locationId,
      'answer': answer,
      'expected_chapter': expectedChapter,
    };
  }
}

class StoryWorldTurnResponse {
  const StoryWorldTurnResponse({
    required this.state,
    required this.scene,
    required this.message,
    required this.memory,
    required this.xpEarned,
    required this.coinsEarned,
    required this.starsEarned,
    required this.observedSignals,
  });

  final StoryWorldState state;
  final StoryWorldScene scene;
  final String message;
  final String memory;
  final int xpEarned;
  final int coinsEarned;
  final int starsEarned;
  final List<String> observedSignals;

  factory StoryWorldTurnResponse.fromJson(Map<String, dynamic> json) {
    return StoryWorldTurnResponse(
      state: StoryWorldState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map? ?? const {}),
      ),
      scene: StoryWorldScene.fromJson(
        Map<String, dynamic>.from(json['scene'] as Map? ?? const {}),
      ),
      message: json['message'] as String? ?? '',
      memory: json['memory'] as String? ?? '',
      xpEarned: (json['xp_earned'] as num?)?.toInt() ?? 0,
      coinsEarned: (json['coins_earned'] as num?)?.toInt() ?? 0,
      starsEarned: (json['stars_earned'] as num?)?.toInt() ?? 0,
      observedSignals: (json['observed_signals'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
    );
  }
}
