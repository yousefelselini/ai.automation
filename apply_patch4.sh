#!/usr/bin/env bash
set -euo pipefail

mkdir -p app/api/admin/users/[id]

# ----------------------------------------------------
# 1) Prisma schema: add user activation + onboarding flags
# ----------------------------------------------------
python3 - <<'PY'
from pathlib import Path
p = Path("prisma/schema.prisma")
s = p.read_text()

if "isActive           Boolean" not in s:
    s = s.replace(
        "  image              String?\n",
        "  image              String?\n  isActive           Boolean              @default(true)\n"
    )

if "aiTested           Boolean" not in s and "model OnboardingProgress" in s:
    s = s.replace(
        "  paymentSubmitted   Boolean  @default(false)\n",
        "  paymentSubmitted   Boolean  @default(false)\n  aiTested           Boolean  @default(false)\n  planChosen         Boolean  @default(false)\n"
    )

p.write_text(s)
print("schema updated")
PY

# ----------------------------------------------------
# 2) Admin API to activate/deactivate users
# ----------------------------------------------------
cat > app/api/admin/users/[id]/route.ts <<'TS'
import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export async function PATCH(req: Request, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  const admin = session?.user as any;
  if (!admin?.id || admin.role !== "ADMIN") return NextResponse.json({ message: "Forbidden" }, { status: 403 });

  const data = await req.json();
  if (typeof data.isActive !== "boolean") {
    return NextResponse.json({ message: "isActive boolean required" }, { status: 400 });
  }

  const user = await prisma.user.update({
    where: { id: params.id },
    data: { isActive: data.isActive }
  });

  return NextResponse.json({ id: user.id, isActive: user.isActive });
}
TS

# ----------------------------------------------------
# 3) Onboarding API: persist aiTested / planChosen
# ----------------------------------------------------
cat > app/api/onboarding/route.ts <<'TS'
import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export async function GET() {
  const session = await getServerSession(authOptions);
  const userId = (session?.user as any)?.id;
  if (!userId) return NextResponse.json({}, { status: 401 });

  const onboarding = await prisma.onboardingProgress.findUnique({ where: { userId } });
  return NextResponse.json(onboarding ?? {});
}

export async function POST(req: Request) {
  const session = await getServerSession(authOptions);
  const userId = (session?.user as any)?.id;
  if (!userId) return NextResponse.json({ message: "Unauthorized" }, { status: 401 });

  const data = await req.json();
  const allDone = [
    data.businessProfileSet,
    data.aiConfigured,
    data.channelConnected,
    data.paymentSubmitted
  ].every(Boolean);

  await prisma.onboardingProgress.upsert({
    where: { userId },
    create: {
      userId,
      businessProfileSet: Boolean(data.businessProfileSet),
      aiConfigured: Boolean(data.aiConfigured),
      channelConnected: Boolean(data.channelConnected),
      paymentSubmitted: Boolean(data.paymentSubmitted),
      aiTested: Boolean(data.aiTested),
      planChosen: Boolean(data.planChosen),
      completedAt: allDone ? new Date() : null
    },
    update: {
      businessProfileSet: Boolean(data.businessProfileSet),
      aiConfigured: Boolean(data.aiConfigured),
      channelConnected: Boolean(data.channelConnected),
      paymentSubmitted: Boolean(data.paymentSubmitted),
      aiTested: Boolean(data.aiTested),
      planChosen: Boolean(data.planChosen),
      completedAt: allDone ? new Date() : null
    }
  });

  return NextResponse.json({ message: "Onboarding progress saved" });
}
TS

# ----------------------------------------------------
# 4) Conversations API: normalize requested statuses
# DB enum stays OPEN/HANDOFF/CLOSED
# ----------------------------------------------------
cat > app/api/conversations/route.ts <<'TS'
import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";

const incomingToDbStatus: Record<string, "OPEN" | "HANDOFF" | "CLOSED"> = {
  NEW: "OPEN",
  AI_HANDLING: "OPEN",
  NEEDS_HUMAN: "HANDOFF",
  CLOSED: "CLOSED",
  OPEN: "OPEN",
  HANDOFF: "HANDOFF"
};

const dbToViewStatus: Record<string, string> = {
  OPEN: "AI_HANDLING",
  HANDOFF: "NEEDS_HUMAN",
  CLOSED: "CLOSED"
};

