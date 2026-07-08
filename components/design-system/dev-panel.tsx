"use client";

import type { ReactNode } from "react";
import { useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { demoPersonas, demoScenarios } from "@/lib/demo-content";
import { defaultRoutes, roleSwitcher } from "@/lib/prototype-config";
import { usePrototypeSettings } from "@/lib/prototype-store";

export function DeveloperPanel() {
  const [open, setOpen] = useState(false);
  const {
    role,
    ageGroup,
    theme,
    network,
    language,
    demoMode,
    activePersonaId,
    activeScenarioId,
    hideDeveloperControls,
    setRole,
    setAgeGroup,
    setTheme,
    setNetwork,
    setLanguage,
    setDemoMode,
    setActivePersonaId,
    setActiveScenarioId,
    reset,
  } = usePrototypeSettings();
  const router = useRouter();
  const pathname = usePathname();

  if (hideDeveloperControls) {
    return null;
  }

  function handleRoleChange(nextRole: "student" | "parent" | "teacher" | "baha") {
    setRole(nextRole);
    setActiveScenarioId(null);
    router.push(defaultRoutes[nextRole]);
  }

  return (
    <div className="fixed bottom-4 right-4 z-50">
      <Button size="lg" onClick={() => setOpen((value) => !value)}>Developer Panel</Button>
      {open ? (
        <div className="mt-3 w-[320px] rounded-[28px] border border-line bg-card p-5 shadow-float">
          <div className="space-y-4 text-sm text-muted">
            <Field label="Role">
              <select value={role} onChange={(event) => handleRoleChange(event.target.value as "student" | "parent" | "teacher" | "baha")} className="h-11 w-full rounded-2xl border border-line bg-canvas px-3 text-ink">
                {roleSwitcher.map((item) => <option key={item.id} value={item.id === "baha" ? "baha" : item.id}>{item.label}</option>)}
              </select>
            </Field>
            <Field label="Age Group">
              <select value={ageGroup} onChange={(event) => setAgeGroup(event.target.value as "9-13" | "14-16" | "17-19")} className="h-11 w-full rounded-2xl border border-line bg-canvas px-3 text-ink">
                {["9-13", "14-16", "17-19"].map((item) => <option key={item}>{item}</option>)}
              </select>
            </Field>
            <Field label="Persona">
              <select value={activePersonaId} onChange={(event) => setActivePersonaId(event.target.value as "persona-a" | "persona-b" | "persona-c")} className="h-11 w-full rounded-2xl border border-line bg-canvas px-3 text-ink">
                {demoPersonas.map((persona) => <option key={persona.id} value={persona.id}>{persona.label}: {persona.title}</option>)}
              </select>
            </Field>
            <Field label="Theme">
              <ToggleGroup value={theme} onChange={(value) => setTheme(value as "light" | "dark")} options={["light", "dark"]} />
            </Field>
            <Field label="Network">
              <ToggleGroup value={network} onChange={(value) => setNetwork(value as "online" | "offline")} options={["online", "offline"]} />
            </Field>
            <Field label="Language">
              <select value={language} onChange={(event) => setLanguage(event.target.value as "en-IN" | "hi-IN")} className="h-11 w-full rounded-2xl border border-line bg-canvas px-3 text-ink">
                <option value="en-IN">English (India)</option>
                <option value="hi-IN">Hindi</option>
              </select>
            </Field>
            <Field label="Demo Data">
              <ToggleGroup value={demoMode} onChange={(value) => setDemoMode(value as "baseline" | "seeded")} options={["baseline", "seeded"]} />
            </Field>
            <Field label="Scenario">
              <select value={activeScenarioId ?? ""} onChange={(event) => setActiveScenarioId(event.target.value || null)} className="h-11 w-full rounded-2xl border border-line bg-canvas px-3 text-ink">
                <option value="">Free exploration</option>
                {demoScenarios.map((scenario) => <option key={scenario.id} value={scenario.id}>{scenario.name}</option>)}
              </select>
            </Field>
            <div className="rounded-2xl bg-black/5 p-3 text-xs dark:bg-white/5">
              <p>Current route</p>
              <p className="mt-1 font-mono text-[11px] text-ink">{pathname}</p>
            </div>
            <Button variant="secondary" className="w-full" onClick={reset}>Reset Prototype</Button>
          </div>
        </div>
      ) : null}
    </div>
  );
}

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="space-y-2">
      <p className="text-xs font-semibold uppercase tracking-[0.18em] text-muted">{label}</p>
      {children}
    </div>
  );
}

function ToggleGroup({ value, onChange, options }: { value: string; onChange: (value: string) => void; options: string[] }) {
  return (
    <div className="grid grid-cols-2 gap-2 rounded-2xl bg-canvas p-1">
      {options.map((option) => (
        <button key={option} onClick={() => onChange(option)} className={`rounded-2xl px-3 py-2 capitalize transition ${value === option ? "bg-primary text-white" : "text-ink"}`}>
          {option}
        </button>
      ))}
    </div>
  );
}
