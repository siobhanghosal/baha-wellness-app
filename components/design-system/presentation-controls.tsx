"use client";

import type { ReactNode } from "react";
import { useEffect, useState } from "react";
import { MonitorUp, MousePointer2, Play, Presentation, RefreshCcw, Scan, WandSparkles } from "lucide-react";
import { usePathname } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { getScenarioById } from "@/lib/demo-content";
import { usePrototypeSettings } from "@/lib/prototype-store";

export function PresentationControls() {
  const [open, setOpen] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const pathname = usePathname();
  const {
    presentationMode,
    hideDeveloperControls,
    hideDebugLabels,
    presentationCursor,
    autoAdvance,
    activeScenarioId,
    activePersonaId,
    setPresentationMode,
    setHideDeveloperControls,
    setHideDebugLabels,
    setPresentationCursor,
    setAutoAdvance,
    reset,
  } = usePrototypeSettings();
  const scenario = getScenarioById(activeScenarioId);

  useEffect(() => {
    function handleFullscreenChange() {
      setIsFullscreen(Boolean(document.fullscreenElement));
    }

    document.addEventListener("fullscreenchange", handleFullscreenChange);
    handleFullscreenChange();
    return () => document.removeEventListener("fullscreenchange", handleFullscreenChange);
  }, []);

  async function toggleFullscreen() {
    if (document.fullscreenElement) {
      await document.exitFullscreen();
      return;
    }
    await document.documentElement.requestFullscreen();
  }

  return (
    <>
      <div className="fixed bottom-4 left-4 z-50">
        <Button size="lg" onClick={() => setOpen((value) => !value)}>
          <Presentation className="mr-2 h-4 w-4" />
          Demo Controls
        </Button>
        {open ? (
          <Card className="mt-3 w-[340px] space-y-4">
            <div className="space-y-2">
              <div className="flex items-center justify-between gap-3">
                <div>
                  <p className="text-xs uppercase tracking-[0.18em] text-muted">Presentation mode</p>
                  <h3 className="font-display text-xl font-semibold text-ink">Stakeholder review controls</h3>
                </div>
                <Badge tone={presentationMode ? "success" : "neutral"}>{presentationMode ? "Live" : "Off"}</Badge>
              </div>
              <p className="text-sm text-muted">Use these controls to simplify the prototype for live demos without changing the core workflows.</p>
            </div>

            <div className="space-y-2">
              <ToggleRow
                active={presentationMode}
                icon={<WandSparkles className="h-4 w-4" />}
                title="Presentation mode"
                body="Turns on a cleaner stakeholder view."
                onClick={() => setPresentationMode(!presentationMode)}
              />
              <ToggleRow
                active={hideDeveloperControls}
                icon={<Scan className="h-4 w-4" />}
                title="Hide developer controls"
                body="Removes the developer panel from view."
                onClick={() => setHideDeveloperControls(!hideDeveloperControls)}
              />
              <ToggleRow
                active={hideDebugLabels}
                icon={<Presentation className="h-4 w-4" />}
                title="Hide debug labels"
                body="Hides route-style metadata such as screen IDs and transition tags."
                onClick={() => setHideDebugLabels(!hideDebugLabels)}
              />
              <ToggleRow
                active={presentationCursor}
                icon={<MousePointer2 className="h-4 w-4" />}
                title="Presentation cursor"
                body="Shows a visible cursor halo during screen sharing."
                onClick={() => setPresentationCursor(!presentationCursor)}
              />
              <ToggleRow
                active={autoAdvance}
                icon={<Play className="h-4 w-4" />}
                title="Auto advance"
                body="Moves through guided scenarios automatically when available."
                onClick={() => setAutoAdvance(!autoAdvance)}
              />
            </div>

            <div className="rounded-[24px] bg-canvas p-4 text-sm text-muted">
              <p className="font-medium text-ink">Current context</p>
              <p className="mt-2">Route: <span className="font-mono text-[11px] text-ink">{pathname}</span></p>
              <p className="mt-1">Scenario: <span className="text-ink">{scenario?.name ?? "Free exploration"}</span></p>
              <p className="mt-1">Persona: <span className="text-ink">{activePersonaId.toUpperCase()}</span></p>
            </div>

            <div className="grid grid-cols-2 gap-2">
              <Button variant="secondary" onClick={toggleFullscreen}>
                <MonitorUp className="mr-2 h-4 w-4" />
                {isFullscreen ? "Exit fullscreen" : "Fullscreen"}
              </Button>
              <Button variant="secondary" onClick={reset}>
                <RefreshCcw className="mr-2 h-4 w-4" />
                Reset
              </Button>
            </div>
          </Card>
        ) : null}
      </div>
      <PresentationCursor />
    </>
  );
}

export function PresentationCursor() {
  const { presentationCursor } = usePrototypeSettings();
  const [position, setPosition] = useState({ x: -100, y: -100 });

  useEffect(() => {
    if (!presentationCursor) return;

    function handleMove(event: MouseEvent) {
      setPosition({ x: event.clientX, y: event.clientY });
    }

    window.addEventListener("mousemove", handleMove);
    return () => window.removeEventListener("mousemove", handleMove);
  }, [presentationCursor]);

  if (!presentationCursor) {
    return null;
  }

  return (
    <div
      className="pointer-events-none fixed z-[80] h-9 w-9 rounded-full border-2 border-primary/70 bg-primary/10 shadow-[0_0_0_10px_rgba(21,94,239,0.08)] transition-transform duration-75"
      style={{ left: position.x - 18, top: position.y - 18 }}
    />
  );
}

function ToggleRow({
  active,
  body,
  icon,
  onClick,
  title,
}: {
  active: boolean;
  body: string;
  icon: ReactNode;
  onClick: () => void;
  title: string;
}) {
  return (
    <button onClick={onClick} className="flex w-full items-start gap-3 rounded-[24px] border border-line bg-canvas px-4 py-3 text-left">
      <div className="mt-0.5 text-primary">{icon}</div>
      <div className="flex-1">
        <div className="flex items-center justify-between gap-3">
          <p className="font-medium text-ink">{title}</p>
          <Badge tone={active ? "success" : "neutral"}>{active ? "On" : "Off"}</Badge>
        </div>
        <p className="mt-1 text-sm text-muted">{body}</p>
      </div>
    </button>
  );
}
