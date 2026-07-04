from __future__ import annotations

from dataclasses import dataclass
import re


@dataclass(frozen=True)
class GameLocationDefinition:
    location_id: str
    npc_id: str
    display_name: str
    title: str
    body: str
    prompt: str
    evidence_query: str


@dataclass(frozen=True)
class StoryBeat:
    title: str
    body: str
    prompt: str


GAME_LOCATIONS = {
    item.location_id: item
    for item in (
        GameLocationDefinition(
            "home",
            "Pip",
            "Home",
            "The Mysterious Backpack",
            "A tiny golden key tumbles from your backpack. Pip thinks it opens "
            "something nearby, but your room is still a wonderful mess.",
            "What do you do next?",
            "children cooperation routines asking for help problem solving",
        ),
        GameLocationDefinition(
            "school",
            "Maya",
            "School",
            "The Wobbly Volcano",
            "Maya’s science-fair volcano has cracked ten minutes before judging. "
            "She looks worried and very quiet.",
            "What do you do next?",
            "children school teamwork help seeking confidence making mistakes",
        ),
        GameLocationDefinition(
            "forest",
            "Niko",
            "Friendship Forest",
            "The Whispering Bridge",
            "Niko is new to the forest club. At the rope bridge, everyone rushes "
            "ahead and Niko stays behind.",
            "What do you do next?",
            "children friendship inclusion empathy communication new student",
        ),
        GameLocationDefinition(
            "castle",
            "Queen Mira",
            "Castle of Courage",
            "The Festival Speech",
            "Queen Mira has lost her voice, and you know the welcome speech. The "
            "courtyard is full, and your tummy feels fluttery.",
            "What do you do next?",
            "children confidence public speaking calming help seeking",
        ),
        GameLocationDefinition(
            "mountain",
            "Ember",
            "Dragon Mountain",
            "Ember’s First Flight",
            "Ember wants to join the cloud parade, but one bumpy landing has made "
            "them afraid to try again.",
            "What do you do next?",
            "children persistence resilience growth mindset trying again",
        ),
        GameLocationDefinition(
            "park",
            "Zoya",
            "Rainbow Park",
            "The One-Rope Game",
            "There is one skipping rope and six players. Zoya says only the fastest "
            "children should get a turn.",
            "What do you do next?",
            "children sharing fairness teamwork cooperation listening",
        ),
        GameLocationDefinition(
            "beach",
            "Ollie",
            "Calm Beach",
            "The Moon-Shell Trail",
            "Ollie cannot find the shell their grandpa gave them. The tide is "
            "coming in, and Ollie’s thoughts are racing.",
            "What do you do next?",
            "children self regulation calming problem solving asking for help",
        ),
        GameLocationDefinition(
            "space",
            "Nova",
            "Space Station",
            "Signal of Kindness",
            "Nova finds a satellite sending mixed-up messages. One astronaut thinks "
            "another was unkind, but nobody knows the whole story.",
            "What do you do next?",
            "children digital safety communication conflict kindness teamwork",
        ),
        GameLocationDefinition(
            "carnival",
            "Tavi",
            "Carnival",
            "The Talent-Show Tangle",
            "Tavi’s juggling act went wrong in rehearsal. Some performers giggle, "
            "and Tavi says they might quit the show.",
            "What do you do next?",
            "children failure creativity resilience kindness growth mindset",
        ),
    )
}

