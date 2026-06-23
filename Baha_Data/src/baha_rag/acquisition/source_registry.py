from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum


class SourceKind(StrEnum):
    ORGANIZATION = "organization"
    RESEARCH = "research"


@dataclass(frozen=True)
class SourceDefinition:
    organization: str
    kind: SourceKind
    country: str | None
    base_domains: tuple[str, ...]
    seed_urls: tuple[str, ...]
    rate_limit_seconds: float = 1.0
    robots_required: bool = True


SOURCE_REGISTRY: tuple[SourceDefinition, ...] = (
    SourceDefinition(
        "Bangalore Adolescent Health Academy",
        SourceKind.ORGANIZATION,
        "India",
        ("baha.org.in", "bahedu.in"),
        ("https://bahedu.in/",),
    ),
    SourceDefinition(
        "IAP Adolescent Health Academy",
        SourceKind.ORGANIZATION,
        "India",
        ("aha.iapindia.org",),
        (
            "https://aha.iapindia.org/",
            "https://aha.iapindia.org/MKU/",
            "https://aha.iapindia.org/AYA/",
            "https://aha.iapindia.org/knowledge-bank/",
            "https://aha.iapindia.org/resources-aha-webinars/",
            "https://aha.iapindia.org/t-teach-PPTs/",
            "https://aha.iapindia.org/t-teach-resource-material/",
            "https://aha.iapindia.org/other-manuals/",
            "https://aha.iapindia.org/Presentation/",
            "https://aha.iapindia.org/adolescon-today/",
            "https://aha.iapindia.org/indian-journal-of-adolescent-medicine/",
            "https://aha.iapindia.org/iap-consensus-guidelines/",
            "https://aha.iapindia.org/parents/",
            "https://aha.iapindia.org/adolescent/",
            "https://aha.iapindia.org/aha-module-for-teachers/",
            "https://aha.iapindia.org/drug-abuse/",
        ),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "Indian Academy of Pediatrics",
        SourceKind.ORGANIZATION,
        "India",
        ("iapindia.org",),
        ("https://iapindia.org/", "https://iapindia.org/publications"),
    ),
    SourceDefinition(
        "NIMHANS",
        SourceKind.ORGANIZATION,
        "India",
        ("nimhans.ac.in", "nimhansbkt.demo-appiness.com"),
        (
            "https://www.nimhans.ac.in/",
            "https://www.nimhans.ac.in/research",
            "https://www.nimhans.ac.in/projects",
            "https://www.nimhans.ac.in/publications/publications-list",
            "https://www.nimhans.ac.in/publications/posters",
            "https://www.nimhans.ac.in/publications/videos",
            "https://www.nimhans.ac.in/library/resources",
            "https://www.nimhans.ac.in/departments",
        ),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "WHO",
        SourceKind.ORGANIZATION,
        None,
        ("who.int",),
        (
            "https://www.who.int/news-room/fact-sheets/detail/adolescent-mental-health",
            "https://www.who.int/teams/mental-health-and-substance-use/mental-health-gap-action-programme",
            "https://www.who.int/teams/mental-health-and-substance-use/data-research/mental-health-atlas",
            "https://www.who.int/health-topics/school-health",
            "https://www.who.int/data",
        ),
    ),
    SourceDefinition(
        "UNICEF",
        SourceKind.ORGANIZATION,
        None,
        ("unicef.org", "data.unicef.org"),
        (
            "https://www.unicef.org/mental-health",
            "https://data.unicef.org/",
            "https://www.unicef.org/adolescence",
        ),
    ),
    SourceDefinition(
        "UNESCO",
        SourceKind.ORGANIZATION,
        None,
        ("unesco.org", "unesdoc.unesco.org", "uis.unesco.org"),
        (
            "https://www.unesco.org/",
            "https://www.unesco.org/en/health-education",
            "https://www.unesco.org/en/school-violence-and-bullying",
            "https://unesdoc.unesco.org/",
            "https://uis.unesco.org/",
        ),
    ),
    SourceDefinition(
        "NCERT",
        SourceKind.ORGANIZATION,
        "India",
        ("ncert.nic.in",),
        ("https://ncert.nic.in/", "https://ncert.nic.in/guidance-and-counselling.php"),
    ),
    SourceDefinition(
        "CBSE",
        SourceKind.ORGANIZATION,
        "India",
        ("cbse.gov.in",),
        ("https://www.cbse.gov.in/", "https://www.cbse.gov.in/cbsenew/counseling.html"),
    ),
    SourceDefinition(
        "NCPCR",
        SourceKind.ORGANIZATION,
        "India",
        ("ncpcr.gov.in",),
        (
            "https://ncpcr.gov.in/",
            "https://ncpcr.gov.in/publications",
            "https://ncpcr.gov.in/guidelines",
        ),
    ),
    SourceDefinition(
        "Ministry of Health and Family Welfare",
        SourceKind.ORGANIZATION,
        "India",
        ("mohfw.gov.in",),
        ("https://www.mohfw.gov.in/",),
    ),
    SourceDefinition(
        "National Mental Health Programme",
        SourceKind.ORGANIZATION,
        "India",
        ("mohfw.gov.in", "nhm.gov.in"),
        ("https://www.mohfw.gov.in/", "https://nhm.gov.in/"),
    ),
    SourceDefinition(
        "NICE",
        SourceKind.ORGANIZATION,
        "United Kingdom",
        ("nice.org.uk",),
        (
            "https://www.nice.org.uk/guidance/ng134",
            "https://www.nice.org.uk/guidance/ng87",
            "https://www.nice.org.uk/guidance/cg170",
            "https://www.nice.org.uk/guidance/ng225",
            "https://www.nice.org.uk/guidance/ng223",
            "https://www.nice.org.uk/guidance/cg159",
        ),
    ),
    SourceDefinition(
        "NHS",
        SourceKind.ORGANIZATION,
        "United Kingdom",
        ("nhs.uk",),
        (
            "https://www.nhs.uk/mental-health/",
            "https://www.nhs.uk/mental-health/children-and-young-adults/",
            "https://www.nhs.uk/mental-health/conditions/",
        ),
    ),
    SourceDefinition(
        "CDC",
        SourceKind.ORGANIZATION,
        "United States",
        ("cdc.gov",),
        (
            "https://www.cdc.gov/mental-health/",
            "https://www.cdc.gov/children-mental-health/about/index.html",
            "https://www.cdc.gov/healthyyouth/",
            "https://www.cdc.gov/youth-behavior/",
            "https://www.cdc.gov/school-health-conditions/",
        ),
    ),
    SourceDefinition(
        "NIMH",
        SourceKind.ORGANIZATION,
        "United States",
        ("nimh.nih.gov",),
        (
            "https://www.nimh.nih.gov/health/topics/child-and-adolescent-mental-health",
            "https://www.nimh.nih.gov/health/topics/anxiety-disorders",
            "https://www.nimh.nih.gov/health/topics/depression",
            "https://www.nimh.nih.gov/health/topics/attention-deficit-hyperactivity-disorder-adhd",
            "https://www.nimh.nih.gov/health/publications/children-and-mental-health",
        ),
    ),
    SourceDefinition(
        "NIH",
        SourceKind.ORGANIZATION,
        "United States",
        ("nih.gov", "ncbi.nlm.nih.gov"),
        (
            "https://www.nih.gov/health-information/emotional-wellness-toolkit",
            "https://www.nih.gov/health-information/your-healthiest-self-wellness-toolkits",
        ),
    ),
    SourceDefinition(
        "SAMHSA",
        SourceKind.ORGANIZATION,
        "United States",
        ("samhsa.gov",),
        (
            "https://www.samhsa.gov/mental-health/children-and-families",
            "https://www.samhsa.gov/mental-health/children-and-families/school-mental-health",
            "https://www.samhsa.gov/find-support/how-to-cope",
            "https://www.samhsa.gov/resource-search",
        ),
    ),
    SourceDefinition(
        "American Academy of Pediatrics",
        SourceKind.ORGANIZATION,
        "United States",
        ("aap.org", "healthychildren.org"),
        (
            "https://www.aap.org/en/patient-care/mental-health-initiatives/",
            "https://www.aap.org/en/patient-care/media-and-children/",
            "https://www.healthychildren.org/English/healthy-living/emotional-wellness/",
            "https://www.healthychildren.org/English/family-life/Media/",
        ),
    ),
    SourceDefinition(
        "CASEL",
        SourceKind.ORGANIZATION,
        "United States",
        ("casel.org",),
        (
            "https://casel.org/",
            "https://casel.org/fundamentals-of-sel/",
            "https://casel.org/systemic-implementation/",
            "https://casel.org/resources-support/",
        ),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "Common Sense Media",
        SourceKind.ORGANIZATION,
        "United States",
        ("commonsensemedia.org", "commonsense.org"),
        (
            "https://www.commonsensemedia.org/",
            "https://www.commonsense.org/education/digital-citizenship",
            "https://www.commonsense.org/education/articles",
            "https://www.commonsensemedia.org/articles",
        ),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "Internet Matters",
        SourceKind.ORGANIZATION,
        "United Kingdom",
        ("internetmatters.org",),
        (
            "https://www.internetmatters.org/",
            "https://www.internetmatters.org/advice/",
            "https://www.internetmatters.org/resources/",
        ),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "eSafety Commissioner",
        SourceKind.ORGANIZATION,
        "Australia",
        ("esafety.gov.au",),
        (
            "https://www.esafety.gov.au/",
            "https://www.esafety.gov.au/parents",
            "https://www.esafety.gov.au/educators",
            "https://www.esafety.gov.au/young-people",
            "https://www.esafety.gov.au/research",
        ),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "Attendance Works",
        SourceKind.ORGANIZATION,
        "United States",
        ("attendanceworks.org",),
        (
            "https://www.attendanceworks.org/",
            "https://www.attendanceworks.org/resources/",
            "https://www.attendanceworks.org/resources/toolkits/",
            "https://www.attendanceworks.org/research/",
        ),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "Education Endowment Foundation",
        SourceKind.ORGANIZATION,
        "United Kingdom",
        ("educationendowmentfoundation.org.uk",),
        (
            "https://educationendowmentfoundation.org.uk/",
            "https://educationendowmentfoundation.org.uk/education-evidence/",
            "https://educationendowmentfoundation.org.uk/education-evidence/guidance-reports",
        ),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "National Center for School Mental Health",
        SourceKind.ORGANIZATION,
        "United States",
        ("schoolmentalhealth.org",),
        (
            "https://www.schoolmentalhealth.org/",
            "https://www.schoolmentalhealth.org/Resources/",
            "https://www.schoolmentalhealth.org/Resources/Foundations-of-School-Mental-Health/",
        ),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "American School Counselor Association",
        SourceKind.ORGANIZATION,
        "United States",
        ("schoolcounselor.org",),
        (
            "https://www.schoolcounselor.org/",
            "https://www.schoolcounselor.org/Standards-Positions/",
            "https://www.schoolcounselor.org/Publications-Research/",
        ),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "National Association of School Psychologists",
        SourceKind.ORGANIZATION,
        "United States",
        ("nasponline.org",),
        (
            "https://www.nasponline.org/",
            "https://www.nasponline.org/resources-and-publications/resources-and-podcasts",
            "https://www.nasponline.org/research-and-policy",
        ),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "OECD",
        SourceKind.ORGANIZATION,
        None,
        ("oecd.org",),
        (
            "https://www.oecd.org/",
            "https://www.oecd.org/en/topics/education-and-skills.html",
            "https://www.oecd.org/en/topics/social-and-emotional-skills.html",
            "https://www.oecd.org/en/publications.html",
        ),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "World Economic Forum",
        SourceKind.ORGANIZATION,
        None,
        ("weforum.org",),
        (
            "https://www.weforum.org/",
            "https://www.weforum.org/topics/education/",
            "https://www.weforum.org/publications/",
        ),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "SCERT Karnataka",
        SourceKind.ORGANIZATION,
        "India",
        ("scert.karnataka.gov.in",),
        ("https://scert.karnataka.gov.in/",),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "National Institute of Open Schooling",
        SourceKind.ORGANIZATION,
        "India",
        ("nios.ac.in",),
        (
            "https://www.nios.ac.in/",
            "https://www.nios.ac.in/online-course-material/",
            "https://www.nios.ac.in/student-information-section/",
        ),
        rate_limit_seconds=1.5,
    ),
    SourceDefinition(
        "PubMed",
        SourceKind.RESEARCH,
        None,
        ("pubmed.ncbi.nlm.nih.gov", "ncbi.nlm.nih.gov"),
        ("https://pubmed.ncbi.nlm.nih.gov/",),
    ),
    SourceDefinition("Europe PMC", SourceKind.RESEARCH, None, ("europepmc.org",), ("https://europepmc.org/",)),
    SourceDefinition(
        "Semantic Scholar",
        SourceKind.RESEARCH,
        None,
        ("semanticscholar.org",),
        ("https://www.semanticscholar.org/",),
    ),
)

