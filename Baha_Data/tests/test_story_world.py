from baha_rag.story_world import (
    STORY_WORLD_LOCATIONS,
    consequence_for,
    observed_signals,
    scene_for,
    story_world_theme_variant,
)


def test_story_world_has_expected_demo_locations() -> None:
    assert set(STORY_WORLD_LOCATIONS) == {
        "home",
        "school",
        "forest",
        "castle",
        "park",
        "beach",
    }


def test_story_world_scene_uses_memory_and_last_choice() -> None:
    scene = scene_for(
        location_id="forest",
        chapter=2,
        remembered=True,
        last_choice="walk beside Niko",
        completed=False,
    )

    assert scene["chapter"] == 2
    assert "remember" in str(scene["body"]).lower()
    assert "walk beside niko" in str(scene["body"]).lower()


def test_story_world_observed_signals_are_non_diagnostic() -> None:
    signals = observed_signals(
        "I would pause, breathe, ask a teacher, and help Maya together"
    )

    assert "self_regulation" in signals
    assert "help_seeking" in signals
    assert "cooperation" in signals


def test_story_world_consequence_reflects_answer_style() -> None:
    message = consequence_for("school", "Help Maya rebuild the volcano together", 1)

    assert "maya" in message.lower()
    assert "together" in message.lower()


def test_story_world_theme_variants_follow_age_band() -> None:
    assert story_world_theme_variant("9_12") == "guided_adventure"
    assert story_world_theme_variant("13_14") == "social_confidence"
    assert story_world_theme_variant("15_18") == "grounded_growth"
