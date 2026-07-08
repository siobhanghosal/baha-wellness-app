import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./apps/**/*.{ts,tsx}",
    "./hooks/**/*.{ts,tsx}",
    "./lib/**/*.{ts,tsx}"
  ],
  darkMode: ["class", '[data-theme="dark"]'],
  theme: {
    extend: {
      colors: {
        canvas: "var(--color-canvas)",
        card: "var(--color-card)",
        ink: "var(--color-ink)",
        muted: "var(--color-muted)",
        line: "var(--color-line)",
        primary: "var(--color-primary)",
        support: "var(--color-support)",
        success: "var(--color-success)",
        warning: "var(--color-warning)",
        danger: "var(--color-danger)",
        info: "var(--color-info)"
      },
      borderRadius: {
        xl2: "1.5rem"
      },
      boxShadow: {
        calm: "0 8px 30px rgba(16,24,40,0.08)",
        float: "0 18px 60px rgba(21,94,239,0.18)"
      },
      fontFamily: {
        display: ["ui-rounded", "SF Pro Rounded", "Nunito Sans", "system-ui", "sans-serif"],
        body: ["Inter", "Segoe UI", "Arial", "sans-serif"],
        mono: ["ui-monospace", "SFMono-Regular", "monospace"]
      }
    },
  },
  plugins: [],
};

export default config;
