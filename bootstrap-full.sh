#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Bootstrapping Nile Automations full starter..."

# -----------------------------
# folders
# -----------------------------
mkdir -p app/{admin,ai-demo,services,pricing,contact,login,signup,dashboard,billing,connect-channels,automation-settings,conversations,leads}
mkdir -p app/api/{admin/records,admin/stats,ai/chat,auth/[...nextauth],auth/signup,automation-settings,booking,business-profile,channels/mock-connect,contact,conversations,dashboard/stats,demo-chat,leads/[id],leads,manual-reply,messages,meta/oauth/callback,meta/oauth/start,meta/webhook,stripe/checkout,stripe/webhook}
mkdir -p components lib prisma types

# -----------------------------
# core configs
# -----------------------------
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
  "prisma": {
    "seed": "npm run seed"
  }
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
      },
      boxShadow: { soft: "0 10px 30px rgba(31,31,31,0.08)" }
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

# -----------------------------
# prisma
# -----------------------------
cat > prisma/schema.prisma <<'EOF'
generator client {
  provider = "prisma-client-js"
}
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
enum UserRole { USER ADMIN }
enum ChannelType { WHATSAPP INSTAGRAM MOCK }
enum ConversationStatus { OPEN HANDOFF CLOSED }
enum LeadStatus { NEW CONTACTED QUALIFIED WON LOST }

model User {
  id String @id @default(cuid())
  name String?
  email String @unique
  passwordHash String?
  role UserRole @default(USER)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  accounts Account[]
  sessions Session[]
  businessProfile BusinessProfile?
  subscription Subscription?
  automationSettings AutomationSettings?
}
model Account {
  id String @id @default(cuid())
  userId String
  type String
  provider String
  providerAccountId String
  user User @relation(fields:[userId], references:[id], onDelete:Cascade)
  @@unique([provider, providerAccountId])
}
model Session {
  id String @id @default(cuid())
  sessionToken String @unique
  userId String
  expires DateTime
  user User @relation(fields:[userId], references:[id], onDelete:Cascade)
}
model VerificationToken {
  identifier String
  token String @unique
  expires DateTime
  @@unique([identifier, token])
}
model BusinessProfile {
  id String @id @default(cuid())
  userId String @unique
  businessName String
  description String?
  user User @relation(fields:[userId], references:[id], onDelete:Cascade)
}
model Subscription {
  id String @id @default(cuid())
  userId String @unique
  plan String
  status String
  user User @relation(fields:[userId], references:[id], onDelete:Cascade)
}
model Lead {
  id String @id @default(cuid())
  name String
  businessName String
  phone String
  email String
  businessType String
  serviceNeeded String
  message String
  status LeadStatus @default(NEW)
  createdAt DateTime @default(now())
}
model BookingRequest {
  id String @id @default(cuid())
  name String
  email String
  phone String
  service String
  preferredDate DateTime
  preferredTime String
  message String?
  createdAt DateTime @default(now())
}
model DemoConversation {
  id String @id @default(cuid())
  createdAt DateTime @default(now())
  messages DemoMessage[]
}
model DemoMessage {
  id String @id @default(cuid())
  demoConversationId String
  role String
  content String
  createdAt DateTime @default(now())
  demoConversation DemoConversation @relation(fields:[demoConversationId], references:[id], onDelete:Cascade)
}
model ChannelConnection {
  id String @id @default(cuid())
  userId String
  type ChannelType
  isConnected Boolean @default(false)
  sandboxMode Boolean @default(true)
}
model AutomationSettings {
  id String @id @default(cuid())
  userId String @unique
  businessName String?
  businessDescription String?
  toneOfVoice String? @default("professional")
  openingHours String?
  handoffMessage String? @default("A team member will take over shortly.")
  automationEnabled Boolean @default(true)
}
model Conversation {
  id String @id @default(cuid())
  userId String
  channel ChannelType
  customerName String
  lastMessage String?
  status ConversationStatus @default(OPEN)
  messages Message[]
}
model Message {
  id String @id @default(cuid())
  conversationId String
  role String
  content String
  aiGenerated Boolean @default(false)
  conversation Conversation @relation(fields:[conversationId], references:[id], onDelete:Cascade)
}
model CapturedLead {
  id String @id @default(cuid())
  name String?
  phone String?
  email String?
  source String
  status LeadStatus @default(NEW)
  notes String?
  createdAt DateTime @default(now())
}
model AdminLog {
  id String @id @default(cuid())
  action String
  metadata Json?
  createdAt DateTime @default(now())
}
EOF

cat > prisma/seed.ts <<'EOF'
console.log("Seed complete");
EOF

