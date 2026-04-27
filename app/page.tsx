import Link from "next/link";
export default function Home() {
  return <main className="mx-auto max-w-6xl px-4 py-16"><h1 className="text-4xl font-bold">Nile Automations</h1><p className="mt-3 text-muted">AI automation SaaS for local Egyptian brands.</p><div className="mt-6 flex gap-3"><Link href="/ai-demo" className="btn-primary">Try AI Demo</Link><Link href="/contact" className="btn-secondary">Book Call</Link></div></main>;
}
