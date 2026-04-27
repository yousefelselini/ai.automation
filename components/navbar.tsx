import Link from "next/link";
export default function Navbar() {
  return <header className="sticky top-0 z-50 border-b border-beige bg-sand/90"><div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-4"><Link href="/" className="font-bold">Nile <span className="text-accent">Automations</span></Link><nav className="hidden gap-4 md:flex text-sm text-muted"><Link href="/">Home</Link><Link href="/services">Services</Link><Link href="/ai-demo">AI Demo</Link><Link href="/pricing">Pricing</Link><Link href="/contact">Contact</Link></nav></div></header>;
}