LOCATION_BEATS = {
    "home": (
        StoryBeat(
            "The Mysterious Backpack",
            "The golden key now glows whenever it points toward a hidden clue. "
            "Pip spots glitter-dust under the bed and a folded map peeking from a sock drawer.",
            "What do you do next?",
        ),
        StoryBeat(
            "The Hidden Door of Pillows",
            "Behind the pile of blankets, the key clicks open a tiny moon-painted door. "
            "Warm light spills out, and a whisper says the first starlight shard is close.",
            "What do you do inside the secret room?",
        ),
        StoryBeat(
            "The Clockwork Attic",
            "Up in the attic, clock-birds flap around a locked chest while the floor hums like a music box. "
            "Pip thinks one of the birds is guarding the next clue on purpose.",
            "How do you handle the attic challenge?",
        ),
        StoryBeat(
            "The Starlight Hearth",
            "Back downstairs, the house fireplace glimmers with constellations that match your map. "
            "One last turn of the key could wake the whole room and reveal what the shard is for.",
            "What do you do to complete the home quest?",
        ),
    ),
    "school": (
        StoryBeat(
            "The Wobbly Volcano",
            "Maya’s science-fair volcano has cracked ten minutes before judging. "
            "The baking-soda lava is leaking onto a poster full of careful notes.",
            "What do you do next?",
        ),
        StoryBeat(
            "The Hallway Supply Sprint",
            "Your first move helps, but now the class needs one missing ingredient from the prep room. "
            "A rival team rushes past, and the judging bell rings once.",
            "What is your next move?",
        ),
        StoryBeat(
            "The Judge’s Surprise Question",
            "The volcano stands again, but a judge asks Maya and you what failed and how you adapted. "
            "Maya looks to you, ready but nervous.",
            "How do you answer or help in the moment?",
        ),
        StoryBeat(
            "The Blue Foam Finale",
            "The repaired volcano suddenly starts glowing brighter than anyone expected, and the crowd gathers close. "
            "Now your team can turn the mistake into the best part of the demonstration.",
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
            "Across the bridge, a row of lantern flowers only glows when the group moves together. "
            "Niko notices a pattern that nobody else has spotted yet.",
            "How do you guide the group now?",
        ),
        StoryBeat(
            "The Foxglove Riddle",
            "A carved stone fox asks for a team answer before it opens the path to the treehouse observatory. "
            "Everyone starts talking at once.",
            "What do you do to move the quest forward?",
        ),
        StoryBeat(
            "The Silver Nest Ceremony",
            "The hidden nest of silver birds has been found, but the birds will only trust one explorer to speak for the group. "
            "Niko nudges your sleeve and smiles.",
            "What do you do to complete the forest quest?",
        ),
    ),
    "castle": (
        StoryBeat(
            "The Festival Speech",
            "Queen Mira has lost her voice, and you know the welcome speech. "
            "Colorful banners snap in the wind above the crowded courtyard.",
            "What do you do next?",
        ),
        StoryBeat(
            "The Echo Hall Rehearsal",
            "A page leads you into the echo hall where every brave word returns twice as strong. "
            "The castle musicians are waiting for a signal to begin.",
            "How do you prepare or act now?",
        ),
        StoryBeat(
            "The Banner of Courage",
            "Just before the speech, the royal banner slips loose and everyone gasps. "
            "The crowd is restless, and this could either become chaos or the perfect opening.",
            "What do you do in this moment?",
        ),
        StoryBeat(
            "The Festival Crownlight",
            "The speech is almost complete when the crownlight crystal above the courtyard flickers on and off. "
            "One final act of courage could turn the whole festival legendary.",
            "What do you do to finish the castle quest?",
        ),
    ),
    "mountain": (
        StoryBeat(
            "Ember’s First Flight",
            "Ember wants to join the cloud parade, but one bumpy landing has made them afraid to try again. "
            "The practice ridge is lined with fluttering ribbons and cheering sprites.",
            "What do you do next?",
        ),
        StoryBeat(
            "The Wind-Step Lesson",
            "A gust sweeps across the ridge, revealing glowing hoofprints in the air. "
            "Ember thinks the wind itself might be showing a safe path.",
            "What is your next move?",
        ),
        StoryBeat(
            "The Parade Gate",
            "At the gate to the cloud parade, older dragons boast loudly while Ember goes quiet again. "
            "The horn will sound any second.",
            "How do you help the quest continue?",
        ),
        StoryBeat(
            "The Sky-Ribbon Dive",
            "The parade begins, and a ribbon of gold light curls through the clouds like a course made just for Ember. "
            "One last choice could turn a shaky try into a soaring triumph.",
            "What do you do to finish the mountain quest?",
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
            "A park helper rolls out chalk, cones, and beanbags, and suddenly the game could become something much bigger. "
            "The group waits to see whose idea takes the lead.",
            "How do you move the game forward?",
        ),
        StoryBeat(
            "The Team Captain Mix-Up",
            "Two children both want to lead, and everyone starts choosing sides. "
            "The music from the bandstand is already counting down to the next round.",
            "What do you do now?",
        ),
        StoryBeat(
            "The Rainbow Relay Finale",
            "Your game is nearly ready, and children from the next playground over want to join too. "
            "This could become the biggest team game Rainbow Park has ever seen.",
            "What do you do to finish the park quest?",
        ),
    ),
    "beach": (
        StoryBeat(
            "The Moon-Shell Trail",
            "Ollie cannot find the shell their grandpa gave them. The tide is coming in, and footprints blur at the water’s edge.",
            "What do you do next?",
        ),
        StoryBeat(
            "The Sand-Map Clue",
            "A tiny crab drags a line through the sand that almost looks like a map. "
            "Ollie notices three places where the moonlight glints brighter than the rest.",
            "Where do you lead the search now?",
        ),
        StoryBeat(
            "The Tidal Cave Echo",
            "The trail leads to a small sea cave where every sound echoes back with a watery shimmer. "
            "Something inside twinkles, but the waves are getting stronger.",
            "What do you do in this moment?",
        ),
        StoryBeat(
            "The Moon-Shell Return",
            "You are close enough to see a silver gleam under the foam, but one wrong move could send it drifting farther away. "
            "Ollie trusts your lead completely now.",
            "What do you do to finish the beach quest?",
        ),
    ),
    "space": (
        StoryBeat(
            "Signal of Kindness",
            "Nova finds a satellite sending mixed-up messages. One astronaut thinks another was unkind, but nobody knows the whole story.",
            "What do you do next?",
        ),
        StoryBeat(
            "The Orbit Archive",
            "Inside the satellite memory room, old messages sparkle like floating puzzle pieces. "
            "Some are missing, and one of them seems to have been scrambled on purpose.",
            "How do you investigate now?",
        ),
        StoryBeat(
            "The Comet Delay",
            "A passing comet shakes the station, and the crew has to fix the signal while keeping everyone calm. "
            "Nova looks to you for a plan.",
            "What do you do in this moment?",
        ),
        StoryBeat(
            "The Kindness Broadcast",
            "The repaired satellite is ready to send one clear message across the stars, and the whole crew can help choose how it starts. "
            "This is your chance to end the misunderstanding for good.",
            "What do you do to finish the space quest?",
        ),
    ),
    "carnival": (
        StoryBeat(
            "The Talent-Show Tangle",
            "Tavi’s juggling act went wrong in rehearsal. Some performers giggle, and the opening spotlight is only minutes away.",
            "What do you do next?",
        ),
        StoryBeat(
            "The Backstage Switcheroo",
            "Behind the curtain, costume ribbons, cards, drums, and lanterns are everywhere. "
            "Tavi suddenly thinks a new version of the act might work better.",
            "How do you help now?",
        ),
        StoryBeat(
            "The Spotlight Surprise",
            "The emcee calls Tavi’s name too early, and the crowd starts clapping before the act is ready. "
            "Backstage turns into a whirl of nerves and glitter.",
            "What do you do in this moment?",
        ),
        StoryBeat(
            "The Grand Carnival Bow",
            "The act is almost saved, and the audience is ready to cheer for something joyful, brave, and unexpected. "
            "One final choice can make the ending unforgettable.",
            "What do you do to finish the carnival quest?",
        ),
    ),
}


