"use client";

import type { ReactNode } from "react";
import { createContext, useContext, useEffect, useMemo, useState } from "react";
import type { DemoPersonaId } from "@/lib/demo-content";
import { defaultRoutes } from "@/lib/prototype-config";

type ThemeMode = "light" | "dark";
type NetworkMode = "online" | "offline";
type AgeGroup = "9-13" | "14-16" | "17-19";
type RoleMode = "student" | "parent" | "teacher" | "baha";
type DemoMode = "baseline" | "seeded";
type Language = "en-IN" | "hi-IN";
type Severity = "low" | "medium" | "high" | "critical";

export type FeedbackEntry = {
  id: string;
  createdAt: string;
  screen: string;
  route: string;
  comment: string;
  severity: Severity;
  role: string;
  scenarioId: null | string;
  personaId: DemoPersonaId;
};

type PrototypeState = {
  role: RoleMode;
  ageGroup: AgeGroup;
  theme: ThemeMode;
  network: NetworkMode;
  demoMode: DemoMode;
  language: Language;
  activePersonaId: DemoPersonaId;
  activeScenarioId: null | string;
  presentationMode: boolean;
  hideDeveloperControls: boolean;
  hideDebugLabels: boolean;
  presentationCursor: boolean;
  autoAdvance: boolean;
  feedbackEntries: FeedbackEntry[];
  setRole: (value: RoleMode) => void;
  setAgeGroup: (value: AgeGroup) => void;
  setTheme: (value: ThemeMode) => void;
  setNetwork: (value: NetworkMode) => void;
  setDemoMode: (value: DemoMode) => void;
  setLanguage: (value: Language) => void;
  setActivePersonaId: (value: DemoPersonaId) => void;
  setActiveScenarioId: (value: null | string) => void;
  setPresentationMode: (value: boolean) => void;
  setHideDeveloperControls: (value: boolean) => void;
  setHideDebugLabels: (value: boolean) => void;
  setPresentationCursor: (value: boolean) => void;
  setAutoAdvance: (value: boolean) => void;
  addFeedback: (entry: Omit<FeedbackEntry, "createdAt" | "id" | "personaId" | "scenarioId">) => void;
  clearFeedback: () => void;
  reset: () => void;
};

const STORAGE_KEY = "baha-prototype-settings";

const PrototypeContext = createContext<PrototypeState | null>(null);

const defaults = {
  role: "student" as RoleMode,
  ageGroup: "14-16" as AgeGroup,
  theme: "light" as ThemeMode,
  network: "online" as NetworkMode,
  demoMode: "seeded" as DemoMode,
  language: "en-IN" as Language,
  activePersonaId: "persona-b" as DemoPersonaId,
  activeScenarioId: null as null | string,
  presentationMode: false,
  hideDeveloperControls: false,
  hideDebugLabels: false,
  presentationCursor: false,
  autoAdvance: false,
  feedbackEntries: [] as FeedbackEntry[],
};

