from __future__ import annotations

from dataclasses import dataclass
from urllib.parse import urlparse


APPROVED_ORGANIZATIONS = {
    "BAHA",
    "Bangalore Adolescent Health Academy",
    "Indian Academy of Pediatrics",
    "NIMHANS",
    "NCERT",
    "CBSE",
    "Ministry of Health and Family Welfare",
    "National Mental Health Programme",
    "NIH",
    "NCPCR",
    "WHO",
    "UNESCO",
    "UNICEF",
    "CDC",
    "NIH",
    "NHS",
    "NICE",
    "American Academy of Pediatrics",
    "SAMHSA",
    "PubMed",
    "Europe PMC",
    "Semantic Scholar",
    "CASEL",
    "Common Sense Media",
    "Internet Matters",
    "eSafety Commissioner",
    "Attendance Works",
    "Education Endowment Foundation",
    "National Center for School Mental Health",
    "American School Counselor Association",
    "National Association of School Psychologists",
    "OECD",
    "World Economic Forum",
    "SCERT Karnataka",
    "National Institute of Open Schooling",
}

APPROVED_DOMAINS = {
    "aap.org",
    "baha.org.in",
    "bahedu.in",
    "cbse.gov.in",
    "cdc.gov",
    "europepmc.org",
    "iapindia.org",
    "mohfw.gov.in",
    "ncbi.nlm.nih.gov",
    "ncert.nic.in",
    "ncpcr.gov.in",
    "nhm.gov.in",
    "nice.org.uk",
    "nimhans.ac.in",
    "nimh.nih.gov",
    "nih.gov",
    "nhs.uk",
    "pubmed.ncbi.nlm.nih.gov",
    "samhsa.gov",
    "semanticscholar.org",
    "unesco.org",
    "unicef.org",
    "who.int",
    "casel.org",
    "commonsensemedia.org",
    "commonsense.org",
    "internetmatters.org",
    "esafety.gov.au",
    "attendanceworks.org",
    "educationendowmentfoundation.org.uk",
    "schoolmentalhealth.org",
    "schoolcounselor.org",
    "nasponline.org",
    "oecd.org",
    "weforum.org",
    "scert.karnataka.gov.in",
    "nios.ac.in",
}


@dataclass(frozen=True)
class SourceValidation:
    approved: bool
    reason: str
    normalized_domain: str | None = None


def normalize_domain(url: str) -> str | None:
    parsed = urlparse(url)
    host = parsed.netloc.lower().split("@")[-1].split(":")[0]
    if host.startswith("www."):
        host = host[4:]
    return host or None


def is_domain_approved(domain: str | None) -> bool:
    if not domain:
        return False
    return any(domain == approved or domain.endswith(f".{approved}") for approved in APPROVED_DOMAINS)


def validate_source(url: str, organization: str) -> SourceValidation:
    domain = normalize_domain(url)
    org_ok = organization in APPROVED_ORGANIZATIONS
    domain_ok = is_domain_approved(domain)
    if org_ok and domain_ok:
        return SourceValidation(True, "approved", domain)
    if not org_ok:
        return SourceValidation(False, f"organization is not approved: {organization}", domain)
    return SourceValidation(False, f"domain is not approved: {domain}", domain)
