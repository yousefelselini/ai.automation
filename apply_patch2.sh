#!/usr/bin/env bash
set -euo pipefail

# ---------------------------
# 1) Demo chat API (save/load)
# ---------------------------
cat > app/api/demo-chat/route.ts <<'TS'
import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export async function GET() {
  const session = await getServerSession(authOptions);
  const userId = (session?.user as any)?.id;
  if (!userId) return NextResponse.json([], { status: 401 });

  // Return last 20 demo conversations with messages
  const convs = await prisma.demoConversation.findMany({
    take: 20,
    orderBy: { createdAt: "desc" },
    include: { messages: { orderBy: { createdAt: "asc" } } }
  });

  return NextResponse.json(convs);
}

export async function POST(req: Request) {
  const session = await getServerSession(authOptions);
  const userId = (session?.user as any)?.id;
  if (!userId) return NextResponse.json({ message: "Unauthorized" }, { status: 401 });

  const body = await req.json();
  const conversationId = body?.conversationId as string | undefined;
  const role = body?.role as "user" | "assistant";
  const content = String(body?.content || "").trim();

  if (!role || !content) {
    return NextResponse.json({ message: "Invalid payload" }, { status: 400 });
  }

  let convId = conversationId;
  if (!convId) {
    const created = await prisma.demoConversation.create({ data: {} });
    convId = created.id;
  }

  await prisma.demoMessage.create({
    data: {
      demoConversationId: convId,
      role,
      content
    }
  });

  return NextResponse.json({ conversationId: convId });
}
TS

# ---------------------------
# 2) AI demo page with history
# ---------------------------
cat > app/ai-demo/page.tsx <<'TSX'
"use client";
import { useEffect, useState } from "react";

type Msg = { role: "user" | "assistant"; content: string };
type DemoConversation = { id: string; createdAt: string; messages: Msg[] };

export default function AIDemoPage() {
  const [messages, setMessages] = useState<Msg[]>([
    { role: "assistant", content: "Hi! I am your AI assistant. Ask me about setup, plans, or support flows." }
  ]);
  const [input, setInput] = useState("");
  const [conversationId, setConversationId] = useState<string | undefined>();
  const [loading, setLoading] = useState(false);
  const [history, setHistory] = useState<DemoConversation[]>([]);

  const loadHistory = async () => {
    const res = await fetch("/api/demo-chat");
    if (res.ok) setHistory(await res.json());
  };

  useEffect(() => {
    loadHistory();
  }, []);

  const persist = async (role: "user" | "assistant", content: string, currentConvId?: string) => {
    const res = await fetch("/api/demo-chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ role, content, conversationId: currentConvId })
    });
    if (!res.ok) return currentConvId;
    const data = await res.json();
    return data.conversationId as string;
  };

  const send = async (text: string) => {
    if (!text.trim()) return;
    setLoading(true);

    setMessages((m) => [...m, { role: "user", content: text }]);
    setInput("");

    let convId = await persist("user", text, conversationId);

    const res = await fetch("/api/ai/chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message: text, conversationId: convId })
    });
    const data = await res.json();

    convId = data.conversationId || convId;
    setConversationId(convId);
    setMessages((m) => [...m, { role: "assistant", content: data.reply }]);

    await persist("assistant", data.reply, convId);
    await loadHistory();

    setLoading(false);
  };

  return (
    <main className="mx-auto max-w-5xl px-4 py-16">
      <h1 className="text-3xl font-bold">Try Your AI Assistant</h1>
      <p className="mt-2 text-[#6F665B]">Test business-aware replies before enabling automation.</p>

      <div className="mt-6 grid gap-4 lg:grid-cols-[1fr_320px]">
        <div className="card p-4">
          <div className="space-y-3">
            {messages.map((m, i) => (
              <div key={i} className={m.role === "user" ? "text-right" : "text-left"}>
                <span className="inline-block rounded-xl border border-[#E5DED3] bg-white px-3 py-2 text-sm">{m.content}</span>
              </div>
            ))}
            {loading && <p className="text-sm text-[#6F665B]">Assistant is typing...</p>}
          </div>

          <div className="mt-4 flex gap-2">
            <input className="input" value={input} onChange={(e) => setInput(e.target.value)} placeholder="Type your message" />
            <button className="btn-primary" onClick={() => send(input)}>Send</button>
          </div>
        </div>

        <aside className="card p-4">
          <p className="font-semibold">Saved Test Chats</p>
          <div className="mt-3 space-y-2">
            {history.map((c) => (
              <button
                key={c.id}
                className="w-full rounded-lg border border-[#E5DED3] bg-white p-2 text-left text-xs hover:bg-[#f8f4ed]"
                onClick={() => {
                  setConversationId(c.id);
                  setMessages(c.messages.length ? c.messages : [{ role: "assistant", content: "New chat loaded." }]);
                }}
              >
                <p className="font-semibold">#{c.id.slice(-6)}</p>
                <p className="text-[#6F665B]">{new Date(c.createdAt).toLocaleString()}</p>
              </button>
            ))}
            {history.length === 0 && <p className="text-sm text-[#6F665B]">No saved chats yet.</p>}
          </div>
        </aside>
      </div>
    </main>
  );
}
TSX

