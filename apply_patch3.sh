#!/usr/bin/env bash
set -euo pipefail

mkdir -p app/settings

# ---------------------------------------------------------
# 1) Meta webhook: verify + receive message + AI/mock reply
# ---------------------------------------------------------
cat > app/api/meta/webhook/route.ts <<'TS'
import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { env } from "@/lib/env";
import { generateAIReply } from "@/lib/ai";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const mode = searchParams.get("hub.mode");
  const token = searchParams.get("hub.verify_token");
  const challenge = searchParams.get("hub.challenge");

  if (mode === "subscribe" && token && token === env.metaVerifyToken) {
    return new NextResponse(challenge || "", { status: 200 });
  }

  return NextResponse.json({ message: "Verification failed" }, { status: 403 });
}

export async function POST(req: Request) {
  const body = await req.json();

  try {
    const entries = body?.entry || [];
    for (const entry of entries) {
      const changes = entry?.changes || [];
      for (const change of changes) {
        const value = change?.value;
        const messages = value?.messages || [];
        const phoneNumberId = value?.metadata?.phone_number_id;

        for (const incoming of messages) {
          const from = incoming?.from || "unknown";
          const text = incoming?.text?.body || "";
          if (!text) continue;

          // find channel by phone_number_id if available, otherwise fallback to any mock connected channel
          const channel = await prisma.channelConnection.findFirst({
            where: phoneNumberId
              ? { whatsappPhoneNumberId: phoneNumberId }
              : { type: "MOCK", isConnected: true },
            orderBy: { updatedAt: "desc" }
          });

          if (!channel) {
            console.log("[META MOCK] message received with no mapped channel", { from, text });
            continue;
          }

          let conversation = await prisma.conversation.findFirst({
            where: { userId: channel.userId, customerPhone: from },
            orderBy: { updatedAt: "desc" }
          });

          if (!conversation) {
            conversation = await prisma.conversation.create({
              data: {
                userId: channel.userId,
                channel: channel.type,
                customerName: `Customer ${from.slice(-4)}`,
                customerPhone: from,
                status: "OPEN",
                lastMessage: text
              }
            });
          } else {
            await prisma.conversation.update({
              where: { id: conversation.id },
              data: { lastMessage: text }
            });
          }

          await prisma.message.create({
            data: {
              conversationId: conversation.id,
              role: "user",
              content: text
            }
          });

          const [settings, profile] = await Promise.all([
            prisma.automationSettings.findUnique({ where: { userId: channel.userId } }),
            prisma.businessProfile.findUnique({ where: { userId: channel.userId } })
          ]);

          const reply = await generateAIReply({
            message: text,
            settings: {
              businessName: profile?.businessName || settings?.businessName,
              businessType: profile?.businessType,
              businessDescription: profile?.description || settings?.businessDescription,
              toneOfVoice: settings?.toneOfVoice,
              openingHours: settings?.openingHours,
              handoffMessage: settings?.handoffMessage,
              productsServices: settings?.productsServices,
              faqs: settings?.faqs,
              blockedWords: settings?.blockedWords
            }
          });

          await prisma.message.create({
            data: {
              conversationId: conversation.id,
              role: "assistant",
              content: reply,
              aiGenerated: true
            }
          });

          // If real WhatsApp token exists, here is where you'd call Graph API send endpoint.
          // For sandbox/no keys: log mock send.
          if (!env.whatsappToken || !env.whatsappPhoneId) {
            console.log("[META MOCK SEND]", { to: from, reply });
          } else {
            // Keep as non-breaking placeholder; can be replaced with actual POST to Meta Graph API.
            console.log("[META LIVE READY] would send reply using configured keys", { to: from });
          }
        }
      }
    }

    return NextResponse.json({ received: true });
  } catch (error) {
    console.error("[META WEBHOOK ERROR]", error);
    return NextResponse.json({ message: "Webhook processing failed" }, { status: 500 });
  }
}
TS

# ---------------------------------------------------------
# 2) Idempotent mock connect route
# ---------------------------------------------------------
cat > app/api/channels/mock-connect/route.ts <<'TS'
import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";

