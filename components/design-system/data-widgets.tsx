import { motion } from "framer-motion";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";

export function StatGrid({ items }: { items: { label: string; value: string | number; tone?: "neutral" | "primary" | "success" | "warning" | "danger" }[] }) {
  return (
    <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
      {items.map((item) => (
        <motion.div key={item.label} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }}>
          <Card>
            <p className="text-sm text-muted">{item.label}</p>
            <div className="mt-3 flex items-center justify-between">
              <p className="font-display text-2xl font-semibold text-ink">{item.value}</p>
              <Badge tone={item.tone ?? "primary"}>{item.tone ?? "live"}</Badge>
            </div>
          </Card>
        </motion.div>
      ))}
    </div>
  );
}

export function BarChart({ values, labelKey, valueKey }: { values: any[]; labelKey: string; valueKey: string }) {
  return (
    <Card className="space-y-4">
      <div>
        <h3 className="font-display text-lg font-semibold text-ink">Trend snapshot</h3>
        <p className="text-sm text-muted">Plain-language visual summaries with privacy-safe abstraction.</p>
      </div>
      <div className="space-y-3">
        {values.map((item) => (
          <div key={item[labelKey]} className="space-y-1">
            <div className="flex items-center justify-between text-sm">
              <span>{item[labelKey]}</span>
              <span className="text-muted">{item[valueKey]}</span>
            </div>
            <Progress value={typeof item[valueKey] === "number" ? item[valueKey] : Number(item[valueKey])} />
          </div>
        ))}
      </div>
    </Card>
  );
}

export function TimelineWidget({ events }: { events: { time: string; event: string }[] }) {
  return (
    <Card className="space-y-4">
      <h3 className="font-display text-lg font-semibold text-ink">Timeline</h3>
      <div className="space-y-4">
        {events.map((event, index) => (
          <div className="flex gap-3" key={`${event.time}-${index}`}>
            <div className="mt-1 h-2.5 w-2.5 rounded-full bg-primary" />
            <div>
              <p className="text-sm font-medium text-ink">{event.event}</p>
              <p className="text-xs text-muted">{event.time}</p>
            </div>
          </div>
        ))}
      </div>
    </Card>
  );
}

export function MessageList({ messages }: { messages: { id: string; author: string; text: string; citation?: string }[] }) {
  return (
    <div className="space-y-3">
      {messages.map((message) => (
        <motion.div key={message.id} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} className={`max-w-[90%] rounded-[24px] px-4 py-3 text-sm ${message.author === "user" ? "ml-auto bg-primary text-white" : "bg-card text-ink shadow-calm"}`}>
          <p>{message.text}</p>
          {message.citation ? <p className="mt-2 text-xs opacity-70">{message.citation}</p> : null}
        </motion.div>
      ))}
    </div>
  );
}
