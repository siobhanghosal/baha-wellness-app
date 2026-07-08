export function Progress({ value }: { value: number }) {
  return (
    <div className="h-2 w-full rounded-full bg-black/5 dark:bg-white/10">
      <div className="h-2 rounded-full bg-primary transition-all duration-300" style={{ width: `${value}%` }} />
    </div>
  );
}
