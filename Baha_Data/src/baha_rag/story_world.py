from __future__ import annotations

from dataclasses import dataclass
import re


TOTAL_STORY_WORLD_CHAPTERS = 4


@dataclass(frozen=True)
class StoryWorldLocationDefinition:
    location_id: str
    display_name: str
    subtitle: str
    npc_id: str
    npc_name: str
    unlock_stars: int


@dataclass(frozen=True)
class StoryBeat:
    title: str
    body: str
    prompt: str


STORY_WORLD_LOCATIONS = {
    item.location_id: item
    for item in (
        StoryWorldLocationDefinition(
            "home",
            "Home",
            "Family moments, daily routines, and small choices.",
            "ria",
            "Ria",
            0,
        ),
        StoryWorldLocationDefinition(
            "school",
            "School",
            "Class, teamwork, and learning one step at a time.",
            "maya",
            "Maya",
            0,
        ),
        StoryWorldLocationDefinition(
            "forest",
            "Friends",
            "Play, friendship, and finding kind ways forward.",
            "niko",
            "Niko",
            0,
        ),
        StoryWorldLocationDefinition(
            "castle",
            "Confidence",
            "Brave choices, speaking up, and believing in yourself.",
            "coach_lina",
            "Coach Lina",
            8,
        ),
        StoryWorldLocationDefinition(
            "park",
            "Fun",
            "Games, laughter, and trying new ideas together.",
            "zoya",
            "Zoya",
            12,
        ),
        StoryWorldLocationDefinition(
            "beach",
            "Calm",
            "Feelings, reset moments, and peaceful pauses.",
            "ollie",
            "Ollie",
            16,
        ),
    )
}


