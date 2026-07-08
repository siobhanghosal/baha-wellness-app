"use client";

import type { ReactNode } from "react";
import { useEffect } from "react";
import { PrototypeProvider } from "@/lib/prototype-store";
import { PrototypeQueryProvider } from "@/lib/query-provider";
import { initMocks } from "@/lib/init-mocks";
import { DeveloperPanel } from "@/components/design-system/dev-panel";
import { PresentationControls } from "@/components/design-system/presentation-controls";
import { FeedbackPanel } from "@/components/design-system/feedback-panel";

export function Providers({ children }: { children: ReactNode }) {
  useEffect(() => {
    initMocks();
  }, []);

  return (
    <PrototypeQueryProvider>
      <PrototypeProvider>
        {children}
        <PresentationControls />
        <FeedbackPanel />
        <DeveloperPanel />
      </PrototypeProvider>
    </PrototypeQueryProvider>
  );
}
