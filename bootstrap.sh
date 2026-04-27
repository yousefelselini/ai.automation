#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Bootstrapping Nile Automations SaaS..."

mkdir -p app/{api,admin,ai-demo,services,pricing,contact,login,signup,dashboard,billing,connect-channels,automation-settings,conversations,leads}
mkdir -p app/api/{auth/[...nextauth],auth/signup,ai/chat,contact,booking,demo-chat,stripe/checkout,stripe/webhook,dashboard/stats,business-profile,automation-settings,channels/mock-connect,meta/oauth/start,meta/oauth/callback,meta/webhook,conversations,messages,manual-reply,leads/[id],leads,admin/stats,admin/records}
mkdir -p components lib prisma types

cat > package.json <<'EOF'
{
  "name": "nile-automations-saas",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "prisma generate && next build",
    "start": "next start",
    "seed": "tsx prisma/seed.ts"
  },
  "dependencies": {
    "@next-auth/prisma-adapter": "^1.0.7",
    "@prisma/client": "^5.22.0",
    "bcryptjs": "^2.4.3",
    "framer-motion": "^11.11.17",
    "next": "14.2.16",
    "next-auth": "^4.24.10",
    "nodemailer": "^6.9.15",
    "openai": "^4.73.1",
    "react": "18.3.1",
    "react-dom": "18.3.1",
    "stripe": "^17.2.1",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "@types/node": "20.16.10",
    "@types/react": "18.3.12",
    "@types/react-dom": "18.3.1",
    "autoprefixer": "10.4.20",
    "postcss": "8.4.47",
    "prisma": "^5.22.0",
    "tailwindcss": "3.4.14",
    "tsx": "^4.19.2",
    "typescript": "5.6.3"
  },
  "prisma": { "seed": "npm run seed" }
}
EOF

cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "strict": true,
    "noEmit": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "jsx": "preserve",
    "resolveJsonModule": true,
    "esModuleInterop": true,
    "paths": { "@/*": ["./*"] },
    "plugins": [{ "name": "next" }]
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

cat > next.config.mjs <<'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {};
export default nextConfig;
EOF

cat > postcss.config.js <<'EOF'
module.exports = { plugins: { tailwindcss: {}, autoprefixer: {} } };
EOF

cat > tailwind.config.ts <<'EOF'
import type { Config } from "tailwindcss";
export default {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./lib/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        sand: "#F8F4ED",
        card: "#FFFDF8",
        beige: "#E8DCC8",
        accent: "#B89B72",
        ink: "#1F1F1F",
        muted: "#6F665B"
      }
    }
  },
  plugins: []
} satisfies Config;
EOF

cat > next-env.d.ts <<'EOF'
/// <reference types="next" />
/// <reference types="next/image-types/global" />
EOF

cat > .env.example <<'EOF'
DATABASE_URL=
NEXTAUTH_SECRET=
NEXTAUTH_URL=
ADMIN_EMAIL=
ADMIN_PASSWORD=
EMAIL_SERVER_HOST=
EMAIL_SERVER_PORT=
EMAIL_SERVER_USER=
EMAIL_SERVER_PASSWORD=
EMAIL_FROM=
AI_API_KEY=
AI_BASE_URL=https://agentrouter.org/v1
AI_MODEL=deepseek-v3.1
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
STRIPE_STARTER_PRICE_ID=
STRIPE_GROWTH_PRICE_ID=
META_APP_ID=
META_APP_SECRET=
META_VERIFY_TOKEN=
META_REDIRECT_URI=
WHATSAPP_ACCESS_TOKEN=
WHATSAPP_PHONE_NUMBER_ID=
INSTAGRAM_BUSINESS_ACCOUNT_ID=
NEXT_PUBLIC_APP_URL=
EOF

cat > app/globals.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
body { @apply bg-sand text-ink; }
.card { @apply bg-card border border-beige rounded-2xl shadow-sm; }
.input { @apply w-full rounded-xl border border-beige bg-white px-3 py-2 text-sm; }
.btn-primary { @apply inline-flex items-center justify-center rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white; }
.btn-secondary { @apply inline-flex items-center justify-center rounded-xl border border-beige bg-card px-4 py-2 text-sm font-semibold; }
EOF

cat > app/layout.tsx <<'EOF'
import "./globals.css";
import Navbar from "@/components/navbar";
import Footer from "@/components/footer";
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en"><body><Navbar />{children}<Footer /></body></html>;
}
EOF

cat > components/navbar.tsx <<'EOF'
import Link from "next/link";
export default function Navbar() {
  return (
    <header className="sticky top-0 z-50 border-b border-beige bg-sand/90">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-4">
        <Link href="/" className="font-bold">Nile <span className="text-accent">Automations</span></Link>
        <nav className="hidden gap-4 md:flex text-sm text-muted">
          <Link href="/">Home</Link><Link href="/services">Services</Link><Link href="/ai-demo">AI Demo</Link><Link href="/pricing">Pricing</Link><Link href="/contact">Contact</Link>
        </nav>
      </div>
    </header>
  );
}
EOF

cat > components/footer.tsx <<'EOF'
export default function Footer() {
  return <footer className="mt-20 border-t border-beige p-8 text-sm text-muted text-center">© Nile Automations</footer>;
}
EOF

