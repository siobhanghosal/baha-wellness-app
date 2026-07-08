"use client";

import type { ReactNode } from "react";
import { useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, ChevronRight, MoonStar, Sparkles } from "lucide-react";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { roleSwitcher, topNav } from "@/lib/prototype-config";
import type { ScreenMeta } from "@/lib/screen-registry";
import { cn } from "@/lib/utils";
import { usePrototypeSettings } from "@/lib/prototype-store";

export function PrototypeAppShell({
  screen,
  children,
  onOpenDialog,
  onOpenSheet,
}: {
  screen: ScreenMeta;
  children: ReactNode;
  onOpenDialog: () => void;
  onOpenSheet: () => void;
}) {
  const router = useRouter();
  const {
    role,
    ageGroup,
    theme,
    network,
    hideDebugLabels,
    setRole,
  } = usePrototypeSettings();
  const navItems = topNav[screen.role];
  const desktop = screen.role === "baha" || screen.role === "teacher";

  useEffect(() => {
    if (role !== screen.role) {
      setRole(screen.role);
    }
  }, [role, screen.role, setRole]);

  return (
    <div className="min-h-screen">
      <div className={cn("mx-auto flex min-h-screen max-w-[1600px]", desktop ? "gap-6 p-4 lg:p-6" : "justify-center px-3 py-4 sm:px-6")}>
        {desktop ? (
          <aside className="hidden w-72 shrink-0 lg:block">
            <Card className="sticky top-6 space-y-5">
              <div>
                <p className="text-xs uppercase tracking-[0.2em] text-muted">BAHA Prototype</p>
                <h1 className="mt-2 font-display text-2xl font-semibold text-ink">{screen.roleLabel}</h1>
              </div>
              <nav className="space-y-2">
                {navItems.map((item) => (
                  <Link
                    key={item.route}
                    href={item.route}
                    className={cn(
                      "flex items-center justify-between rounded-2xl px-4 py-3 text-sm text-muted transition hover:bg-black/5 hover:text-ink dark:hover:bg-white/5",
                      item.route === screen.route && "bg-primary text-white hover:text-white",
                    )}
                  >
                    <span>{item.label}</span>
                    <ChevronRight className="h-4 w-4" />
                  </Link>
                ))}
              </nav>
              <div className="rounded-3xl bg-black/5 p-4 dark:bg-white/5">
                <p className="text-sm font-medium text-ink">Prototype context</p>
                <div className="mt-3 flex flex-wrap gap-2">
                  <Badge tone="primary">{ageGroup}</Badge>
                  <Badge tone={network === "online" ? "success" : "warning"}>{network}</Badge>
                  <Badge tone="neutral">{theme}</Badge>
                </div>
              </div>
            </Card>
          </aside>
        ) : null}
        <div className={cn("flex min-h-[90vh] flex-col", desktop ? "flex-1" : "w-full max-w-md")}>
          <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="rounded-[32px] border border-line bg-card shadow-float">
            <header className="border-b border-line px-5 py-4">
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-start gap-3">
                  <button onClick={() => router.push(screen.previousRoute || `/${screen.role}`)} className="mt-1 inline-flex h-10 w-10 items-center justify-center rounded-full border border-line bg-canvas text-ink">
                    <ArrowLeft className="h-4 w-4" />
                  </button>
                  <div>
                    {!hideDebugLabels ? <p className="text-xs uppercase tracking-[0.18em] text-muted">{screen.id}</p> : null}
                    <h2 className="font-display text-2xl font-semibold text-ink">{screen.name}</h2>
                    <p className="mt-1 text-sm text-muted">{screen.pattern} · {screen.layout}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <Button variant="ghost" size="sm" onClick={onOpenSheet}>Quick actions</Button>
                  <Button variant="secondary" size="sm" onClick={onOpenDialog}>Info</Button>
                </div>
              </div>
              <div className="mt-4 flex flex-wrap gap-2">
                {!hideDebugLabels ? <Badge tone="primary">{screen.transition}</Badge> : null}
                <Badge tone="neutral">{screen.roleLabel}</Badge>
                {!hideDebugLabels ? <Badge tone={network === "online" ? "success" : "warning"}>{network}</Badge> : null}
                {theme === "dark" ? <Badge tone="neutral"><MoonStar className="mr-1 h-3 w-3" /> Dark</Badge> : null}
                <Badge tone="warning"><Sparkles className="mr-1 h-3 w-3" /> Calm Neo-Modern Care</Badge>
              </div>
              <div className="mt-4 flex flex-wrap gap-2">
                {roleSwitcher.map((item) => {
                  const destination = item.id === "baha" ? "/baha/splash" : `/${item.id}/splash`;
                  const active = (item.id === "baha" && screen.role === "baha") || item.id === screen.role;
                  return (
                    <Link
                      key={item.id}
                      href={destination}
                      className={cn(
                        "rounded-full border border-line px-3 py-2 text-xs font-medium transition",
                        active ? "bg-primary text-white" : "bg-canvas text-ink hover:bg-black/5 dark:hover:bg-white/5",
                      )}
                    >
                      {item.label}
                    </Link>
                  );
                })}
              </div>
            </header>
            <main className="min-h-[720px] bg-canvas/40 px-4 py-5 sm:px-5">{children}</main>
            {!desktop ? (
              <footer className="border-t border-line px-3 py-3">
                <div className="grid grid-cols-5 gap-2">
                  {navItems.map((item) => (
                    <Link
                      key={item.route}
                      href={item.route}
                      className={cn(
                        "rounded-2xl px-2 py-2 text-center text-xs transition",
                        item.route === screen.route ? "bg-primary text-white" : "text-muted hover:bg-black/5 dark:hover:bg-white/5",
                      )}
                    >
                      {item.label}
                    </Link>
                  ))}
                </div>
              </footer>
            ) : null}
          </motion.div>
        </div>
      </div>
    </div>
  );
}