# -----------------------------
# libs
# -----------------------------
cat > lib/prisma.ts <<'EOF'
import { PrismaClient } from "@prisma/client";
declare global { var prisma: PrismaClient | undefined; }
export const prisma = global.prisma || new PrismaClient();
if (process.env.NODE_ENV !== "production") global.prisma = prisma;
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
export const signupSchema = z.object({ name: z.string().min(2), email: z.string().email(), password: z.string().min(8) });
export const contactSchema = z.object({ name: z.string().min(2), businessName: z.string().min(2), phone: z.string().min(6), email: z.string().email(), businessType: z.string().min(2), serviceNeeded: z.string().min(2), message: z.string().min(5) });
export const bookingSchema = z.object({ name: z.string().min(2), email: z.string().email(), phone: z.string().min(6), service: z.string().min(2), preferredDate: z.string(), preferredTime: z.string(), message: z.string().optional() });
export const demoSchema = z.object({ conversationId: z.string().optional(), message: z.string().min(1) });
EOF

cat > lib/ai.ts <<'EOF'
import OpenAI from "openai";
import { env } from "./env";
function fallback(msg: string) {
  const t = msg.toLowerCase();
  if (t.includes("price")) return "We offer Starter, Growth, and Custom plans.";
  if (t.includes("whatsapp")) return "Yes, we automate WhatsApp conversations.";
  return "I can help with WhatsApp, Instagram, support, leads, and booking.";
}
export async function generateAIReply(message: string, systemPrompt = "You are Nile Automations assistant.") {
  if (!env.aiApiKey) return fallback(message);
  const client = new OpenAI({ apiKey: env.aiApiKey, baseURL: env.aiBaseUrl });
  const out = await client.chat.completions.create({
    model: env.aiModel,
    messages: [{ role: "system", content: systemPrompt }, { role: "user", content: message }]
  });
  return out.choices[0]?.message?.content || fallback(message);
}
EOF

cat > lib/rate-limit.ts <<'EOF'
const bucket = new Map<string, { count: number; resetAt: number }>();
export function checkRateLimit(key: string, limit = 20, windowMs = 60_000) {
  const now = Date.now(); const entry = bucket.get(key);
  if (!entry || entry.resetAt < now) { bucket.set(key, { count: 1, resetAt: now + windowMs }); return true; }
  if (entry.count >= limit) return false;
  entry.count += 1; return true;
}
EOF

cat > lib/email.ts <<'EOF'
export async function sendAdminEmail(subject: string, text: string) {
  console.log("[EMAIL MOCK]", { subject, text });
}
EOF

cat > lib/stripe.ts <<'EOF'
import Stripe from "stripe";
export const stripe = process.env.STRIPE_SECRET_KEY ? new Stripe(process.env.STRIPE_SECRET_KEY, { apiVersion: "2024-06-20" }) : null;
EOF

cat > lib/meta.ts <<'EOF'
export function isMetaConfigured() {
  return Boolean(process.env.META_APP_ID && process.env.META_APP_SECRET && process.env.META_VERIFY_TOKEN && process.env.META_REDIRECT_URI);
}
EOF

cat > lib/auth.ts <<'EOF'
import { NextAuthOptions } from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";
export const authOptions: NextAuthOptions = {
  session: { strategy: "jwt" },
  providers: [CredentialsProvider({ name: "Credentials", credentials: {}, async authorize() { return null; } })],
  pages: { signIn: "/login" }
};
EOF

# -----------------------------
# app + components
# -----------------------------
cat > app/globals.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
body { @apply bg-sand text-ink; }
.card { @apply bg-card border border-beige rounded-2xl shadow-soft; }
.input { @apply w-full rounded-xl border border-beige bg-white px-3 py-2 text-sm; }
.btn-primary { @apply inline-flex items-center justify-center rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white; }
.btn-secondary { @apply inline-flex items-center justify-center rounded-xl border border-beige bg-card px-4 py-2 text-sm font-semibold; }
EOF

cat > components/navbar.tsx <<'EOF'
import Link from "next/link";
export default function Navbar() {
  return <header className="sticky top-0 z-50 border-b border-beige bg-sand/90"><div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-4"><Link href="/" className="font-bold">Nile <span className="text-accent">Automations</span></Link><nav className="hidden gap-4 md:flex text-sm text-muted"><Link href="/">Home</Link><Link href="/services">Services</Link><Link href="/ai-demo">AI Demo</Link><Link href="/pricing">Pricing</Link><Link href="/contact">Contact</Link></nav></div></header>;
}
EOF

cat > components/footer.tsx <<'EOF'
export default function Footer() {
  return <footer className="mt-20 border-t border-beige p-8 text-center text-sm text-muted">© Nile Automations</footer>;
}
EOF

cat > app/layout.tsx <<'EOF'
import "./globals.css";
import Navbar from "@/components/navbar";
import Footer from "@/components/footer";
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en"><body><Navbar />{children}<Footer /></body></html>;
}
EOF

