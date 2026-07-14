from baha_rag.acquisition.campaign import (
    AHA,
    classify_resource,
    is_campaign_relevant,
    is_restricted_url,
    source_weight,
)


def test_campaign_weights_match_required_order() -> None:
    assert source_weight("Bangalore Adolescent Health Academy") == 1.00
    assert source_weight(AHA) == 0.95
    assert source_weight("NIMHANS") == 0.90
    assert source_weight("WHO") == 0.85
    assert source_weight("UNICEF") == 0.80
    assert source_weight("PubMed") == 0.75


def test_campaign_blocks_login_and_member_routes() -> None:
    assert is_restricted_url("https://aha.iapindia.org/member-login.php")
    assert is_restricted_url("https://example.org/admin/resources")
    assert not is_restricted_url("https://aha.iapindia.org/knowledge-bank/")


def test_campaign_classifies_teacher_resource() -> None:
    audience, resource_class = classify_resource("AHA Module for Teachers")
    assert audience == "teacher"
    assert resource_class == "Teacher Resource"


def test_campaign_recognizes_aha_target_area() -> None:
    assert is_campaign_relevant("AHA Webinar PPTs", AHA)
