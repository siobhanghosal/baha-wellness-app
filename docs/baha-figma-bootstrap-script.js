const existingPages = figma.root.children.map((p) => p.name);
const wantedPages = [
  "00 Cover",
  "01 Product Architecture",
  "02 Student App",
  "03 Parent App",
  "04 Teacher App",
  "05 BAHA Counselor App",
  "06 Foundations",
];

const createdNodeIds = [];
const mutatedNodeIds = [];

function ensurePage(name) {
  let page = figma.root.children.find((p) => p.name === name);
  if (!page) {
    page = figma.createPage();
    page.name = name;
    createdNodeIds.push(page.id);
  } else {
    mutatedNodeIds.push(page.id);
  }
  return page;
}

const coverPage = ensurePage("00 Cover");
await figma.setCurrentPageAsync(coverPage);

const existingCover = coverPage.children.find((n) => n.name === "BAHA Cover");
if (!existingCover) {
  const cover = figma.createAutoLayout("VERTICAL");
  cover.name = "BAHA Cover";
  cover.x = 120;
  cover.y = 120;
  cover.resize(1440, 1024);
  cover.paddingTop = 72;
  cover.paddingRight = 72;
  cover.paddingBottom = 72;
  cover.paddingLeft = 72;
  cover.itemSpacing = 24;
  cover.fills = [{ type: "SOLID", color: { r: 0.95, g: 0.98, b: 0.97 } }];
  cover.cornerRadius = 32;

  await figma.loadFontAsync({ family: "Inter", style: "Regular" });
  await figma.loadFontAsync({ family: "Inter", style: "Medium" });
  await figma.loadFontAsync({ family: "Inter", style: "Semi Bold" });

  const eyebrow = figma.createText();
  eyebrow.characters = "BAHA WELLNESS COMPANION";
  eyebrow.fontName = { family: "Inter", style: "Regular" };
  eyebrow.fontSize = 20;
  eyebrow.fills = [{ type: "SOLID", color: { r: 0.11, g: 0.43, b: 0.40 } }];

  const title = figma.createText();
  title.characters = "Adolescent-first wellness platform";
  title.fontName = { family: "Inter", style: "Semi Bold" };
  title.fontSize = 56;
  title.lineHeight = { unit: "PIXELS", value: 64 };
  title.fills = [{ type: "SOLID", color: { r: 0.10, g: 0.17, b: 0.21 } }];

  const subtitle = figma.createText();
  subtitle.characters =
    "Student, Parent, Teacher, and BAHA Counselor apps built on a privacy-first shared platform.";
  subtitle.fontName = { family: "Inter", style: "Regular" };
  subtitle.fontSize = 24;
  subtitle.lineHeight = { unit: "PIXELS", value: 34 };
  subtitle.fills = [{ type: "SOLID", color: { r: 0.26, g: 0.34, b: 0.38 } }];
  subtitle.layoutSizingHorizontal = "FILL";

  const principles = figma.createAutoLayout("HORIZONTAL");
  principles.name = "Principles";
  principles.itemSpacing = 16;

  const principleTexts = [
    "Support before crisis",
    "Awareness before intervention",
    "Self-knowledge before diagnosis",
  ];

  for (const label of principleTexts) {
    const chip = figma.createAutoLayout("HORIZONTAL");
    chip.paddingTop = 12;
    chip.paddingRight = 18;
    chip.paddingBottom = 12;
    chip.paddingLeft = 18;
    chip.cornerRadius = 999;
    chip.fills = [{ type: "SOLID", color: { r: 0.86, g: 0.94, b: 0.92 } }];

    const chipText = figma.createText();
    chipText.characters = label;
    chipText.fontName = { family: "Inter", style: "Medium" };
    chipText.fontSize = 18;
    chipText.fills = [{ type: "SOLID", color: { r: 0.11, g: 0.32, b: 0.31 } }];
    chip.appendChild(chipText);
    createdNodeIds.push(chip.id, chipText.id);
    principles.appendChild(chip);
  }

  const roles = figma.createAutoLayout("HORIZONTAL");
  roles.name = "Roles";
  roles.itemSpacing = 16;

  const roleNames = [
    "Student App",
    "Parent App",
    "Teacher App",
    "BAHA Counselor App",
  ];

  for (const label of roleNames) {
    const card = figma.createAutoLayout("VERTICAL");
    card.paddingTop = 24;
    card.paddingRight = 24;
    card.paddingBottom = 24;
    card.paddingLeft = 24;
    card.itemSpacing = 8;
    card.cornerRadius = 24;
    card.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
    card.strokes = [{ type: "SOLID", color: { r: 0.84, g: 0.89, b: 0.88 } }];
    card.strokeWeight = 1;
    card.resize(292, 140);

    const roleTitle = figma.createText();
    roleTitle.characters = label;
    roleTitle.fontName = { family: "Inter", style: "Semi Bold" };
    roleTitle.fontSize = 24;
    roleTitle.fills = [{ type: "SOLID", color: { r: 0.10, g: 0.17, b: 0.21 } }];

    const roleBody = figma.createText();
    roleBody.characters =
      "Dedicated experience with role-specific privacy, content, and actions.";
    roleBody.fontName = { family: "Inter", style: "Regular" };
    roleBody.fontSize = 16;
    roleBody.lineHeight = { unit: "PIXELS", value: 24 };
    roleBody.fills = [{ type: "SOLID", color: { r: 0.30, g: 0.37, b: 0.40 } }];
    roleBody.layoutSizingHorizontal = "FILL";

    card.appendChild(roleTitle);
    card.appendChild(roleBody);
    createdNodeIds.push(card.id, roleTitle.id, roleBody.id);
    roles.appendChild(card);
  }

  cover.appendChild(eyebrow);
  cover.appendChild(title);
  cover.appendChild(subtitle);
  cover.appendChild(principles);
  cover.appendChild(roles);
  coverPage.appendChild(cover);
  createdNodeIds.push(
    cover.id,
    eyebrow.id,
    title.id,
    subtitle.id,
    principles.id,
    roles.id,
  );
}

for (const pageName of wantedPages) {
  ensurePage(pageName);
}

return {
  createdNodeIds,
  mutatedNodeIds,
  existingPages,
  pageNames: figma.root.children.map((p) => p.name),
};