cat > app/page.tsx <<'EOF'
import Link from "next/link";
export default function HomePage() {
  return (
    <main className="mx-auto max-w-6xl px-4 py-16">
      <h1 className="text-4xl font-bold">Nile Automations</h1>
      <p className="mt-3 text-muted">AI automation SaaS for local Egyptian brands.</p>
      <div className="mt-6 flex gap-3">
        <Link href="/ai-demo" className="btn-primary">Try AI Demo</Link>
        <Link href="/contact" className="btn-secondary">Book Call</Link>
      </div>
    </main>
  );
}
EOF

cat > app/ai-demo/page.tsx <<'EOF'
"use client";
import { useState } from "react";
export default function AIDemoPage() {
  const [msgs, setMsgs] = useState<{role:string;content:string}[]>([{role:"assistant",content:"Hi! Ask me anything."}]);
  const [input, setInput] = useState("");
  const [conversationId, setConversationId] = useState<string|undefined>();
  const send = async () => {
    if (!input.trim()) return;
    setMsgs(m => [...m, { role:"user", content: input }]);
    const text = input; setInput("");
    const res = await fetch("/api/ai/chat", { method:"POST", headers:{ "Content-Type":"application/json" }, body: JSON.stringify({ message: text, conversationId }) });
    const data = await res.json();
    setConversationId(data.conversationId);
    setMsgs(m => [...m, { role:"assistant", content:data.reply }]);
  };
  return <main className="mx-auto max-w-3xl px-4 py-16"><h1 className="text-3xl font-bold">AI Demo</h1><div className="card mt-6 p-4 space-y-2">{msgs.map((m,i)=><p key={i}><b>{m.role}:</b> {m.content}</p>)}</div><div className="mt-3 flex gap-2"><input className="input" value={input} onChange={e=>setInput(e.target.value)} /><button className="btn-primary" onClick={send}>Send</button></div></main>;
}
EOF

cat > lib/env.ts <<'EOF'
export const env = {
  aiApiKey: process.env.AI_API_KEY,
  aiBaseUrl: process.env.AI_BASE_URL || "https://agentrouter.org/v1",
  aiModel: process.env.AI_MODEL || "deepseek-v3.1"
};
EOF

cat > lib/validators.ts <<'EOF'
import { z } from "zod";
export const demoSchema = z.object({ conversationId: z.string().optional(), message: z.string().min(1) });
EOF

cat > lib/prisma.ts <<'EOF'
import { PrismaClient } from "@prisma/client";
declare global { var prisma: PrismaClient | undefined; }
export const prisma = global.prisma || new PrismaClient();
if (process.env.NODE_ENV !== "production") global.prisma = prisma;
EOF

cat > lib/ai.ts <<'EOF'
import OpenAI from "openai";
import { env } from "./env";
export async function generateAIReply(message: string) {
  if (!env.aiApiKey) {
    const m = message.toLowerCase();
    if (m.includes("price")) return "We offer Starter, Growth, and Custom plans.";
    return "I can help with WhatsApp, Instagram, support, leads, and bookings.";
  }
  const client = new OpenAI({ apiKey: env.aiApiKey, baseURL: env.aiBaseUrl });
  const out = await client.chat.completions.create({
    model: env.aiModel,
    messages: [{ role:"system", content:"You are Nile Automations assistant." }, { role:"user", content: message }]
  });
  return out.choices[0]?.message?.content || "How can I help?";
}
EOF

cat > app/api/ai/chat/route.ts <<'EOF'
import { NextResponse } from "next/server";
import { demoSchema } from "@/lib/validators";
import { prisma } from "@/lib/prisma";
import { generateAIReply } from "@/lib/ai";

export async function POST(req: Request) {
  const body = await req.json();
  const parsed = demoSchema.safeParse(body);
  if (!parsed.success) return NextResponse.json({ message: "Invalid input" }, { status: 400 });

  const conv = parsed.data.conversationId
    ? await prisma.demoConversation.findUnique({ where: { id: parsed.data.conversationId } })
    : await prisma.demoConversation.create({ data: {} });

  if (!conv) return NextResponse.json({ message: "Conversation not found" }, { status: 404 });

  await prisma.demoMessage.create({ data: { demoConversationId: conv.id, role: "user", content: parsed.data.message } });
  const reply = await generateAIReply(parsed.data.message);
  await prisma.demoMessage.create({ data: { demoConversationId: conv.id, role: "assistant", content: reply } });

  return NextResponse.json({ conversationId: conv.id, reply });
}
EOF

cat > prisma/schema.prisma <<'EOF'
generator client { provider = "prisma-client-js" }
datasource db { provider = "postgresql"; url = env("DATABASE_URL") }

model DemoConversation {
  id        String      @id @default(cuid())
  createdAt DateTime    @default(now())
  messages  DemoMessage[]
}

model DemoMessage {
  id                 String @id @default(cuid())
  demoConversationId String
  role               String
  content            String
  createdAt          DateTime @default(now())
  demoConversation   DemoConversation @relation(fields:[demoConversationId], references:[id], onDelete:Cascade)
}
EOF

cat > prisma/seed.ts <<'EOF'
console.log("Seed complete");
EOF

cat > README.md <<'EOF'
# Nile Automations SaaS
## Setup
cp .env.example .env
npm install
npx prisma migrate dev --name init
npx prisma db seed
npm run dev
EOF

echo "✅ Bootstrap complete."
echo "Next:"
echo "1) npm install"
echo "2) npx prisma migrate dev --name init"
echo "3) npx prisma db seed"
echo "4) npm run dev"