export async function GET() {
  const session = await getServerSession(authOptions);
  const userId = (session?.user as any)?.id;
  if (!userId) return NextResponse.json([], { status: 401 });

  const rows = await prisma.conversation.findMany({
    where: { userId },
    include: { messages: { orderBy: { createdAt: "asc" }, take: 25 } },
    orderBy: { updatedAt: "desc" }
  });

  return NextResponse.json(
    rows.map((r) => ({ ...r, status: dbToViewStatus[r.status] || r.status }))
  );
}

export async function PATCH(req: Request) {
  const session = await getServerSession(authOptions);
  const userId = (session?.user as any)?.id;
  if (!userId) return NextResponse.json({ message: "Unauthorized" }, { status: 401 });

  const data = await req.json();
  if (!data.id) return NextResponse.json({ message: "Conversation id required" }, { status: 400 });

  const normalized = incomingToDbStatus[String(data.status || "").toUpperCase()] || "OPEN";

  const updated = await prisma.conversation.update({
    where: { id: data.id },
    data: {
      status: normalized,
      lastMessage: data.lastMessage
    }
  });

  return NextResponse.json({ ...updated, status: dbToViewStatus[updated.status] || updated.status });
}
TS

# ----------------------------------------------------
# 5) Admin page: users list + activate/deactivate buttons
# ----------------------------------------------------
cat > app/admin/page.tsx <<'TSX'
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import Link from "next/link";

async function toggleUser(id: string, isActive: boolean) {
  "use server";
  await fetch(`${process.env.NEXTAUTH_URL || "http://localhost:3000"}/api/admin/users/${id}`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ isActive }),
    cache: "no-store"
  }).catch(() => null);
}

export default async function AdminPage() {
  const session = await getServerSession(authOptions);
  if ((session?.user as any)?.role !== "ADMIN") return <main className="mx-auto max-w-3xl px-4 py-16">Access denied.</main>;

  const [usersCount, leads, bookings, subs, channels, convs, demos, pendingPayments, users] = await Promise.all([
    prisma.user.count(),
    prisma.lead.count(),
    prisma.bookingRequest.count(),
    prisma.subscription.count(),
    prisma.channelConnection.count(),
    prisma.conversation.count(),
    prisma.demoConversation.count(),
    prisma.manualPayment.findMany({ where: { status: "PENDING" }, orderBy: { createdAt: "desc" }, take: 30 }),
    prisma.user.findMany({ take: 30, orderBy: { createdAt: "desc" } })
  ]);

  return (
    <main className="mx-auto max-w-6xl px-4 py-16">
      <h1 className="text-3xl font-bold">Admin Dashboard</h1>

      <div className="mt-6 grid gap-4 md:grid-cols-3">
        {[["Users", usersCount], ["Leads", leads], ["Bookings", bookings], ["Subscriptions", subs], ["Channels", channels], ["Conversations", convs], ["Demo Chats", demos]].map(([label, val]) => (
          <div className="card p-4" key={String(label)}>
            <p className="text-sm text-[#6F665B]">{label}</p>
            <p className="text-xl font-semibold">{val as number}</p>
          </div>
        ))}
      </div>

      <section className="mt-8">
        <h2 className="text-xl font-semibold">Recent Users (Activate/Deactivate)</h2>
        <div className="mt-4 space-y-3">
          {users.map((u) => (
            <div className="card flex items-center justify-between gap-3 p-4" key={u.id}>
              <div>
                <p className="font-semibold">{u.name || "No name"}</p>
                <p className="text-sm text-[#6F665B]">{u.email}</p>
                <p className="text-xs text-[#6F665B]">Role: {u.role} • Active: {String((u as any).isActive ?? true)}</p>
              </div>
              <div className="flex gap-2">
                <form action={toggleUser.bind(null, u.id, true)}>
                  <button className="btn-secondary">Activate</button>
                </form>
                <form action={toggleUser.bind(null, u.id, false)}>
                  <button className="btn-secondary">Deactivate</button>
                </form>
              </div>
            </div>
          ))}
        </div>
      </section>

      <section className="mt-8">
        <h2 className="text-xl font-semibold">Pending Manual Payments</h2>
        <div className="mt-4 space-y-3">
          {pendingPayments.length === 0 && <p className="text-sm text-[#6F665B]">No pending requests.</p>}
          {pendingPayments.map((payment) => (
            <div className="card p-4" key={payment.id}>
              <p className="font-semibold">{payment.plan} — ${payment.amountUsd}</p>
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

echo "✅ Patch 4 applied."