def scene_for(
    *,
    location_id: str,
    chapter: int,
    remembered: bool,
    last_choice: str | None = None,
) -> dict:
    location = GAME_LOCATIONS[location_id]
    beats = LOCATION_BEATS[location_id]
    beat = beats[(chapter - 1) % len(beats)]
    memory_line = (
        f'{location.npc_id} smiles. “I remember how you helped before!” '
        if remembered
        else ""
    )
    continuation_line = (
        f"Last time, you decided to {last_choice.lower()}. "
        if last_choice
        else ""
    )
    chapter_line = (
        f"This is chapter {chapter} of your {location.display_name.lower()} quest. "
        if chapter > 1
        else ""
    )
    return {
        "location_id": location_id,
        "chapter": chapter,
        "title": beat.title if chapter == 1 else f"{beat.title} · Chapter {chapter}",
        "body": chapter_line + memory_line + continuation_line + beat.body,
        "prompt": beat.prompt,
        "npc_id": location.npc_id,
    }


def observed_signals(answer: str) -> list[str]:
    normalized = answer.lower()
    rules = {
        "communication": ("ask", "listen", "feel", "say"),
        "cooperation": ("help", "together", "friend", "team"),
        "self_regulation": ("breathe", "pause", "calm", "slow"),
        "persistence": ("try", "practice", "plan", "again"),
        "kindness": ("kind", "cheer", "beside", "include"),
        "help_seeking": ("teacher", "adult", "ask for help"),
    }
    signals = [
        signal
        for signal, terms in rules.items()
        if any(term in normalized for term in terms)
    ]
    return signals or ["decision_making", "curiosity"]