export async function POST() {
  const session = await getServerSession(authOptions);
  const userId = (session?.user as any)?.id;
  if (!userId) return NextResponse.json({ message: "Unauthorized" }, { status: 401 });

  const existing = await prisma.channelConnection.findFirst({
    where: { userId, type: "MOCK", isConnected: true }
  });

  if (!existing) {
    await prisma.channelConnection.create({
      data: { userId, type: "MOCK", isConnected: true, sandboxMode: true }
    });
  }

  await prisma.onboardingProgress.upsert({
    where: { userId },
    create: { userId, channelConnected: true },
    update: { channelConnected: true }
  });

  return NextResponse.json({ message: "WhatsApp sandbox connected successfully" });
}
TS

# ---------------------------------------------------------
# 3) Connect channels page with live status check
# ---------------------------------------------------------
cat > app/connect-channels/page.tsx <<'TSX'
"use client";
import { useEffect, useState } from "react";

export default function ConnectChannelsPage() {
  const [msg, setMsg] = useState("");
  const [connected, setConnected] = useState(false);

  const refresh = async () => {
    const res = await fetch("/api/dashboard/stats");
    if (res.ok) {
      const data = await res.json();
      setConnected((data.connectedChannels || 0) > 0);
    }
  };

  useEffect(() => {
    refresh();
  }, []);

  const connectMock = async () => {
    const res = await fetch("/api/channels/mock-connect", { method: "POST" });
    const data = await res.json();
    setMsg(data.message);
    refresh();
  };

  return (
    <main className="mx-auto max-w-5xl px-4 py-16">
      <h1 className="text-3xl font-bold">Connect WhatsApp</h1>
      <p className="mt-2 text-[#6F665B]">Use sandbox mode first. Real Meta sending can be enabled later with keys.</p>

      <div className="mt-4 rounded-xl border border-[#E5DED3] bg-[#FFFDF8] p-4">
        <p className="text-sm">Current status: <span className={connected ? "font-semibold text-green-700" : "font-semibold text-[#6F665B]"}>{connected ? "Connected" : "Not connected"}</span></p>
      </div>

      <div className="mt-6 grid gap-4 md:grid-cols-2">
        <div className="card p-5">
          <h3 className="font-semibold">Meta OAuth (Production-ready path)</h3>
          <p className="mt-2 text-sm text-[#6F665B]">Connect a real WhatsApp Business account through Meta OAuth.</p>
          <a href="/api/meta/oauth/start?channel=whatsapp" className="btn-secondary mt-4">Start OAuth</a>
        </div>

        <div className="card p-5">
          <h3 className="font-semibold">Sandbox Mock Connect</h3>
          <p className="mt-2 text-sm text-[#6F665B]">Works without Meta keys and updates dashboard status.</p>
          <button className="btn-primary mt-4" onClick={connectMock}>Connect Sandbox</button>
        </div>
      </div>

      {msg && <p className="mt-3 text-sm text-[#6F665B]">{msg}</p>}
    </main>
  );
}
TSX

# ---------------------------------------------------------
# 4) Settings page
# ---------------------------------------------------------
cat > app/settings/page.tsx <<'TSX'
"use client";
import { useEffect, useState } from "react";

export default function SettingsPage() {
  const [state, setState] = useState<any>({});
  const [msg, setMsg] = useState("");

  useEffect(() => {
    fetch("/api/automation-settings").then((r) => r.json()).then(setState);
  }, []);

  const save = async () => {
    const res = await fetch("/api/automation-settings", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(state)
    });
    const data = await res.json();
    setMsg(data.message || "Saved");
  };

  return (
    <main className="mx-auto max-w-3xl px-4 py-16">
      <h1 className="text-3xl font-bold">Settings</h1>
      <p className="mt-2 text-[#6F665B]">General account + automation toggles.</p>

      <div className="card mt-6 grid gap-3 p-5">
        <input className="input" placeholder="Business Name" value={state.businessName || ""} onChange={(e) => setState({ ...state, businessName: e.target.value })} />
        <input className="input" placeholder="Tone of Voice" value={state.toneOfVoice || ""} onChange={(e) => setState({ ...state, toneOfVoice: e.target.value })} />
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={state.automationEnabled ?? true} onChange={(e) => setState({ ...state, automationEnabled: e.target.checked })} />
          Automation enabled
        </label>
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={state.requireApprovalBeforeSend ?? false} onChange={(e) => setState({ ...state, requireApprovalBeforeSend: e.target.checked })} />
          Require human approval
        </label>

        <button className="btn-primary" onClick={save}>Save settings</button>
      </div>

      {msg && <p className="mt-3 text-sm text-[#6F665B]">{msg}</p>}
    </main>
  );
}
TSX

echo "✅ Patch 3 applied."
