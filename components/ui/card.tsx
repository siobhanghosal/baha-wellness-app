import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

export function Card({ className, children }: { className?: string; children?: ReactNode }) {
  return <div className={cn("rounded-[24px] border border-line bg-card p-5 shadow-calm", className)}>{children}</div>;
}