LOCATION_BEATS = {
    "home": (
        StoryBeat(
            "The Mysterious Backpack",
            "A tiny golden key tumbles from your backpack. Ria thinks it opens something nearby, but your room is still a wonderful mess.",
            "What do you do next?",
        ),
        StoryBeat(
            "The Hidden Door of Pillows",
            "Behind the pile of blankets, the key clicks open a tiny moon-painted door. Warm light spills out, and a whisper says the first starlight shard is close.",
            "What do you do inside the secret room?",
        ),
        StoryBeat(
            "The Clockwork Attic",
            "Up in the attic, clock-birds flap around a locked chest while the floor hums like a music box. Ria thinks one of the birds is guarding the next clue on purpose.",
            "How do you handle the attic challenge?",
        ),
        StoryBeat(
            "The Starlight Hearth",
            "Back downstairs, the fireplace glimmers with constellations that match your map. One last turn of the key could wake the whole room and reveal what the shard is for.",
            "What do you do to complete the home quest?",
        ),
    ),
    "school": (
        StoryBeat(
            "The Wobbly Volcano",
            "Maya's science-fair volcano has cracked ten minutes before judging. The baking-soda lava is leaking onto a poster full of careful notes.",
            "What do you do next?",
        ),
        StoryBeat(
            "The Hallway Supply Sprint",
            "Your first move helps, but now the class needs one missing ingredient from the prep room. A rival team rushes past, and the judging bell rings once.",
            "What is your next move?",
        ),
        StoryBeat(
            "The Judge's Surprise Question",
            "The volcano stands again, but a judge asks Maya and you what failed and how you adapted. Maya looks to you, ready but nervous.",
            "How do you answer or help in the moment?",
        ),
        StoryBeat(
            "The Blue Foam Finale",
            "The repaired volcano suddenly starts glowing brighter than anyone expected, and the crowd gathers close. Now your team can turn the mistake into the best part of the demonstration.",
            "What do you do to finish the science-fair quest?",
        ),
    ),
    "forest": (
        StoryBeat(
            "The Whispering Bridge",
            "Niko is new to the forest club. At the rope bridge, everyone rushes ahead while silver leaves spin in the wind.",
            "What do you do next?",
        ),
        StoryBeat(
            "The Lantern Trail",
            "Across the bridge, a row of lantern flowers only glows when the group moves together. Niko notices a pattern that nobody else has spotted yet.",
            "How do you guide the group now?",
        ),
        StoryBeat(
            "The Foxglove Riddle",
            "A carved stone fox asks for a team answer before it opens the path to the treehouse observatory. Everyone starts talking at once.",
            "What do you do to move the quest forward?",
        ),
        StoryBeat(
            "The Silver Nest Ceremony",
            "The hidden nest of silver birds has been found, but the birds will only trust one explorer to speak for the group. Niko nudges your sleeve and smiles.",
            "What do you do to complete the forest quest?",
        ),
    ),
    "castle": (
        StoryBeat(
            "The Festival Speech",
            "Coach Lina asks you to help open the confidence festival because the main speaker has lost their voice. The courtyard is full, and your tummy feels fluttery.",
            "What do you do next?",
        ),
        StoryBeat(
            "The Echo Hall Rehearsal",
            "A mentor leads you into the echo hall where every brave word returns twice as strong. The musicians are waiting for a signal to begin.",
            "How do you prepare or act now?",
        ),
        StoryBeat(
            "The Banner of Courage",
            "Just before the speech, the festival banner slips loose and everyone gasps. The crowd is restless, and this could either become chaos or the perfect opening.",
            "What do you do in this moment?",
        ),
        StoryBeat(
            "The Crownlight Finale",
            "The speech is almost complete when the crownlight crystal above the courtyard flickers on and off. One final act of courage could turn the whole festival legendary.",
            "What do you do to finish the confidence quest?",
        ),
    ),
    "park": (
        StoryBeat(
            "The One-Rope Game",
            "There is one skipping rope and six players. Zoya says only the fastest children should get a turn.",
            "What do you do next?",
        ),
        StoryBeat(
            "The Chalk Circle Challenge",
            "A park helper rolls out chalk, cones, and beanbags, and suddenly the game could become something much bigger. The group waits to see whose idea takes the lead.",
            "How do you move the game forward?",
        ),
        StoryBeat(
            "The Team Captain Mix-Up",
            "Two children both want to lead, and everyone starts choosing sides. The music from the bandstand is already counting down to the next round.",
            "What do you do now?",
        ),
        StoryBeat(
            "The Rainbow Relay Finale",
            "Your game is nearly ready, and children from the next playground over want to join too. This could become the biggest team game the park has ever seen.",
            "What do you do to finish the park quest?",
        ),
    ),
    "beach": (
        StoryBeat(
            "The Moon-Shell Trail",
            "Ollie cannot find the shell their grandparent gave them. The tide is coming in, and footprints blur at the water's edge.",
            "What do you do next?",
        ),
        StoryBeat(
            "The Sand-Map Clue",
            "A tiny crab drags a line through the sand that almost looks like a map. Ollie notices three places where the moonlight glints brighter than the rest.",
            "Where do you lead the search now?",
        ),
        StoryBeat(
            "The Tidal Cave Echo",
            "The trail leads to a small sea cave where every sound echoes back with a watery shimmer. Something inside twinkles, but the waves are getting stronger.",
            "What do you do in this moment?",
        ),
        StoryBeat(
            "The Moon-Shell Return",
            "You are close enough to see a silver gleam under the foam, but one wrong move could send it drifting farther away. Ollie trusts your lead completely now.",
            "What do you do to finish the calm quest?",
        ),
    ),
}


def story_world_theme_variant(age_cohort: str | None) -> str:
    if age_cohort == "9_12":
        return "guided_adventure"
    if age_cohort == "13_14":
        return "social_confidence"
    return "grounded_growth"


def scene_for(
    *,
    location_id: str,
    chapter: int,
    remembered: bool,
    last_choice: str | None = None,
    completed: bool = False,
) -> dict[str, object]:
    location = STORY_WORLD_LOCATIONS[location_id]
    beat = LOCATION_BEATS[location_id][max(0, min(chapter, TOTAL_STORY_WORLD_CHAPTERS) - 1)]
    memory_line = (
        f'{location.npc_name} smiles. "I remember how you helped before." '
        if remembered
        else ""
    )
    continuation_line = (
        f'Last time, you chose: "{last_choice}". '
        if last_choice
        else ""
    )
    completion_line = (
        "You have already completed this world once, so now you can revisit it with more confidence. "
        if completed
        else ""
    )
    title = beat.title if chapter <= 1 else f"{beat.title} · Chapter {chapter}"
    prompt = (
        "You can keep exploring here or switch to another world whenever you want."
        if completed and chapter >= TOTAL_STORY_WORLD_CHAPTERS
        else beat.prompt
    )
    return {
        "location_id": location_id,
        "chapter": chapter,
        "title": title,
        "body": f"{completion_line}{memory_line}{continuation_line}{beat.body}".strip(),
        "prompt": prompt,
        "npc_id": location.npc_id,
        "npc_name": location.npc_name,
    }