def consequence_for(location_id: str, answer: str, chapter: int) -> str:
    action = answer.strip().rstrip(".")
    lowered_action = action.lower()
    beat_index = (chapter - 1) % len(LOCATION_BEATS[location_id])
    style = _action_style(answer)
    stage_openers = (
        "Your first move lands immediately.",
        "The quest grows bigger because of what you do next.",
        "That choice changes the turning point of the adventure.",
        "The ending starts to bend in your favor.",
    )
    location_payoffs = {
        "home": (
            "Pip yips happily as the map reveals another hidden symbol under the floorboards.",
            "The tiny moon-painted door unlocks a room full of glowing cushions and clue-jars.",
            "One clock-bird bows to you and drops a silver cog into your hand.",
            "The hearth flares with starlight and the house itself seems to cheer.",
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
            "Queen Mira’s eyes shine with relief as the courtyard energy steadies.",
            "The echo hall turns your courage into something bigger than your own voice.",
            "The loose banner becomes the perfect opening for a brave surprise.",
            "The crownlight crystal blazes on, and the whole festival feels legendary.",
        ),
        "mountain": (
            "Ember’s wings stop trembling long enough for hope to sneak back in.",
            "The wind-steps brighten, showing a safer path through the sky.",
            "The parade gate no longer feels like a wall; it feels like an invitation.",
            "Gold sky-ribbons curl around Ember in a burst of fearless flight.",
        ),
        "park": (
            "The group pauses, then starts building around your idea instead of arguing over turns.",
            "Chalk circles and beanbags turn the rope game into a real team challenge.",
            "The children stop choosing sides and start choosing roles.",
            "Rainbow Park erupts into the biggest laugh-filled relay of the day.",
        ),
        "beach": (
            "Ollie exhales, and the search becomes sharper instead of wilder.",
            "The sand-map clue suddenly makes sense once everyone slows down to follow it.",
            "The cave echoes back your plan like the sea agrees with you.",
            "A silver glimmer surfaces in the foam exactly where you hoped it would.",
        ),
        "space": (
            "Nova nods as the scrambled messages begin to look more like clues than mistakes.",
            "A missing piece of the orbit archive flickers back to life under your plan.",
            "The crew steadies as the comet shake turns into a teamwork test instead of a panic.",
            "The satellite powers up with a clear kindness broadcast ready to launch.",
        ),
        "carnival": (
            "Tavi’s shoulders lift as the act starts feeling possible again.",
            "Backstage clutter suddenly looks more like a treasure chest of new act ideas.",
            "The spotlight surprise turns from disaster into drama in the best way.",
            "The audience leans forward, ready to cheer for the bold ending you helped shape.",
        ),
    }
    style_lines = {
        "brave": f"You step in with a bold idea to {lowered_action}, and everyone feels the quest lurch forward.",
        "clever": f"Your clever plan to {lowered_action} uncovers a solution nobody else had noticed.",
        "kind": f"Your kind move to {lowered_action} changes the mood before it changes the path.",
        "calm": f"Your calm choice to {lowered_action} steadies the whole scene and opens the next clue.",
        "creative": f"Your unexpected idea to {lowered_action} makes the adventure more magical at once.",
        "steady": f"Your choice to {lowered_action} gives the adventure a clear direction.",
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
