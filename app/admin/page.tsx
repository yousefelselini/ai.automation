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