def observed_signals(answer: str) -> list[str]:
    normalized = answer.lower()
    rules = {
        "communication": ("ask", "listen", "feel", "say", "talk"),
        "cooperation": ("help", "together", "friend", "team", "share"),
        "self_regulation": ("breathe", "pause", "calm", "slow", "steady"),
        "persistence": ("try", "practice", "plan", "again", "keep going"),
        "kindness": ("kind", "cheer", "beside", "include", "comfort"),
        "help_seeking": ("teacher", "adult", "ask for help", "counselor"),
    }
    signals = [
        signal
        for signal, terms in rules.items()
        if any(term in normalized for term in terms)
    ]
    return signals or ["decision_making", "curiosity"]


def consequence_for(location_id: str, answer: str, chapter: int) -> str:
    action = answer.strip().rstrip(".")
    beat_index = (max(chapter, 1) - 1) % TOTAL_STORY_WORLD_CHAPTERS
    style = _action_style(answer)
    stage_openers = (
        "Your first move lands immediately.",
        "The quest grows bigger because of what you do next.",
        "That choice changes the turning point of the adventure.",
        "The ending starts to bend in your favor.",
    )
    location_payoffs = {
        "home": (
            "Ria lights up as the map reveals another hidden symbol under the floorboards.",
            "The tiny moon-painted door unlocks a room full of glowing cushions and clue-jars.",
            "One clock-bird bows to you and drops a silver cog into your hand.",
            "The hearth flares with starlight and the whole house seems to cheer.",
        ),
        "school": (
            "Maya straightens up, and the volcano team finally has a clear first step.",
            "A supply run turns into a perfect save just before the judging bell rings again.",
            "The judge leans in, impressed that your team turned a mistake into an experiment.",
            "Bright blue foam spirals upward, and the whole class bursts into applause.",
        ),
        "forest": (
            "Niko relaxes enough to notice clues everyone else missed.",
            "The lantern flowers begin glowing in a path only a real team could open.",
            "The stone fox listens, then slides aside with a mossy grin.",
            "The silver birds swoop low in a sparkling circle of welcome.",
        ),
        "castle": (
            "Coach Lina nods as the courtyard energy steadies around your brave choice.",
            "The echo hall turns your courage into something bigger than your own voice.",
            "The loose banner becomes the perfect opening for a brave surprise.",
            "The crownlight crystal blazes on, and the whole festival feels legendary.",
        ),
        "park": (
            "The group pauses, then starts building around your idea instead of arguing over turns.",
            "Chalk circles and beanbags turn the rope game into a real team challenge.",
            "The children stop choosing sides and start choosing roles.",
            "The park erupts into the biggest laugh-filled relay of the day.",
        ),
        "beach": (
            "Ollie exhales, and the search becomes sharper instead of wilder.",
            "The sand-map clue suddenly makes sense once everyone slows down to follow it.",
            "The cave echoes back your plan like the sea agrees with you.",
            "A silver glimmer surfaces in the foam exactly where you hoped it would.",
        ),
    }
    style_lines = {
        "brave": f'You step in with a bold idea, "{action}," and everyone feels the quest lurch forward.',
        "clever": f'Your clever plan, "{action}," uncovers a solution nobody else had noticed.',
        "kind": f'Your kind move, "{action}," changes the mood before it changes the path.',
        "calm": f'Your calm choice, "{action}," steadies the whole scene and opens the next clue.',
        "creative": f'Your unexpected idea, "{action}," makes the adventure more magical at once.',
        "steady": f'Your choice, "{action}," gives the adventure a clear direction.',
    }
    return " ".join(
        [
            stage_openers[beat_index],
            style_lines[style],
            location_payoffs[location_id][beat_index],
        ]
    )


def _action_style(answer: str) -> str:
    normalized = re.sub(r"\s+", " ", answer.lower())
    if any(term in normalized for term in ("brave", "stand", "speak", "lead", "protect")):
        return "brave"
    if any(term in normalized for term in ("plan", "build", "invent", "figure", "solve")):
        return "clever"
    if any(term in normalized for term in ("help", "kind", "include", "hug", "listen", "comfort")):
        return "kind"
    if any(term in normalized for term in ("breathe", "pause", "calm", "slow", "steady")):
        return "calm"
    if any(term in normalized for term in ("pretend", "draw", "sing", "dance", "magic", "funny")):
        return "creative"
    return "steady"
