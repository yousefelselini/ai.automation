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
