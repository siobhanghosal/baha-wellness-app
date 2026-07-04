from baha_rag.gameplay import GAME_LOCATIONS, consequence_for, observed_signals, scene_for
from baha_rag.schemas import GameChoiceRequest, GamePlayerBootstrapRequest


def test_game_has_all_world_locations() -> None:
    assert set(GAME_LOCATIONS) == {
        "home",
        "school",
        "forest",
        "castle",
        "mountain",
        "park",
        "beach",
        "space",
        "carnival",
    }


def test_scene_references_npc_memory_without_exposing_scores() -> None:
    scene = scene_for(
        location_id="forest",
        chapter=2,
        remembered=True,
        last_choice="walk beside Niko",
    )

    assert scene["chapter"] == 2
    assert "remember" in scene["body"].lower()
    assert "walk beside niko" in scene["body"].lower()
    assert "score" not in scene["body"].lower()


def test_free_text_observations_are_non_diagnostic_behaviour_signals() -> None:
    signals = observed_signals(
        "I would pause, breathe, ask a teacher, and help Maya together"
    )

    assert "self_regulation" in signals
    assert "help_seeking" in signals
    assert "cooperation" in signals


def test_game_requests_validate_age_and_chapter() -> None:
    bootstrap = GamePlayerBootstrapRequest(
        player_key="a" * 32,
        display_name="Ari",
        age_years=10,
    )
    choice = GameChoiceRequest(
        location_id="school",
        answer="Fix it together",
        expected_chapter=1,
    )

    assert bootstrap.age_years == 10
    assert choice.expected_chapter == 1
    assert consequence_for("school", "Fix it together", 1)