export function PrototypeProvider({ children }: { children: ReactNode }) {
  const [role, setRole] = useState<RoleMode>(defaults.role);
  const [ageGroup, setAgeGroup] = useState<AgeGroup>(defaults.ageGroup);
  const [theme, setTheme] = useState<ThemeMode>(defaults.theme);
  const [network, setNetwork] = useState<NetworkMode>(defaults.network);
  const [demoMode, setDemoMode] = useState<DemoMode>(defaults.demoMode);
  const [language, setLanguage] = useState<Language>(defaults.language);
  const [activePersonaId, setActivePersonaId] = useState<DemoPersonaId>(defaults.activePersonaId);
  const [activeScenarioId, setActiveScenarioId] = useState<null | string>(defaults.activeScenarioId);
  const [presentationMode, setPresentationModeState] = useState(defaults.presentationMode);
  const [hideDeveloperControls, setHideDeveloperControls] = useState(defaults.hideDeveloperControls);
  const [hideDebugLabels, setHideDebugLabels] = useState(defaults.hideDebugLabels);
  const [presentationCursor, setPresentationCursor] = useState(defaults.presentationCursor);
  const [autoAdvance, setAutoAdvance] = useState(defaults.autoAdvance);
  const [feedbackEntries, setFeedbackEntries] = useState<FeedbackEntry[]>(defaults.feedbackEntries);

  useEffect(() => {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return;
    try {
      const parsed = JSON.parse(raw);
      setRole(parsed.role ?? defaults.role);
      setAgeGroup(parsed.ageGroup ?? defaults.ageGroup);
      setTheme(parsed.theme ?? defaults.theme);
      setNetwork(parsed.network ?? defaults.network);
      setDemoMode(parsed.demoMode ?? defaults.demoMode);
      setLanguage(parsed.language ?? defaults.language);
      setActivePersonaId(parsed.activePersonaId ?? defaults.activePersonaId);
      setActiveScenarioId(parsed.activeScenarioId ?? defaults.activeScenarioId);
      setPresentationModeState(parsed.presentationMode ?? defaults.presentationMode);
      setHideDeveloperControls(parsed.hideDeveloperControls ?? defaults.hideDeveloperControls);
      setHideDebugLabels(parsed.hideDebugLabels ?? defaults.hideDebugLabels);
      setPresentationCursor(parsed.presentationCursor ?? defaults.presentationCursor);
      setAutoAdvance(parsed.autoAdvance ?? defaults.autoAdvance);
      setFeedbackEntries(parsed.feedbackEntries ?? defaults.feedbackEntries);
    } catch {
      localStorage.removeItem(STORAGE_KEY);
    }
  }, []);

  useEffect(() => {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({
        role,
        ageGroup,
        theme,
        network,
        demoMode,
        language,
        activePersonaId,
        activeScenarioId,
        presentationMode,
        hideDeveloperControls,
        hideDebugLabels,
        presentationCursor,
        autoAdvance,
        feedbackEntries,
      }),
    );
    document.documentElement.dataset.theme = theme;
    document.documentElement.dataset.role = role;
    document.documentElement.dataset.ageGroup = ageGroup;
    document.documentElement.dataset.presentation = presentationMode ? "true" : "false";
    document.documentElement.dataset.presentationCursor = presentationCursor ? "true" : "false";
  }, [
    role,
    ageGroup,
    theme,
    network,
    demoMode,
    language,
    activePersonaId,
    activeScenarioId,
    presentationMode,
    hideDeveloperControls,
    hideDebugLabels,
    presentationCursor,
    autoAdvance,
    feedbackEntries,
  ]);

  const value = useMemo<PrototypeState>(
    () => ({
      role,
      ageGroup,
      theme,
      network,
      demoMode,
      language,
      activePersonaId,
      activeScenarioId,
      presentationMode,
      hideDeveloperControls,
      hideDebugLabels,
      presentationCursor,
      autoAdvance,
      feedbackEntries,
      setRole,
      setAgeGroup,
      setTheme,
      setNetwork,
      setDemoMode,
      setLanguage,
      setActivePersonaId,
      setActiveScenarioId,
      setPresentationMode: (value) => {
        setPresentationModeState(value);
        setHideDeveloperControls(value);
        setHideDebugLabels(value);
        setPresentationCursor(value);
      },
      setHideDeveloperControls,
      setHideDebugLabels,
      setPresentationCursor,
      setAutoAdvance,
      addFeedback: (entry) => {
        setFeedbackEntries((current) => [
          {
            id: `feedback-${Date.now()}`,
            createdAt: new Date().toISOString(),
            screen: entry.screen,
            route: entry.route,
            comment: entry.comment,
            severity: entry.severity,
            role: entry.role,
            scenarioId: activeScenarioId,
            personaId: activePersonaId,
          },
          ...current,
        ]);
      },
      clearFeedback: () => setFeedbackEntries([]),
      reset: () => {
        setRole(defaults.role);
        setAgeGroup(defaults.ageGroup);
        setTheme(defaults.theme);
        setNetwork(defaults.network);
        setDemoMode(defaults.demoMode);
        setLanguage(defaults.language);
        setActivePersonaId(defaults.activePersonaId);
        setActiveScenarioId(defaults.activeScenarioId);
        setPresentationModeState(defaults.presentationMode);
        setHideDeveloperControls(defaults.hideDeveloperControls);
        setHideDebugLabels(defaults.hideDebugLabels);
        setPresentationCursor(defaults.presentationCursor);
        setAutoAdvance(defaults.autoAdvance);
        setFeedbackEntries(defaults.feedbackEntries);
        localStorage.removeItem(STORAGE_KEY);
      },
    }),
    [
      role,
      ageGroup,
      theme,
      network,
      demoMode,
      language,
      activePersonaId,
      activeScenarioId,
      presentationMode,
      hideDeveloperControls,
      hideDebugLabels,
      presentationCursor,
      autoAdvance,
      feedbackEntries,
    ],
  );

  return <PrototypeContext.Provider value={value}>{children}</PrototypeContext.Provider>;
}

export function usePrototypeSettings() {
  const context = useContext(PrototypeContext);
  if (!context) throw new Error("usePrototypeSettings must be used within PrototypeProvider");
  return context;
}

export { defaultRoutes };
