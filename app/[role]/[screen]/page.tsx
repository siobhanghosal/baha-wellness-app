import { notFound } from "next/navigation";
import { getRoleScreens, getScreenBySlug } from "@/lib/screen-registry";
import { PrototypeScreenPage } from "@/components/design-system/screen-page";

export default async function ScreenPage({ params }: { params: Promise<{ role: string; screen: string }> }) {
  const resolved = await params;
  const { role, screen: screenSlug } = resolved;
  const screen = getScreenBySlug(role, screenSlug);
  if (!screen) return notFound();
  const roleScreens = getRoleScreens(role);
  return <PrototypeScreenPage screen={screen} roleScreens={roleScreens} role={role} />;
}
