import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

export function Badge({ children, tone = "neutral" }: { children: ReactNode; tone?: "neutral" | "primary" | "success" | "warning" | "danger" }) {
  const tones = {
    neutral: "bg-black/5 text-muted dark:bg-white/10 dark:text-white/80",
    primary: "bg-primary/10 text-primary",
    success: "bg-success/10 text-success",
    warning: "bg-warning/10 text-warning",
    danger: "bg-danger/10 text-danger",
  };
  return <span className={cn("inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold", tones[tone])}>{children}</span>;
}
