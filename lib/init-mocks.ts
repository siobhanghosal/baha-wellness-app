let started = false;

export async function initMocks() {
  if (started || typeof window === "undefined") return;
  try {
    const { worker } = await import("@/mock-data/msw/browser");
    await worker.start({ onUnhandledRequest: "bypass" });
    started = true;
  } catch {
    started = true;
  }
}