SOURCE_ALIASES = {
    "baha": "Bangalore Adolescent Health Academy",
    "iap": "Indian Academy of Pediatrics",
    "aha": "IAP Adolescent Health Academy",
    "iap aha": "IAP Adolescent Health Academy",
    "mohfw": "Ministry of Health and Family Welfare",
    "nmhp": "National Mental Health Programme",
    "aap": "American Academy of Pediatrics",
    "nimh": "NIMH",
    "common sense": "Common Sense Media",
    "asca": "American School Counselor Association",
    "nasp": "National Association of School Psychologists",
    "ncsmh": "National Center for School Mental Health",
    "eef": "Education Endowment Foundation",
    "nios": "National Institute of Open Schooling",
}


class SourceRegistryService:
    def all_sources(self) -> list[SourceDefinition]:
        return list(SOURCE_REGISTRY)

    def by_organization(self, organization: str) -> SourceDefinition:
        normalized = SOURCE_ALIASES.get(organization.lower(), organization)
        for source in SOURCE_REGISTRY:
            if source.organization.lower() == normalized.lower():
                return source
        raise KeyError(f"Unknown approved source: {organization}")

    def domains(self) -> set[str]:
        return {domain for source in SOURCE_REGISTRY for domain in source.base_domains}

    def organization_for_domain(self, host: str) -> SourceDefinition | None:
        normalized = host.removeprefix("www.").lower()
        for source in SOURCE_REGISTRY:
            if any(normalized == domain or normalized.endswith(f".{domain}") for domain in source.base_domains):
                return source
        return None
