"use client";

import type { ReactNode } from "react";
import { useEffect, useMemo, useState } from "react";
import { motion } from "framer-motion";
import { Controller, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Bell, BookOpen, Brain, ChevronDown, Filter, HeartPulse, MessageSquareText, ShieldAlert, Sparkles, Star, Timer, UserRound } from "lucide-react";
import type { ScreenMeta } from "@/lib/screen-registry";
import { PrototypeAppShell } from "@/components/design-system/app-shell";
import { StatGrid, BarChart, TimelineWidget, MessageList } from "@/components/design-system/data-widgets";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input, Textarea } from "@/components/ui/input";
import { Dialog } from "@/components/ui/dialog";
import { Sheet } from "@/components/ui/sheet";
import { Progress } from "@/components/ui/progress";
import { getPersonaById, getScenarioById, getStakeholderNote } from "@/lib/demo-content";
import { usePrototypeSettings } from "@/lib/prototype-store";

const noteSchema = z.object({
  focus: z.string().min(2),
  detail: z.string().min(8),
  urgency: z.string().min(2),
});

const checkInSchema = z.object({
  mood: z.number().min(1).max(5),
  sleep: z.number().min(1).max(10),
  stress: z.number().min(1).max(5),
  energy: z.number().min(1).max(5),
});

type ActionRoutes = {
  primary: string;
  secondary: string;
  citation: string;
  humanHelp: string;
  moduleDetail: string;
  filter: string;
  policy: string;
  gameDetails: string[];
  gameLaunches: string[];
};

