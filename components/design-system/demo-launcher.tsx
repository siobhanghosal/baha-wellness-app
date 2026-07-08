"use client";

import { startTransition } from "react";
import { useRouter } from "next/navigation";
import { ArrowRight, PlayCircle, Presentation, ShieldCheck, Sparkles, Users } from "lucide-react";
import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { demoAudienceCards, demoPersonas, demoScenarios, getPersonaById } from "@/lib/demo-content";
import { screenRegistry } from "@/lib/screen-registry";
import { usePrototypeSettings } from "@/lib/prototype-store";

export function DemoLauncher() {
  const router = useRouter();
  const {
    role,
    ageGroup,
    activePersonaId,
    activeScenarioId,
    presentationMode,
    feedbackEntries,
    setRole,
    setAgeGroup,
    setActivePersonaId,
    setActiveScenarioId,
    setDemoMode,
    setPresentationMode,
    reset,
  } = usePrototypeSettings();

  const currentPersona = getPersonaById(activePersonaId);
  const uniqueComponents = new Set(screenRegistry.flatMap((screen) => screen.components)).size;
  const activeScenario = demoScenarios.find((scenario) => scenario.id === activeScenarioId) ?? null;

  function openAudience(route: string, nextRole: "student" | "parent" | "teacher" | "baha", nextAgeGroup: "9-13" | "14-16" | "17-19") {
    startTransition(() => {
      setRole(nextRole);
      setAgeGroup(nextAgeGroup);
      setActiveScenarioId(null);
      router.push(route);
    });
  }

  function startScenario(scenarioId: string) {
    const scenario = demoScenarios.find((item) => item.id === scenarioId);
    if (!scenario) return;

    startTransition(() => {
      setRole(scenario.role);
      setAgeGroup(scenario.ageGroup);
      setDemoMode("seeded");
      setActivePersonaId(scenario.personaId);
      setActiveScenarioId(scenario.id);
      router.push(scenario.routes[0]);
    });
  }

  return (
    <main className="min-h-screen bg-canvas px-4 py-6 text-ink sm:px-6 lg:px-8">
      <div className="mx-auto max-w-7xl space-y-6">
        <motion.section initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} className="overflow-hidden rounded-[36px] border border-line bg-card shadow-float">
          <div className="grid gap-6 p-6 lg:grid-cols-[1.25fr_0.75fr] lg:p-8">
            <div className="space-y-5">
              <div className="flex flex-wrap gap-2">
                <Badge tone="warning">BAHA Wellness Companion</Badge>
                <Badge tone="primary">Interactive Product Demonstration</Badge>
                <Badge tone={presentationMode ? "success" : "neutral"}>{presentationMode ? "Presentation mode on" : "Exploration mode"}</Badge>
              </div>
              <div className="space-y-3">
                <h1 className="font-display text-4xl font-semibold tracking-tight sm:text-5xl">Stakeholder-ready walkthroughs for students, families, educators, and clinicians.</h1>
                <p className="max-w-3xl text-base leading-7 text-muted">
                  Choose an audience or start a guided scenario. Every flow uses local mock data, documented navigation, and presentation-safe controls designed for BAHA stakeholder review meetings.
                </p>
              </div>
              <div className="flex flex-wrap gap-3">
                <Button size="lg" onClick={() => startScenario("student-daily-journey")}>
                  Start recommended walkthrough
                </Button>
                <Button variant="secondary" size="lg" onClick={() => setPresentationMode(!presentationMode)}>
                  <Presentation className="mr-2 h-4 w-4" />
                  {presentationMode ? "Exit presentation mode" : "Enter presentation mode"}
                </Button>
              </div>
            </div>
            <Card className="bg-gradient-to-br from-primary/10 via-card to-support/10">
              <div className="space-y-4">
                <div>
                  <p className="text-xs uppercase tracking-[0.18em] text-muted">Current demo context</p>
                  <h2 className="mt-2 font-display text-2xl font-semibold text-ink">{currentPersona.label}: {currentPersona.title}</h2>
                </div>
                <p className="text-sm leading-6 text-muted">{currentPersona.summary}</p>
                <div className="grid gap-3 sm:grid-cols-2">
                  <MiniStat label="Active role" value={role === "baha" ? "Counselor" : role} />
                  <MiniStat label="Age band" value={ageGroup} />
                  <MiniStat label="Current flow" value={activeScenario?.name ?? "Free explore"} />
                  <MiniStat label="Feedback notes" value={String(feedbackEntries.length)} />
                </div>
              </div>
            </Card>
          </div>
        </motion.section>

        <section className="space-y-4">
          <div className="flex items-center gap-3">
            <Users className="h-5 w-5 text-primary" />
            <div>
              <h2 className="font-display text-2xl font-semibold">Choose an audience</h2>
              <p className="text-sm text-muted">Open the prototype at the right level of maturity and responsibility for the review session.</p>
            </div>
          </div>
          <div className="grid gap-4 xl:grid-cols-3">
            {demoAudienceCards.map((card) => (
              <Card key={card.id} className="flex h-full flex-col justify-between gap-5">
                <div className="space-y-4">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <h3 className="font-display text-2xl font-semibold text-ink">{card.label}</h3>
                      <p className="mt-2 text-sm text-muted">{card.targetAudience}</p>
                    </div>
                    <Badge tone="primary">{card.estimatedDemoDuration}</Badge>
                  </div>
                  <div className="space-y-2 text-sm text-muted">
                    <p><span className="font-medium text-ink">Purpose:</span> {card.purpose}</p>
                    <p><span className="font-medium text-ink">Main workflows:</span> {card.mainWorkflows.join(" • ")}</p>
                  </div>
                </div>
                <Button onClick={() => openAudience(card.route, card.role, card.ageGroup)}>
                  Open audience demo
                </Button>
              </Card>
            ))}
          </div>
        </section>

        <section className="grid gap-6 xl:grid-cols-[1.1fr_0.9fr]">
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <PlayCircle className="h-5 w-5 text-primary" />
              <div>
                <h2 className="font-display text-2xl font-semibold">Guided demo scenarios</h2>
                <p className="text-sm text-muted">Each button activates the right role, persona, and documented route sequence automatically.</p>
              </div>
            </div>
            <div className="grid gap-4">
              {demoScenarios.map((scenario) => (
                <Card key={scenario.id} className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                  <div className="space-y-2">
                    <div className="flex flex-wrap items-center gap-2">
                      <h3 className="font-display text-xl font-semibold text-ink">{scenario.name}</h3>
                      <Badge tone="warning">{scenario.estimatedDuration}</Badge>
                      <Badge tone="neutral">{scenario.role === "baha" ? "Counselor" : scenario.role}</Badge>
                    </div>
                    <p className="text-sm text-muted">{scenario.description}</p>
                    <p className="text-sm text-muted"><span className="font-medium text-ink">Purpose:</span> {scenario.purpose}</p>
                  </div>
                  <Button onClick={() => startScenario(scenario.id)}>
                    Start scenario
                    <ArrowRight className="ml-2 h-4 w-4" />
                  </Button>
                </Card>
              ))}
            </div>
          </div>

          <div className="space-y-6">
            <section className="space-y-4">
              <div className="flex items-center gap-3">
                <Sparkles className="h-5 w-5 text-primary" />
                <div>
                  <h2 className="font-display text-2xl font-semibold">Demo personas</h2>
                  <p className="text-sm text-muted">Switch the underlying story without changing the product structure.</p>
                </div>
              </div>
              <div className="grid gap-4">
                {demoPersonas.map((persona) => (
                  <Card key={persona.id} className="space-y-4">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <p className="text-xs uppercase tracking-[0.18em] text-muted">{persona.label}</p>
                        <h3 className="mt-1 font-display text-xl font-semibold text-ink">{persona.title}</h3>
                      </div>
                      <Badge tone={activePersonaId === persona.id ? "success" : "neutral"}>{activePersonaId === persona.id ? "Active" : "Available"}</Badge>
                    </div>
                    <p className="text-sm text-muted">{persona.summary}</p>
                    <p className="text-sm text-muted"><span className="font-medium text-ink">Best for:</span> {persona.bestFor}</p>
                    <Button variant={activePersonaId === persona.id ? "secondary" : "primary"} onClick={() => setActivePersonaId(persona.id)}>
                      {activePersonaId === persona.id ? "Persona selected" : "Use this persona"}
                    </Button>
                  </Card>
                ))}
              </div>
            </section>

            <section className="space-y-4">
              <div className="flex items-center gap-3">
                <ShieldCheck className="h-5 w-5 text-primary" />
                <div>
                  <h2 className="font-display text-2xl font-semibold">Demo dashboard</h2>
                  <p className="text-sm text-muted">Presentation stats for facilitators, investors, and implementation partners.</p>
                </div>
              </div>
              <div className="grid gap-3 sm:grid-cols-2">
                <MiniStat label="Total screens" value={String(screenRegistry.length)} />
                <MiniStat label="Routes" value={String(screenRegistry.length)} />
                <MiniStat label="Components" value={String(uniqueComponents)} />
                <MiniStat label="Demo personas" value={String(demoPersonas.length)} />
                <MiniStat label="Coverage" value="100% documented flows" />
                <MiniStat label="Current role" value={role === "baha" ? "Counselor" : role} />
                <MiniStat label="Current flow" value={activeScenario?.name ?? "Free explore"} />
              </div>
              <Card className="space-y-4">
                <p className="text-sm text-muted">
                  Reset the prototype between meetings, or keep the current scenario and persona active while switching roles inside the experience.
                </p>
                <div className="flex flex-wrap gap-3">
                  <Button variant="secondary" onClick={reset}>Reset prototype</Button>
                  <Button onClick={() => startScenario("counselor-escalation")}>Open counselor walkthrough</Button>
                </div>
              </Card>
            </section>
          </div>
        </section>
      </div>
    </main>
  );
}

function MiniStat({ label, value }: { label: string; value: string }) {
  return (
    <Card className="space-y-2">
      <p className="text-sm text-muted">{label}</p>
      <p className="font-display text-2xl font-semibold text-ink">{value}</p>
    </Card>
  );
}