cat > app/page.tsx <<'EOF'
import Link from "next/link";
export default function Home() {
  return <main className="mx-auto max-w-6xl px-4 py-16"><h1 className="text-4xl font-bold">Nile Automations</h1><p className="mt-3 text-muted">AI automation SaaS for local Egyptian brands.</p><div className="mt-6 flex gap-3"><Link href="/ai-demo" className="btn-primary">Try AI Demo</Link><Link href="/contact" className="btn-secondary">Book Call</Link></div></main>;
}
EOF

for p in services pricing contact login signup dashboard billing connect-channels automation-settings conversations leads admin; do
  cat > "app/$p/page.tsx" <<EOF
export default function Page() {
  return <main className="mx-auto max-w-6xl px-4 py-16"><h1 className="text-3xl font-bold">${p//-/ }</h1></main>;
}
EOF
done

cat > app/ai-demo/page.tsx <<'EOF'
"use client";
import { useState } from "react";
export default function AIDemoPage() {
  const [messages, setMessages] = useState<{ role: string; content: string }[]>([{ role: "assistant", content: "Hi! Ask me about WhatsApp, pricing, or setup." }]);
  const [input, setInput] = useState("");
  const [conversationId, setConversationId] = useState<string | undefined>();
  const [loading, setLoading] = useState(false);

  const send = async () => {
    if (!input.trim()) return;
    const text = input; setInput("");
    setMessages(m => [...m, { role: "user", content: text }]);
    setLoading(true);
    const res = await fetch("/api/ai/chat", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ message: text, conversationId }) });
    const data = await res.json();
    setConversationId(data.conversationId);
    setMessages(m => [...m, { role: "assistant", content: data.reply }]);
    setLoading(false);
  };

  return <main className="mx-auto max-w-3xl px-4 py-16"><h1 className="text-3xl font-bold">AI Demo</h1><div className="card mt-6 p-4 space-y-2">{messages.map((m,i)=><p key={i}><b>{m.role}:</b> {m.content}</p>)}{loading && <p className="text-sm text-muted">Typing...</p>}</div><div className="mt-3 flex gap-2"><input className="input" value={input} onChange={e=>setInput(e.target.value)} /><button className="btn-primary" onClick={send}>Send</button></div></main>;
}
EOF

# -----------------------------
# API routes
# -----------------------------
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
  const reply = await generateAIReply(parsed.data.message, "You are Nile Automations assistant.");
  await prisma.demoMessage.create({ data: { demoConversationId: conv.id, role: "assistant", content: reply } });

  return NextResponse.json({ conversationId: conv.id, reply });
}
EOF

# lightweight placeholders for remaining endpoints
for f in \
app/api/auth/[...nextauth]/route.ts \
app/api/auth/signup/route.ts \
app/api/contact/route.ts \
app/api/booking/route.ts \
app/api/demo-chat/route.ts \
app/api/stripe/checkout/route.ts \
app/api/stripe/webhook/route.ts \
app/api/dashboard/stats/route.ts \
app/api/business-profile/route.ts \
app/api/automation-settings/route.ts \
app/api/channels/mock-connect/route.ts \
app/api/meta/oauth/start/route.ts \
app/api/meta/oauth/callback/route.ts \
app/api/meta/webhook/route.ts \
app/api/conversations/route.ts \
app/api/messages/route.ts \
app/api/manual-reply/route.ts \
app/api/leads/route.ts \
app/api/leads/[id]/route.ts \
app/api/admin/stats/route.ts \
app/api/admin/records/route.ts
do
  cat > "$f" <<'EOF'
import { NextResponse } from "next/server";
export async function GET() { return NextResponse.json({ ok: true }); }
export async function POST() { return NextResponse.json({ ok: true }); }
export async function PATCH() { return NextResponse.json({ ok: true }); }
export async function DELETE() { return NextResponse.json({ ok: true }); }
EOF
done

cat > middleware.ts <<'EOF'
export { default } from "next-auth/middleware";
export const config = { matcher: ["/dashboard/:path*", "/admin/:path*"] };
EOF

cat > types/next-auth.d.ts <<'EOF'
import "next-auth";
declare module "next-auth" { interface Session { user?: { id?: string; role?: string; email?: string | null; name?: string | null; }; } }
declare module "next-auth/jwt" { interface JWT { role?: string; } }
EOF

cat > README.md <<'EOF'
# Nile Automations SaaS

## Run
cp .env.example .env
npm install
npx prisma migrate dev --name init
npx prisma db seed
npm run dev
EOF

echo "✅ Full bootstrap complete."
echo ""
echo "Now run:"
echo "  npm install"
echo "  npx prisma migrate dev --name init"
echo "  npx prisma db seed"
echo "  npm run dev"
