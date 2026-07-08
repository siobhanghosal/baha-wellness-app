import { redirect } from "next/navigation";
import { defaultRoutes } from "@/lib/prototype-config";

export default async function RoleIndex({ params }: { params: Promise<{ role: string }> }) {
  const resolved = await params;
  const route = defaultRoutes[resolved.role as keyof typeof defaultRoutes] ?? defaultRoutes.student;
  redirect(route);
}
