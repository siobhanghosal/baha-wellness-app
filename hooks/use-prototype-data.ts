"use client";

import { useQuery } from "@tanstack/react-query";
import { getLocalRoleData, getLocalScreens, getLocalTranslations } from "@/lib/api";
import { usePrototypeSettings } from "@/lib/prototype-store";

export function usePrototypeRoleData(role: string) {
  const { activePersonaId, ageGroup, demoMode } = usePrototypeSettings();

  return useQuery({
    queryKey: ["role-data", role, activePersonaId, ageGroup, demoMode],
    queryFn: () => getLocalRoleData(role, { activePersonaId, ageGroup, demoMode }),
  });
}

export function usePrototypeScreens() {
  return useQuery({
    queryKey: ["screens"],
    queryFn: () => getLocalScreens(),
  });
}

export function useTranslations() {
  return useQuery({
    queryKey: ["translations"],
    queryFn: () => getLocalTranslations(),
  });
}
