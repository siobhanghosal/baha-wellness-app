import { http, HttpResponse } from "msw";
import prototypeData from "@/mock-data/json/prototype-data.json";
import screens from "@/mock-data/generated/screens.json";
import translations from "@/mock-data/json/translations.json";

const wait = (ms = 220) => new Promise((resolve) => setTimeout(resolve, ms));

export const handlers = [
  http.get("/prototype-api/screens", async () => {
    await wait();
    return HttpResponse.json(screens);
  }),
  http.get("/prototype-api/role-data", async ({ request }) => {
    await wait();
    const url = new URL(request.url);
    const role = url.searchParams.get("role") || "student";
    const canonical = role === "counselor" ? "baha" : role;
    return HttpResponse.json((prototypeData as Record<string, unknown>)[canonical]);
  }),
  http.get("/prototype-api/translations", async () => {
    await wait(80);
    return HttpResponse.json(translations);
  }),
  http.post("/prototype-api/demo/seed", async () => {
    await wait(100);
    return HttpResponse.json({ ok: true, message: "Demo state refreshed" });
  }),
];
