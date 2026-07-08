import screens from "@/mock-data/generated/screens.json";

export type PrototypeRole = "student" | "parent" | "teacher" | "baha" | "counselor";

export type ScreenMeta = {
  id: string;
  name: string;
  role: "student" | "parent" | "teacher" | "baha";
  roleLabel: string;
  route: string;
  pattern: string;
  layout: string;
  components: string[];
  slug: string;
  deepLink: string;
  transition: string;
  auth: string;
  permission: string;
  previousRoute: string;
  nextRoute: string;
  isTopLevel: boolean;
};

export const screenRegistry = screens as ScreenMeta[];

export function canonicalRole(role: string): PrototypeRole {
  if (role === "counselor") return "baha";
  return role as PrototypeRole;
}

export function getRoleScreens(role: string) {
  const canonical = canonicalRole(role);
  return screenRegistry.filter((screen) => screen.role === canonical);
}

export function getScreenBySlug(role: string, slug: string) {
  const canonical = canonicalRole(role);
  return screenRegistry.find((screen) => screen.role === canonical && screen.slug === slug);
}

export function getScreenByRoute(route: string) {
  return screenRegistry.find((screen) => screen.route === route);
}