# -----------------------------------
# 3) Billing page (manual details UI)
# -----------------------------------
cat > app/billing/page.tsx <<'TSX'
"use client";
import { useState } from "react";

export default function BillingPage() {
  const [form, setForm] = useState({
    plan: "Starter",
    paymentMethod: "InstaPay",
    amountUsd: "199",
    senderName: "",
    senderPhone: "",
    transactionRef: "",
    proofUrl: "",
    notes: ""
  });
  const [message, setMessage] = useState("");

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    const res = await fetch("/api/manual-payments", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ ...form, amountUsd: Number(form.amountUsd) })
    });
    const data = await res.json();
    setMessage(data.message || "Submitted");
  };

  return (
    <main className="mx-auto max-w-3xl px-4 py-16">
      <h1 className="text-3xl font-bold">Billing & Manual Payment</h1>
      <p className="mt-2 text-[#6F665B]">Submit payment proof using InstaPay / Vodafone Cash / Bank transfer.</p>

      <form className="card mt-6 grid gap-3 p-5" onSubmit={submit}>
        <select className="input" value={form.plan} onChange={(e) => setForm({ ...form, plan: e.target.value })}>
          <option>Starter</option>
          <option>Growth</option>
          <option>Custom</option>
        </select>

        <select className="input" value={form.paymentMethod} onChange={(e) => setForm({ ...form, paymentMethod: e.target.value })}>
          <option>InstaPay</option>
          <option>Vodafone Cash</option>
          <option>Bank transfer</option>
        </select>

        <input className="input" placeholder="Amount (USD)" value={form.amountUsd} onChange={(e) => setForm({ ...form, amountUsd: e.target.value })} />
        <input className="input" placeholder="Sender name" value={form.senderName} onChange={(e) => setForm({ ...form, senderName: e.target.value })} required />
        <input className="input" placeholder="Sender phone" value={form.senderPhone} onChange={(e) => setForm({ ...form, senderPhone: e.target.value })} required />
        <input className="input" placeholder="Transaction reference" value={form.transactionRef} onChange={(e) => setForm({ ...form, transactionRef: e.target.value })} required />
        <input className="input" placeholder="Screenshot URL" value={form.proofUrl} onChange={(e) => setForm({ ...form, proofUrl: e.target.value })} required />
        <textarea className="input" placeholder="Notes (optional)" value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} />

        <button className="btn-primary">Submit payment proof</button>
      </form>

      {message && <p className="mt-3 text-sm text-[#6F665B]">{message}</p>}
    </main>
  );
}
TSX

# ------------------------------------------
# 4) Admin page payment details visibility
# ------------------------------------------
cat > app/admin/page.tsx <<'TSX'
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import Link from "next/link";

export default async function AdminPage() {
  const session = await getServerSession(authOptions);
  if ((session?.user as any)?.role !== "ADMIN") return <main className="mx-auto max-w-3xl px-4 py-16">Access denied.</main>;

  const [users, leads, bookings, subs, channels, convs, demos, pendingPayments] = await Promise.all([
    prisma.user.count(),
    prisma.lead.count(),
    prisma.bookingRequest.count(),
    prisma.subscription.count(),
    prisma.channelConnection.count(),
    prisma.conversation.count(),
    prisma.demoConversation.count(),
    prisma.manualPayment.findMany({ where: { status: "PENDING" }, orderBy: { createdAt: "desc" }, take: 30 })
  ]);

  return (
    <main className="mx-auto max-w-6xl px-4 py-16">
      <h1 className="text-3xl font-bold">Admin Dashboard</h1>
      <div className="mt-6 grid gap-4 md:grid-cols-3">
        {[["Users", users], ["Leads", leads], ["Bookings", bookings], ["Subscriptions", subs], ["Channels", channels], ["Conversations", convs], ["Demo Chats", demos]].map(([label, val]) => (
          <div className="card p-4" key={String(label)}>
            <p className="text-sm text-[#6F665B]">{label}</p>
            <p className="text-xl font-semibold">{val as number}</p>
          </div>
        ))}
      </div>

      <section className="mt-8">
        <h2 className="text-xl font-semibold">Pending Manual Payments</h2>
        <div className="mt-4 space-y-3">
          {pendingPayments.length === 0 && <p className="text-sm text-[#6F665B]">No pending requests.</p>}
          {pendingPayments.map((payment) => (
            <div className="card p-4" key={payment.id}>
              <p className="font-semibold">{payment.plan} — ${payment.amountUsd}</p>
              <p className="text-sm text-[#6F665B]">Method: {payment.paymentMethod || "N/A"}</p>
              <p className="text-sm text-[#6F665B]">Sender: {payment.senderName || "N/A"} ({payment.senderPhone || "N/A"})</p>
              <p className="text-sm text-[#6F665B]">Ref: {payment.transactionRef || "N/A"}</p>
              <p className="text-sm text-[#6F665B]">Proof: {payment.proofUrl}</p>

              <div className="mt-3 flex gap-2">
                <Link href={`/api/admin/manual-payments/${payment.id}/approve?status=APPROVED`} className="btn-primary">Approve</Link>
                <Link href={`/api/admin/manual-payments/${payment.id}/approve?status=REJECTED`} className="btn-secondary">Reject</Link>
              </div>
            </div>
          ))}
        </div>
      </section>
    </main>
  );
}
TSX

echo "✅ Patch 2 applied."
