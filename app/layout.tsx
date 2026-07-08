import type { ReactNode } from "react";
import "./globals.css";
import { Providers } from "@/app/providers";

export const metadata = {
  title: "BAHA Interactive Prototype",
  description: "Stakeholder review prototype generated from BAHA architecture documents.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
