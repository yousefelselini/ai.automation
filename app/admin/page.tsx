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
