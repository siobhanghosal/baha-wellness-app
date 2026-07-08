"use client";

import { useMemo, useState } from "react";
import { Download, MessageSquarePlus } from "lucide-react";
import { usePathname } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input, Textarea } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { getScreenByRoute } from "@/lib/screen-registry";
import { usePrototypeSettings } from "@/lib/prototype-store";

export function FeedbackPanel() {
  const [open, setOpen] = useState(false);
  const [comment, setComment] = useState("");
  const [feedbackRole, setFeedbackRole] = useState("Clinician");
  const [severity, setSeverity] = useState<"low" | "medium" | "high" | "critical">("medium");
  const pathname = usePathname();
  const { role, feedbackEntries, addFeedback, clearFeedback } = usePrototypeSettings();

  const activeScreen = useMemo(() => getScreenByRoute(pathname) ?? null, [pathname]);

  function submitFeedback() {
    if (!comment.trim()) return;
    addFeedback({
      screen: activeScreen?.name ?? "Demo Launcher",
      route: pathname,
      comment: comment.trim(),
      severity,
      role: feedbackRole,
    });
    setComment("");
    setFeedbackRole("Clinician");
    setSeverity("medium");
  }

  function exportFeedback() {
    const payload = JSON.stringify(feedbackEntries, null, 2);
    const blob = new Blob([payload], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = "baha-stakeholder-feedback.json";
    anchor.click();
    URL.revokeObjectURL(url);
  }

  return (
    <div className="fixed bottom-24 right-4 z-50">
      <Button size="lg" onClick={() => setOpen((value) => !value)}>
        <MessageSquarePlus className="mr-2 h-4 w-4" />
        Leave Feedback
      </Button>
      {open ? (
        <Card className="mt-3 w-[340px] space-y-4">
          <div className="space-y-2">
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-xs uppercase tracking-[0.18em] text-muted">Stakeholder notes</p>
                <h3 className="font-display text-xl font-semibold text-ink">Capture meeting feedback</h3>
              </div>
              <Badge tone="primary">{feedbackEntries.length}</Badge>
            </div>
            <p className="text-sm text-muted">Comments are stored locally and can be exported as JSON after the walkthrough.</p>
          </div>

          <div className="rounded-[24px] bg-canvas p-4 text-sm text-muted">
            <p>Screen: <span className="text-ink">{activeScreen?.name ?? "Demo Launcher"}</span></p>
            <p className="mt-1">Current route role: <span className="text-ink">{role === "baha" ? "Counselor / BAHA" : role}</span></p>
          </div>

          <div className="space-y-3">
            <Input value={activeScreen?.name ?? "Demo Launcher"} readOnly />
            <select value={feedbackRole} onChange={(event) => setFeedbackRole(event.target.value)} className="h-11 w-full rounded-2xl border border-line bg-canvas px-3 text-sm text-ink">
              {["Clinician", "Teacher", "Parent", "NGO Partner", "Investor", "Administrator"].map((label) => (
                <option key={label} value={label}>{label}</option>
              ))}
            </select>
            <div className="grid grid-cols-4 gap-2 rounded-[24px] bg-canvas p-1">
              {(["low", "medium", "high", "critical"] as const).map((level) => (
                <button
                  key={level}
                  onClick={() => setSeverity(level)}
                  className={`rounded-[20px] px-2 py-2 text-xs font-medium uppercase transition ${severity === level ? "bg-primary text-white" : "text-ink"}`}
                >
                  {level}
                </button>
              ))}
            </div>
            <Textarea value={comment} onChange={(event) => setComment(event.target.value)} placeholder="Add a clinician, teacher, parent, or investor comment..." />
          </div>

          <div className="grid grid-cols-2 gap-2">
            <Button variant="secondary" onClick={submitFeedback}>Save note</Button>
            <Button onClick={exportFeedback}>
              <Download className="mr-2 h-4 w-4" />
              Export JSON
            </Button>
          </div>

          {feedbackEntries.length ? (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <p className="text-sm font-medium text-ink">Recent feedback</p>
                <button onClick={clearFeedback} className="text-xs text-muted underline-offset-2 hover:underline">
                  Clear
                </button>
              </div>
              <div className="max-h-40 space-y-2 overflow-auto pr-1">
                {feedbackEntries.slice(0, 3).map((entry) => (
                  <div key={entry.id} className="rounded-[20px] bg-canvas p-3 text-sm">
                    <div className="flex items-center justify-between gap-2">
                      <p className="font-medium text-ink">{entry.screen}</p>
                      <Badge tone="warning">{entry.severity}</Badge>
                    </div>
                    <p className="mt-1 text-muted">{entry.comment}</p>
                  </div>
                ))}
              </div>
            </div>
          ) : null}
        </Card>
      ) : null}
    </div>
  );
}
