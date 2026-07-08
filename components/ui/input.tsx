import type { InputHTMLAttributes, TextareaHTMLAttributes } from "react";
import { cn } from "@/lib/utils";

export function Input(props: InputHTMLAttributes<HTMLInputElement>) {
  return <input {...props} className={cn("h-12 w-full rounded-2xl border border-line bg-canvas px-4 text-sm text-ink outline-none transition focus:border-primary", props.className)} />;
}

export function Textarea(props: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return <textarea {...props} className={cn("min-h-28 w-full rounded-3xl border border-line bg-canvas px-4 py-3 text-sm text-ink outline-none transition focus:border-primary", props.className)} />;
}
