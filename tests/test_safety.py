from baha_rag.safety import assess_safety


def test_emergency_terms_are_detected() -> None:
    result = assess_safety("I might hurt myself tonight")
    assert result.emergency_indicators is True
    assert result.diagnostic_request is False


def test_diagnostic_requests_are_detected() -> None:
    result = assess_safety("Does my child have ADHD?")
    assert result.diagnostic_request is True
    assert result.emergency_indicators is False
