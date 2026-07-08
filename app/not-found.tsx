import Link from "next/link";
import { Button } from "@/components/ui/button";

export default function NotFound() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-canvas p-6">
      <div className="rounded-[32px] border border-line bg-card p-8 text-center shadow-float">
        <h1 className="font-display text-3xl font-semibold text-ink">Prototype route not found</h1>
        <p className="mt-3 text-sm text-muted">Try relaunching a documented role experience.</p>
        <div className="mt-6">
          <Link href="/"><Button>Back to launcher</Button></Link>
        </div>
      </div>
    </main>
  );
}