export function PrototypeScreenRenderer({ screen, roleData, roleScreens }: { screen: ScreenMeta; roleData: any; roleScreens: ScreenMeta[] }) {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [sheetOpen, setSheetOpen] = useState(false);
  const [feedbackMessage, setFeedbackMessage] = useState<string | null>(null);
  const router = useRouter();
  const { ageGroup, network, demoMode, language, activePersonaId, activeScenarioId, autoAdvance, hideDebugLabels, setActiveScenarioId } = usePrototypeSettings();
  const scenario = getScenarioById(activeScenarioId);
  const persona = getPersonaById(activePersonaId);
  const scenarioStepIndex = scenario ? scenario.routes.indexOf(screen.route) : -1;
  const notes = getStakeholderNote(screen);

  const checkInForm = useForm({
    resolver: zodResolver(checkInSchema),
    defaultValues: { mood: 4, sleep: 7, stress: 3, energy: 4 },
  });

  const noteForm = useForm({
    resolver: zodResolver(noteSchema),
    defaultValues: { focus: screen.name, detail: "This mocked prototype captures the interaction flow for stakeholder review.", urgency: "Moderate" },
  });

  const quickLinks = useMemo(() => {
    const pairs = [
      roleScreens.find((item) => /module detail/i.test(item.name)),
      roleScreens.find((item) => /lesson view/i.test(item.name)),
      roleScreens.find((item) => /quiz/i.test(item.name)),
      roleScreens.find((item) => /citation detail/i.test(item.name)),
      roleScreens.find((item) => /help center/i.test(item.name)),
      roleScreens.find((item) => /case detail/i.test(item.name)),
      roleScreens.find((item) => /content editor/i.test(item.name)),
      roleScreens.find((item) => /queue filters/i.test(item.name)),
    ].filter(Boolean) as ScreenMeta[];
    return pairs.slice(0, 4);
  }, [roleScreens]);

  const statItems = buildStatItems(screen, roleData);
  const actionRoutes = useMemo(() => buildActionRoutes(screen, roleScreens), [roleScreens, screen]);

  useEffect(() => {
    if (!autoAdvance || !scenario || scenarioStepIndex < 0 || scenarioStepIndex >= scenario.routes.length - 1) {
      return;
    }

    const timeout = window.setTimeout(() => {
      router.push(scenario.routes[scenarioStepIndex + 1]);
    }, 4500);

    return () => window.clearTimeout(timeout);
  }, [autoAdvance, router, scenario, scenarioStepIndex]);

  useEffect(() => {
    if (!feedbackMessage) {
      return;
    }

    const timeout = window.setTimeout(() => setFeedbackMessage(null), 2200);
    return () => window.clearTimeout(timeout);
  }, [feedbackMessage]);

  return (
    <>
      <PrototypeAppShell screen={screen} onOpenDialog={() => setDialogOpen(true)} onOpenSheet={() => setSheetOpen(true)}>
        <div className="space-y-4">
          {network === "offline" ? (
            <Card className="border-warning/30 bg-warning/10">
              <div className="flex items-start gap-3">
                <ShieldAlert className="mt-1 h-5 w-5 text-warning" />
                <div>
                  <p className="font-medium text-ink">Offline simulation active</p>
                  <p className="text-sm text-muted">The prototype is showing cached-safe behavior and resilient UI states for this route.</p>
                </div>
              </div>
            </Card>
          ) : null}

          <Hero screen={screen} ageGroup={ageGroup} demoMode={demoMode} personaLabel={persona.label} />

          {feedbackMessage ? (
            <Card className="border-success/30 bg-success/10">
              <p className="text-sm font-medium text-ink">{feedbackMessage}</p>
            </Card>
          ) : null}

          {scenario && scenarioStepIndex >= 0 ? (
            <ScenarioPanel
              currentIndex={scenarioStepIndex}
              onNext={() => router.push(scenario.routes[Math.min(scenarioStepIndex + 1, scenario.routes.length - 1)])}
              onPrevious={() => router.push(scenario.routes[Math.max(scenarioStepIndex - 1, 0)])}
              onStop={() => {
                setActiveScenarioId(null);
                router.push(`/${screen.role}`);
              }}
              scenario={scenario}
              totalSteps={scenario.routes.length}
            />
          ) : null}

          <StatGrid items={statItems} />

          {renderScreenContent(
            screen,
            roleData,
            checkInForm,
            noteForm,
            quickLinks,
            actionRoutes,
            (route) => router.push(route),
            (message) => setFeedbackMessage(message),
            () => setDialogOpen(true),
          )}

          <StakeholderNotesPanel screen={screen} notes={notes} />

          <Card className="space-y-3">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="font-display text-lg font-semibold text-ink">Prototype navigation</h3>
                <p className="text-sm text-muted">Every route in this role is available for stakeholder walkthrough.</p>
              </div>
              <Badge tone="neutral">{language}</Badge>
            </div>
            <div className="grid gap-2 sm:grid-cols-2">
              {roleScreens.slice(0, 8).map((item) => (
                <Link key={item.route} href={item.route} className={`rounded-2xl border border-line bg-canvas px-4 py-3 text-sm transition hover:-translate-y-0.5 ${item.route === screen.route ? "border-primary text-primary" : "text-ink"}`}>
                  <div className="flex items-center justify-between">
                    <span>{item.name}</span>
                    {!hideDebugLabels ? <span className="text-xs text-muted">{item.id}</span> : null}
                  </div>
                </Link>
              ))}
            </div>
            <div className="flex justify-end gap-3">
              <Link href={screen.previousRoute}><Button variant="secondary">Back Route</Button></Link>
              <Link href={screen.nextRoute}><Button>Next Route</Button></Link>
            </div>
          </Card>
        </div>
      </PrototypeAppShell>

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} title={`${screen.name} details`} description={`${screen.auth}. ${screen.permission}. Transition: ${screen.transition}.`}>
        <div className="mt-4 space-y-4 text-sm text-muted">
          <div className="rounded-2xl bg-canvas p-4">
            <p className="font-medium text-ink">Why this screen exists</p>
            <p className="mt-2">{notes.whyExists}</p>
          </div>
          <div className="rounded-2xl bg-canvas p-4">
            <p className="font-medium text-ink">PRD reference</p>
            <p className="mt-2">{notes.prdReference}</p>
          </div>
          <div className="rounded-2xl bg-canvas p-4">
            <p className="font-medium text-ink">Components</p>
            <div className="mt-2 flex flex-wrap gap-2">
              {screen.components.map((component) => <Badge key={component} tone="primary">{component}</Badge>)}
            </div>
          </div>
        </div>
      </Dialog>

      <Sheet open={sheetOpen} onClose={() => setSheetOpen(false)} title="Prototype quick actions">
        <div className="space-y-3">
          <div className="rounded-[24px] bg-canvas p-4 text-sm text-muted">
            <p className="font-medium text-ink">{scenario?.name ?? "Free exploration"}</p>
            <p className="mt-2">Persona: {persona.label}. Auto advance is {autoAdvance ? "enabled" : "disabled"}.</p>
          </div>
          <div className="grid gap-2 sm:grid-cols-2">
            {quickLinks.map((item) => (
              <Link key={item.route} href={item.route} className="rounded-2xl border border-line bg-canvas px-4 py-3 text-sm text-ink">
                {item.name}
              </Link>
            ))}
          </div>
          <Button className="w-full" onClick={() => router.push(actionRoutes.primary)}>Open recommended next route</Button>
        </div>
      </Sheet>
    </>
  );
}

