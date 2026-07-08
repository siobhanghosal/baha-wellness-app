"use client";

import { usePrototypeRoleData } from "@/hooks/use-prototype-data";
import { PrototypeScreenRenderer } from "@/components/design-system/screen-renderer";
import { Card } from "@/components/ui/card";
import type { ScreenMeta } from "@/lib/screen-registry";

export function PrototypeScreenPage({ screen, roleScreens, role }: { screen: ScreenMeta; roleScreens: ScreenMeta[]; role: string }) {
  const { data, isLoading, isError, refetch } = usePrototypeRoleData(role);

  if (isLoading) {
    return (
      <main className="min-h-screen bg-canvas p-6">
        <div className="mx-auto max-w-5xl space-y-4">
          <Card className="h-40 animate-pulse bg-canvas" />
          <Card className="h-72 animate-pulse bg-canvas" />
        </div>
      </main>
    );
  }

  if (isError || !data) {
    return (
      <main className="min-h-screen bg-canvas p-6">
        <div className="mx-auto max-w-3xl">
          <Card className="space-y-4">
            <h1 className="font-display text-2xl font-semibold text-ink">Prototype data could not load</h1>
            <p className="text-sm text-muted">MSW mock data or local query bootstrapping did not complete in time for this route.</p>
            <div className="flex gap-3">
              <button onClick={() => refetch()} className="rounded-full bg-primary px-5 py-3 text-sm font-medium text-white">Retry</button>
            </div>
          </Card>
        </div>
      </main>
    );
  }

  return <PrototypeScreenRenderer screen={screen} roleData={data} roleScreens={roleScreens} />;
}
