import type { ReactNode } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Button } from "@/components/ui/button";

export function Dialog({
  open,
  title,
          description,
          onClose,
          children,
}: {
  open: boolean;
          title: string;
          description: string;
          onClose: () => void;
          children?: ReactNode;
        }) {
  return (
    <AnimatePresence>
      {open ? (
        <motion.div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4 backdrop-blur-sm" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
          <motion.div initial={{ opacity: 0, scale: 0.96 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.96 }} className="w-full max-w-md rounded-[28px] border border-line bg-card p-6 shadow-float">
            <h3 className="font-display text-xl font-semibold text-ink">{title}</h3>
            <p className="mt-2 text-sm text-muted">{description}</p>
            {children}
            <div className="mt-5 flex justify-end">
              <Button variant="secondary" onClick={onClose}>Close</Button>
            </div>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
}