function Hero({ screen, ageGroup, demoMode, personaLabel }: { screen: ScreenMeta; ageGroup: string; demoMode: string; personaLabel: string }) {
  return (
    <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }}>
      <Card className="overflow-hidden bg-gradient-to-br from-primary/10 via-card to-support/10">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div className="space-y-2">
            <p className="text-xs uppercase tracking-[0.18em] text-muted">{screen.roleLabel} experience</p>
            <h3 className="font-display text-2xl font-semibold text-ink">{screen.name}</h3>
            <p className="max-w-2xl text-sm text-muted">Faithful interactive prototype driven by the BAHA architecture, UX specification, navigation model, design system, and visual language.</p>
          </div>
          <div className="flex flex-wrap gap-2">
            <Badge tone="primary">{screen.pattern}</Badge>
            <Badge tone="success">{ageGroup}</Badge>
            <Badge tone="warning">{demoMode}</Badge>
            <Badge tone="neutral">{personaLabel}</Badge>
          </div>
        </div>
      </Card>
    </motion.div>
  );
}

function ScenarioPanel({
  currentIndex,
  onNext,
  onPrevious,
  onStop,
  scenario,
  totalSteps,
}: {
  currentIndex: number;
  onNext: () => void;
  onPrevious: () => void;
  onStop: () => void;
  scenario: NonNullable<ReturnType<typeof getScenarioById>>;
  totalSteps: number;
}) {
  const { autoAdvance } = usePrototypeSettings();
  const progress = ((currentIndex + 1) / totalSteps) * 100;

  return (
    <Card className="space-y-4 border-primary/20 bg-primary/5">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <p className="text-xs uppercase tracking-[0.18em] text-muted">Guided demo scenario</p>
          <h3 className="mt-1 font-display text-xl font-semibold text-ink">{scenario.name}</h3>
          <p className="mt-2 max-w-2xl text-sm text-muted">{scenario.description}</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Badge tone="primary">Step {currentIndex + 1} of {totalSteps}</Badge>
          <Badge tone="warning">{scenario.estimatedDuration}</Badge>
          <Badge tone={autoAdvance ? "success" : "neutral"}>{autoAdvance ? "Auto advance on" : "Manual advance"}</Badge>
        </div>
      </div>
      <Progress value={progress} />
      <div className="flex flex-wrap justify-end gap-3">
        <Button variant="secondary" onClick={onPrevious} disabled={currentIndex === 0}>Previous step</Button>
        <Button variant="secondary" onClick={onStop}>Exit scenario</Button>
        <Button onClick={onNext} disabled={currentIndex >= totalSteps - 1}>Next step</Button>
      </div>
    </Card>
  );
}

function StakeholderNotesPanel({
  notes,
  screen,
}: {
  notes: ReturnType<typeof getStakeholderNote>;
  screen: ScreenMeta;
}) {
  return (
    <Card className="p-0">
      <details className="group">
        <summary className="flex cursor-pointer list-none items-center justify-between px-5 py-4">
          <div>
            <p className="text-xs uppercase tracking-[0.18em] text-muted">Stakeholder notes</p>
            <h3 className="mt-1 font-display text-lg font-semibold text-ink">{screen.name} rationale</h3>
          </div>
          <ChevronDown className="h-5 w-5 text-muted transition group-open:rotate-180" />
        </summary>
        <div className="border-t border-line px-5 py-4">
          <div className="grid gap-3 xl:grid-cols-2">
            <NoteBlock title="Why this screen exists" body={notes.whyExists} />
            <NoteBlock title="User goal" body={notes.userGoal} />
            <NoteBlock title="PRD reference" body={notes.prdReference} />
            <NoteBlock title="Privacy considerations" body={notes.privacy} />
            <div className="xl:col-span-2">
              <NoteBlock title="Clinical considerations" body={notes.clinical} />
            </div>
          </div>
        </div>
      </details>
    </Card>
  );
}

function NoteBlock({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-[24px] bg-canvas p-4">
      <p className="font-medium text-ink">{title}</p>
      <p className="mt-2 text-sm text-muted">{body}</p>
    </div>
  );
}

