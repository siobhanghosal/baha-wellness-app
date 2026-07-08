import prototypeData from "@/mock-data/json/prototype-data.json";
import screens from "@/mock-data/generated/screens.json";
import translations from "@/mock-data/json/translations.json";
import { applyPersonaOverlay } from "@/lib/demo-content";
import type { DemoPersonaId } from "@/lib/demo-content";

export async function wait(ms = 180) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function getLocalScreens<T>() {
  await wait(120);
  return screens as T;
}

export async function getLocalRoleData<T>(
  role: string,
  options?: { activePersonaId?: DemoPersonaId; ageGroup?: string; demoMode?: "baseline" | "seeded" },
) {
  await wait(220);
  const canonical = role === "counselor" ? "baha" : role;
  const baseData = (prototypeData as Record<string, unknown>)[canonical] as T;
  return applyPersonaOverlay(
    canonical,
    baseData,
    options?.activePersonaId ?? "persona-b",
    options?.ageGroup ?? "14-16",
    options?.demoMode ?? "seeded",
  );
}

export async function getLocalTranslations<T>() {
  await wait(60);
  return translations as T;
}
