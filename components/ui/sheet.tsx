import type { ReactNode } from "react";
import { AnimatePresence, motion } from "framer-motion";

export function Sheet({
  open,
          onClose,
          title,
          children,
}: {
          open: boolean;
          onClose: () => void;
          title: string;
          children: ReactNode;
        }) {
  return (
    <AnimatePresence>
      {open ? (
        <motion.div className="fixed inset-0 z-40 bg-black/25" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={onClose}>
          <motion.div className="absolute bottom-0 left-0 right-0 rounded-t-[32px] border border-line bg-card p-6 shadow-float" initial={{ y: 320 }} animate={{ y: 0 }} exit={{ y: 320 }} transition={{ duration: 0.24 }} onClick={(event) => event.stopPropagation()}>
            <div className="mx-auto mb-4 h-1.5 w-14 rounded-full bg-black/10 dark:bg-white/10" />
            <h3 className="font-display text-lg font-semibold text-ink">{title}</h3>
            <div className="mt-4">{children}</div>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
}