function buildStatItems(screen: ScreenMeta, roleData: any) {
  if (screen.role === "student") {
    return [
      { label: "Current streak", value: `${roleData.profile.streak} weeks`, tone: "success" as const },
      { label: "Focus theme", value: roleData.profile.focusTheme, tone: "primary" as const },
      { label: "Notifications", value: roleData.notifications.length, tone: "warning" as const },
      { label: "Learning progress", value: `${roleData.modules[0].progress}%`, tone: "primary" as const },
    ];
  }
  if (screen.role === "parent") {
    return [
      { label: "Consent status", value: roleData.guardian.consent, tone: "success" as const },
      { label: "Linked students", value: roleData.linkedStudents.length, tone: "primary" as const },
      { label: "Summary focus", value: roleData.summary.guideTheme, tone: "warning" as const },
      { label: "Unread notices", value: roleData.notifications.length, tone: "primary" as const },
    ];
  }
  if (screen.role === "teacher") {
    return [
      { label: "School", value: roleData.teacher.school, tone: "neutral" as const },
      { label: "Referrals", value: roleData.referrals.length, tone: "warning" as const },
      { label: "Pastoral notes", value: roleData.pastoralNotes.length, tone: "primary" as const },
      { label: "Training", value: roleData.teacher.training, tone: "success" as const },
    ];
  }
  return [
    { label: "Queue count", value: roleData.operator.queueCount, tone: "danger" as const },
    { label: "Cases", value: roleData.queue.length, tone: "warning" as const },
    { label: "Content items", value: roleData.content.length, tone: "primary" as const },
    { label: "Audit events", value: roleData.audit.length, tone: "neutral" as const },
  ];
}

function buildActionRoutes(screen: ScreenMeta, roleScreens: ScreenMeta[]): ActionRoutes {
  const roleHome = `/${screen.role}`;

  function firstDifferent(...routes: Array<string | undefined>) {
    return routes.find((route) => route && route !== screen.route) ?? roleHome;
  }

  function findByName(...patterns: string[]) {
    return roleScreens.find((item) => item.route !== screen.route && patterns.some((pattern) => item.name.toLowerCase().includes(pattern)))?.route;
  }

  function findGameRoute(title: string, index: number) {
    const lowerTitle = title.toLowerCase();
    if (lowerTitle.includes("emotion")) return firstDifferent(findByName("emotion explorer"), screen.nextRoute);
    if (lowerTitle.includes("friend")) return firstDifferent(findByName("friendship choices"), screen.nextRoute);
    if (lowerTitle.includes("breath")) return firstDifferent(findByName("calm breathing"), screen.nextRoute);
    if (lowerTitle.includes("time") || lowerTitle.includes("cap")) return firstDifferent(findByName("time cap prompt"), screen.nextRoute);

    const fallbackRoutes = [
      findByName("emotion explorer"),
      findByName("friendship choices"),
      findByName("calm breathing"),
      findByName("time cap prompt"),
    ];

    return firstDifferent(fallbackRoutes[index], screen.nextRoute);
  }

  function launchRouteForGame(title: string, index: number) {
    const targetRoute = findGameRoute(title, index);
    const targetScreen = roleScreens.find((item) => item.route === targetRoute);
    if (!targetScreen) return targetRoute;
    return targetScreen.route === screen.route ? firstDifferent(targetScreen.nextRoute, screen.nextRoute, roleHome) : targetScreen.route;
  }

  const humanHelpRoute = screen.role === "student"
    ? firstDifferent(findByName("counselor request"), findByName("help center"), screen.nextRoute, roleHome)
    : screen.role === "teacher"
      ? firstDifferent(findByName("referral detail"), findByName("restricted student case notice"), screen.nextRoute, roleHome)
      : screen.role === "parent"
        ? firstDifferent(findByName("alert notification detail"), findByName("data rights"), screen.nextRoute, roleHome)
        : firstDifferent(findByName("emergency protocol"), findByName("case assignment"), findByName("support queue"), screen.nextRoute, roleHome);

  const policyRoute = screen.role === "student"
    ? firstDifferent(findByName("privacy settings"), findByName("consent tier editor"), findByName("help center"), screen.nextRoute, roleHome)
    : screen.role === "parent"
      ? firstDifferent(findByName("data rights"), findByName("privacy tier review"), findByName("notification settings"), screen.nextRoute, roleHome)
      : screen.role === "teacher"
        ? firstDifferent(findByName("notification center"), findByName("settings"), screen.nextRoute, roleHome)
        : firstDifferent(findByName("operational settings"), findByName("audit log"), findByName("user and role management"), screen.nextRoute, roleHome);

  return {
    primary: firstDifferent(screen.nextRoute, roleHome),
    secondary: firstDifferent(screen.previousRoute, roleHome),
    citation: firstDifferent(findByName("citation detail"), screen.nextRoute, roleHome),
    humanHelp: humanHelpRoute,
    moduleDetail: firstDifferent(findByName("module detail"), screen.nextRoute, roleHome),
    filter: firstDifferent(findByName("queue filters"), findByName("trend filter"), screen.nextRoute, roleHome),
    policy: policyRoute,
    gameDetails: [
      findGameRoute("Emotion Explorer", 0),
      findGameRoute("Friendship Choices", 1),
      findGameRoute("Calm Breathing", 2),
      findGameRoute("Time Cap Prompt", 3),
    ],
    gameLaunches: [
      launchRouteForGame("Emotion Explorer", 0),
      launchRouteForGame("Friendship Choices", 1),
      launchRouteForGame("Calm Breathing", 2),
      launchRouteForGame("Time Cap Prompt", 3),
    ],
  };
}

