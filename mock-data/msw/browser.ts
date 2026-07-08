import { setupWorker } from "msw/browser";
import { handlers } from "@/mock-data/msw/handlers";

export const worker = setupWorker(...handlers);
