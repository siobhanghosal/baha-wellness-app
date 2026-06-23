from baha_rag.ingestion.sources import validate_source


def test_approved_source_requires_approved_domain_and_org() -> None:
    result = validate_source("https://www.who.int/health-topics/adolescent-health", "WHO")
    assert result.approved is True


def test_rejects_unapproved_domain() -> None:
    result = validate_source("https://example.com/advice", "WHO")
    assert result.approved is False


def test_life_skills_campaign_source_is_approved() -> None:
    result = validate_source("https://casel.org/resources-support/", "CASEL")
    assert result.approved is True