function renderScreenContent(
  screen: ScreenMeta,
  roleData: any,
  checkInForm: any,
  noteForm: any,
  quickLinks: ScreenMeta[],
  actionRoutes: ActionRoutes,
  navigate: (route: string) => void,
  showFeedback: (message: string) => void,
  openInfoDialog: () => void,
) {
  const lower = screen.name.toLowerCase();

  if (lower.includes("splash")) {
    return (
      <Card className="flex min-h-[280px] flex-col items-center justify-center gap-4 text-center">
        <div className="rounded-full bg-primary/10 p-5 text-primary"><Sparkles className="h-8 w-8" /></div>
        <h3 className="font-display text-3xl font-semibold">BAHA Wellness Companion</h3>
        <p className="max-w-md text-sm text-muted">Bootstrapping session context, privacy posture, mock notifications, and stakeholder-ready demo data.</p>
        <Progress value={72} />
      </Card>
    );
  }

  if (lower.includes("questionnaire")) {
    return (
      <Card className="space-y-5">
        <div>
          <h3 className="font-display text-xl font-semibold">Weekly check-in</h3>
          <p className="text-sm text-muted">Mocked React Hook Form + Zod validation with fully local interaction states.</p>
        </div>
        {(["mood", "sleep", "stress", "energy"] as const).map((field) => (
          <Controller
            key={field}
            control={checkInForm.control}
            name={field}
            render={({ field: controllerField }) => (
              <div className="space-y-2">
                <div className="flex items-center justify-between text-sm">
                  <span className="capitalize">{field}</span>
                  <span className="text-muted">{controllerField.value}</span>
                </div>
                <input type="range" min={1} max={field === "sleep" ? 10 : 5} value={controllerField.value} onChange={(event) => controllerField.onChange(Number(event.target.value))} className="w-full accent-[var(--color-primary)]" />
              </div>
            )}
          />
        ))}
        <div className="flex justify-end">
          <Button onClick={checkInForm.handleSubmit(() => navigate(actionRoutes.primary))}>Save check-in</Button>
        </div>
      </Card>
    );
  }

  if (lower.includes("buddy") || lower.includes("chat")) {
    return (
      <div className="grid gap-4 xl:grid-cols-[1.3fr_0.9fr]">
        <Card className="space-y-4">
          <div className="flex items-center gap-2">
            <MessageSquareText className="h-5 w-5 text-primary" />
            <h3 className="font-display text-xl font-semibold">Conversation</h3>
          </div>
          <MessageList messages={roleData.chat} />
          <div className="rounded-[24px] border border-line bg-canvas p-3">
            <Input placeholder="Type a supportive message..." />
            <div className="mt-3 flex justify-end gap-2">
              <Button variant="secondary" onClick={() => navigate(actionRoutes.citation)}>Open citation</Button>
              <Button onClick={() => showFeedback("Message captured in the prototype conversation.")}>Send</Button>
            </div>
          </div>
        </Card>
        <Card className="space-y-4">
          <h3 className="font-display text-xl font-semibold">Safe prompts and handoff</h3>
          <div className="space-y-3">
            {roleData.safeQuestions?.map((question: any) => (
              <div key={question.id} className="rounded-2xl bg-canvas p-4">
                <div className="flex items-center justify-between gap-2">
                  <p className="text-sm font-medium text-ink">{question.title}</p>
                  <Badge tone="primary">{question.tag}</Badge>
                </div>
              </div>
            ))}
          </div>
          <Button className="w-full" variant="secondary" onClick={() => navigate(actionRoutes.humanHelp)}>Get human help</Button>
        </Card>
      </div>
    );
  }

  if (lower.includes("learning") || lower.includes("module") || lower.includes("lesson") || lower.includes("quiz")) {
    return (
      <div className="grid gap-4 xl:grid-cols-[1.1fr_0.9fr]">
        <Card className="space-y-4">
          <div className="flex items-center gap-2">
            <BookOpen className="h-5 w-5 text-primary" />
            <h3 className="font-display text-xl font-semibold">Learning catalogue</h3>
          </div>
          <div className="space-y-3">
            {(roleData.modules || []).map((module: any) => (
              <div key={module.id} className="rounded-[24px] border border-line bg-canvas p-4">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="font-medium text-ink">{module.title}</p>
                    <p className="mt-1 text-sm text-muted">{module.duration} · {module.format ?? "guided content"}</p>
                  </div>
                  <Badge tone="primary">{module.progress}%</Badge>
                </div>
                <div className="mt-3"><Progress value={module.progress} /></div>
                <div className="mt-3 flex gap-2">
                  <Button variant="secondary" onClick={() => navigate(actionRoutes.moduleDetail)}>Details</Button>
                  <Button onClick={() => navigate(actionRoutes.primary)}>Continue</Button>
                </div>
              </div>
            ))}
          </div>
        </Card>
        <Card className="space-y-4">
          <h3 className="font-display text-xl font-semibold">Module detail and quiz</h3>
          <p className="text-sm text-muted">This prototype shows lesson progression, quiz completion, and reflection states without backend dependency.</p>
          <div className="space-y-3">
            <div className="rounded-[24px] bg-canvas p-4">
              <p className="font-medium text-ink">Lesson summary</p>
              <p className="mt-2 text-sm text-muted">Supportive content cards, audio, and reflection prompts use the documented design-system components.</p>
            </div>
            <div className="rounded-[24px] bg-canvas p-4">
              <p className="font-medium text-ink">Quiz result</p>
              <p className="mt-2 text-sm text-muted">Formative feedback remains encouraging and non-punitive.</p>
              <div className="mt-3 flex gap-2">
                <Badge tone="success">Completed</Badge>
                <Badge tone="primary">Reflection saved</Badge>
              </div>
            </div>
          </div>
        </Card>
      </div>
    );
  }

  if (lower.includes("game") || lower.includes("breathing") || lower.includes("friendship") || lower.includes("emotion explorer")) {
    return (
      <div className="grid gap-4 xl:grid-cols-[1.1fr_0.9fr]">
        <Card className="space-y-4">
          <div className="flex items-center gap-2">
            <Brain className="h-5 w-5 text-primary" />
            <h3 className="font-display text-xl font-semibold">Games and regulation</h3>
          </div>
          <div className="grid gap-3">
            {(roleData.games || []).map((game: any, index: number) => (
              <div key={game.id} className="rounded-[24px] border border-line bg-canvas p-4">
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <p className="font-medium text-ink">{game.title}</p>
                    <p className="text-sm text-muted">{game.duration}</p>
                  </div>
                  <Badge tone="primary">{game.status}</Badge>
                </div>
                <div className="mt-3 flex gap-2">
                  <Button
                    variant="secondary"
                    onClick={() => navigate(actionRoutes.gameDetails[index] ?? actionRoutes.primary)}
                  >
                    Details
                  </Button>
                  <Button
                    onClick={() => navigate(actionRoutes.gameLaunches[index] ?? actionRoutes.primary)}
                  >
                    Launch
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </Card>
        <Card className="space-y-4">
          <h3 className="font-display text-xl font-semibold">Achievements</h3>
          <div className="space-y-3">
            {(roleData.achievements || []).map((achievement: any) => (
              <div key={achievement.id} className="rounded-[24px] bg-canvas p-4">
                <div className="flex items-center justify-between">
                  <p className="font-medium text-ink">{achievement.title}</p>
                  <Badge tone={achievement.status === "earned" ? "success" : "neutral"}>{achievement.status}</Badge>
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    );
  }

  if (lower.includes("queue") || lower.includes("case") || lower.includes("audit") || lower.includes("content") || lower.includes("analytics") || lower.includes("threshold")) {
    return (
      <div className="grid gap-4 xl:grid-cols-[1.2fr_0.8fr]">
        <Card className="space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Filter className="h-5 w-5 text-primary" />
              <h3 className="font-display text-xl font-semibold">Operational workspace</h3>
            </div>
            <Button variant="secondary" onClick={() => navigate(actionRoutes.filter)}>Open filters</Button>
          </div>
          <div className="overflow-hidden rounded-[24px] border border-line">
            <div className="grid grid-cols-4 bg-canvas px-4 py-3 text-xs font-semibold uppercase tracking-[0.12em] text-muted">
              <span>ID</span>
              <span>Source</span>
              <span>Status</span>
              <span>Severity</span>
            </div>
            {(roleData.queue || roleData.content || roleData.users || []).map((row: any, index: number) => (
              <div key={row.id ?? index} className="grid grid-cols-4 border-t border-line bg-card px-4 py-4 text-sm text-ink">
                <span>{row.id}</span>
                <span>{row.source ?? row.title ?? row.name}</span>
                <span>{row.status ?? row.scope}</span>
                <span>{row.severity ?? "Reviewed"}</span>
              </div>
            ))}
          </div>
        </Card>
        <div className="space-y-4">
          {roleData.caseTimeline ? <TimelineWidget events={roleData.caseTimeline} /> : null}
          {roleData.analytics ? <StatGrid items={roleData.analytics.map((item: any) => ({ label: item.metric, value: item.value, tone: "primary" as const }))} /> : null}
        </div>
      </div>
    );
  }

  if (lower.includes("referral") || lower.includes("pastoral") || lower.includes("request") || lower.includes("assignment") || lower.includes("editor")) {
    return (
      <div className="grid gap-4 xl:grid-cols-[1fr_0.95fr]">
        <Card className="space-y-4">
          <h3 className="font-display text-xl font-semibold">Workflow form</h3>
          <div className="space-y-3">
            <Input placeholder="Focus area" {...noteForm.register("focus")} />
            <Input placeholder="Urgency" {...noteForm.register("urgency")} />
            <Textarea placeholder="Add an operational note or support detail" {...noteForm.register("detail")} />
            <div className="flex justify-end gap-2">
              <Button variant="secondary" onClick={() => showFeedback("Draft saved locally for this prototype.")}>Save draft</Button>
              <Button onClick={noteForm.handleSubmit(() => navigate(actionRoutes.primary))}>Submit</Button>
            </div>
          </div>
        </Card>
        <Card className="space-y-4">
          <h3 className="font-display text-xl font-semibold">Workflow context</h3>
          <div className="space-y-3">
            {quickLinks.map((item) => (
              <Link key={item.route} href={item.route} className="block rounded-[24px] bg-canvas p-4 text-sm text-ink">
                {item.name}
              </Link>
            ))}
          </div>
        </Card>
      </div>
    );
  }

  if (lower.includes("trend") || lower.includes("summary") || lower.includes("dashboard") || lower.includes("home")) {
    const chartValues = screen.role === "teacher" ? roleData.classTrends : screen.role === "baha" ? roleData.analytics.map((item: any, index: number) => ({ theme: item.metric, score: 50 + index * 10 })) : roleData.moodHistory ?? [{ week: "Now", mood: 3 }];
    return (
      <div className="grid gap-4 xl:grid-cols-[1.15fr_0.85fr]">
        <BarChart values={chartValues} labelKey={screen.role === "baha" ? "theme" : screen.role === "teacher" ? "theme" : "week"} valueKey={screen.role === "teacher" ? "score" : screen.role === "baha" ? "score" : "mood"} />
        <Card className="space-y-4">
          <h3 className="font-display text-xl font-semibold">Recommendations and alerts</h3>
          <div className="space-y-3">
            {(roleData.notifications || []).map((item: any) => (
              <div key={item.id} className="rounded-[24px] bg-canvas p-4">
                <div className="flex items-start gap-3">
                  <Bell className="mt-0.5 h-4 w-4 text-primary" />
                  <div>
                    <p className="font-medium text-ink">{item.title}</p>
                    <p className="mt-1 text-sm text-muted">{item.body}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    );
  }

  if (lower.includes("profile") || lower.includes("settings") || lower.includes("privacy") || lower.includes("data rights") || lower.includes("notification")) {
    return (
      <div className="grid gap-4 xl:grid-cols-[1fr_1fr]">
        <Card className="space-y-3">
          <div className="flex items-center gap-2">
            <UserRound className="h-5 w-5 text-primary" />
            <h3 className="font-display text-xl font-semibold">Profile and preferences</h3>
          </div>
          {[{ label: "Reminders", value: "Enabled" }, { label: "Privacy tier", value: roleData.profile?.consentTier ?? roleData.guardian?.privacyTier ?? "Role-safe default" }, { label: "Language", value: "English (India)" }].map((item) => (
            <div key={item.label} className="flex items-center justify-between rounded-[24px] bg-canvas px-4 py-3">
              <span className="text-sm text-ink">{item.label}</span>
              <Badge tone="primary">{item.value}</Badge>
            </div>
          ))}
        </Card>
        <Card className="space-y-3">
          <h3 className="font-display text-xl font-semibold">Support and privacy</h3>
          <div className="space-y-3">
            <div className="rounded-[24px] bg-canvas p-4 text-sm text-muted">Settings are interactive, role-aware, and fully local to this prototype.</div>
            <div className="flex gap-2">
              <Button variant="secondary" onClick={openInfoDialog}>Open policy dialog</Button>
              <Button onClick={() => showFeedback("Preferences saved locally for this role.")}>Save preferences</Button>
            </div>
          </div>
        </Card>
      </div>
    );
  }

  if (lower.includes("offline") || lower.includes("pending") || lower.includes("restricted")) {
    return (
      <Card className="space-y-4">
        <div className="flex items-start gap-3">
          <ShieldAlert className="mt-1 h-6 w-6 text-warning" />
          <div>
            <h3 className="font-display text-xl font-semibold text-ink">Resilient state</h3>
            <p className="mt-2 text-sm text-muted">This route demonstrates offline, pending, or restricted-access behavior without breaking the prototype flow.</p>
          </div>
        </div>
        <div className="grid gap-3 sm:grid-cols-2">
          <Card className="bg-canvas">
            <p className="font-medium text-ink">Cached actions</p>
            <p className="mt-2 text-sm text-muted">Review saved content, open support guidance, and retry when network is restored.</p>
          </Card>
          <Card className="bg-canvas">
            <p className="font-medium text-ink">Safe next step</p>
            <p className="mt-2 text-sm text-muted">Use a documented parent route or return to the role home shell.</p>
          </Card>
        </div>
      </Card>
    );
  }

  return (
    <div className="grid gap-4 xl:grid-cols-[1.05fr_0.95fr]">
      <Card className="space-y-4">
        <div className="flex items-center gap-2">
          <HeartPulse className="h-5 w-5 text-primary" />
          <h3 className="font-display text-xl font-semibold">Documented screen experience</h3>
        </div>
        <p className="text-sm text-muted">This screen is rendered from the existing BAHA architecture artifacts, using shared prototype components and realistic mock data.</p>
        <div className="grid gap-3 sm:grid-cols-2">
          {quickLinks.map((item) => (
            <Link key={item.route} href={item.route} className="rounded-[24px] bg-canvas p-4 text-sm text-ink">
              {item.name}
            </Link>
          ))}
        </div>
      </Card>
      <Card className="space-y-4">
        <h3 className="font-display text-xl font-semibold">Interaction quality</h3>
        <div className="space-y-3">
          <QualityRow icon={<Timer className="h-4 w-4" />} title="Motion" body="200–300ms transitions and tactile feedback." />
          <QualityRow icon={<Star className="h-4 w-4" />} title="Accessibility" body="Large touch targets, contrast, and keyboard support." />
          <QualityRow icon={<Sparkles className="h-4 w-4" />} title="Mock realism" body="Local JSON data and scenario-specific interactions." />
        </div>
      </Card>
    </div>
  );
}

function QualityRow({ icon, title, body }: { icon: ReactNode; title: string; body: string }) {
  return (
    <div className="flex gap-3 rounded-[24px] bg-canvas p-4">
      <div className="mt-0.5 text-primary">{icon}</div>
      <div>
        <p className="font-medium text-ink">{title}</p>
        <p className="mt-1 text-sm text-muted">{body}</p>
      </div>
    </div>
  );
}
