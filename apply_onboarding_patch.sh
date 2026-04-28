#!/usr/bin/env bash
set -euo pipefail

mkdir -p app/onboarding app/api/onboarding

cat > app/onboarding/page.tsx <<'TSX'
"use client";
import Link from "next/link";
import { useEffect, useMemo, useState } from "react";

export default function OnboardingPage() {
  const [form, setForm] = useState({
    businessName: "", businessType: "", description: "",
    productsServicesText: "", faqsText: "", openingHours: "",
    deliveryInfo: "", toneOfVoice: "professional",
    handoffMessage: "A team member will take over shortly."
  });

  const [progress, setProgress] = useState({
    businessProfileSet: false, aiConfigured: false,
    channelConnected: false, paymentSubmitted: false
  });

  const [message, setMessage] = useState("");

  useEffect(() => {
    Promise.all([
      fetch("/api/onboarding").then(r => r.json()),
      fetch("/api/business-profile").then(r => r.json()).catch(() => ({})),
      fetch("/api/automation-settings").then(r => r.json()).catch(() => ({})),
    ]).then(([onb, profile, settings]) => {
      setProgress(prev => ({ ...prev, ...onb }));
      setForm(prev => ({
        ...prev,
        businessName: profile?.businessName || settings?.businessName || "",
        businessType: profile?.businessType || "",
        description: profile?.description || settings?.businessDescription || "",
        productsServicesText: Array.isArray(settings?.productsServices) ? settings.productsServices.join("\n") : "",
        faqsText: Array.isArray(settings?.faqs) ? settings.faqs.join("\n") : "",
        openingHours: settings?.openingHours || "",
        toneOfVoice: settings?.toneOfVoice || "professional",
        handoffMessage: settings?.handoffMessage || prev.handoffMessage
      }));
    });
  }, []);

  const completion = useMemo(() => {
    const vals = Object.values(progress);
    return Math.round((vals.filter(Boolean).length / vals.length) * 100);
  }, [progress]);

  const save = async () => {
    await fetch("/api/business-profile", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        businessName: form.businessName,
        businessType: form.businessType,
        description: form.description
      })
    });

    await fetch("/api/automation-settings", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        businessName: form.businessName,
        businessType: form.businessType,
        businessDescription: form.description,
        productsServices: form.productsServicesText.split("\n").map(x => x.trim()).filter(Boolean),
        faqs: form.faqsText.split("\n").map(x => x.trim()).filter(Boolean),
        openingHours: form.openingHours,
        toneOfVoice: form.toneOfVoice,
        handoffMessage: form.handoffMessage,
        deliveryInfo: form.deliveryInfo
      })
    });

    await fetch("/api/onboarding", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        businessProfileSet: true,
        aiConfigured: true,
        channelConnected: progress.channelConnected,
        paymentSubmitted: progress.paymentSubmitted
      })
    });

    setProgress(p => ({ ...p, businessProfileSet: true, aiConfigured: true }));
    setMessage("Onboarding details saved.");
  };

  return (
    <main className="mx-auto max-w-4xl px-4 py-16">
      <h1 className="text-3xl font-bold">Onboarding Wizard</h1>
      <p className="mt-2 text-[#6F665B]">Complete setup before activation.</p>

      <div className="card mt-4 p-4">
        <div className="flex items-center justify-between text-sm"><span>Completion</span><span>{completion}%</span></div>
        <div className="mt-2 h-2 rounded-full bg-[#E5DED3]"><div className="h-full rounded-full bg-[#B89B72]" style={{ width: `${completion}%` }} /></div>
      </div>

      <div className="card mt-6 grid gap-3 p-5">
        <input className="input" placeholder="Business name" value={form.businessName} onChange={(e) => setForm({ ...form, businessName: e.target.value })} />
        <input className="input" placeholder="Business type" value={form.businessType} onChange={(e) => setForm({ ...form, businessType: e.target.value })} />
        <textarea className="input min-h-20" placeholder="Business description" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
        <textarea className="input min-h-20" placeholder="Products/services (one per line)" value={form.productsServicesText} onChange={(e) => setForm({ ...form, productsServicesText: e.target.value })} />
        <textarea className="input min-h-20" placeholder="FAQs (one per line)" value={form.faqsText} onChange={(e) => setForm({ ...form, faqsText: e.target.value })} />
        <input className="input" placeholder="Opening hours" value={form.openingHours} onChange={(e) => setForm({ ...form, openingHours: e.target.value })} />
        <textarea className="input min-h-20" placeholder="Delivery/booking info" value={form.deliveryInfo} onChange={(e) => setForm({ ...form, deliveryInfo: e.target.value })} />
        <input className="input" placeholder="AI tone" value={form.toneOfVoice} onChange={(e) => setForm({ ...form, toneOfVoice: e.target.value })} />
        <textarea className="input min-h-20" placeholder="Handoff message" value={form.handoffMessage} onChange={(e) => setForm({ ...form, handoffMessage: e.target.value })} />
        <button className="btn-primary" onClick={save}>Save onboarding</button>
      </div>

      <div className="mt-6 grid gap-3 md:grid-cols-2">
        <Link href="/ai-demo" className="card p-4 hover:shadow-md">Test AI</Link>
        <Link href="/pricing" className="card p-4 hover:shadow-md">Choose plan</Link>
        <Link href="/billing" className="card p-4 hover:shadow-md">Upload payment proof</Link>
        <Link href="/dashboard" className="card p-4 hover:shadow-md">Open dashboard</Link>
      </div>

      {message && <p className="mt-3 text-sm text-[#6F665B]">{message}</p>}
    </main>
  );
}
TSX

cat > app/api/onboarding/route.ts <<'TS'
import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export async function GET() {
  const session = await getServerSession(authOptions);
  const userId = (session?.user as any)?.id;
  if (!userId) return NextResponse.json({}, { status: 401 });
  const row = await prisma.onboardingProgress.findUnique({ where: { userId } });
  return NextResponse.json(row || {});
}

export async function POST(req: Request) {
  const session = await getServerSession(authOptions);
  const userId = (session?.user as any)?.id;
  if (!userId) return NextResponse.json({ message: "Unauthorized" }, { status: 401 });

  const data = await req.json();
  const allDone = [
    Boolean(data.businessProfileSet),
    Boolean(data.aiConfigured),
    Boolean(data.channelConnected),
    Boolean(data.paymentSubmitted)
  ].every(Boolean);

  await prisma.onboardingProgress.upsert({
    where: { userId },
    create: {
      userId,
      businessProfileSet: Boolean(data.businessProfileSet),
      aiConfigured: Boolean(data.aiConfigured),
      channelConnected: Boolean(data.channelConnected),
      paymentSubmitted: Boolean(data.paymentSubmitted),
      completedAt: allDone ? new Date() : null
    },
    update: {
      businessProfileSet: Boolean(data.businessProfileSet),
      aiConfigured: Boolean(data.aiConfigured),
      channelConnected: Boolean(data.channelConnected),
      paymentSubmitted: Boolean(data.paymentSubmitted),
      completedAt: allDone ? new Date() : null
    }
  });

  return NextResponse.json({ message: "Onboarding progress saved" });
}
TS

# Navbar link (add only if missing)
if [ -f components/navbar.tsx ] && ! grep -q '/onboarding' components/navbar.tsx; then
  perl -0777 -i -pe 's/\[\"\/contact\", \"Contact\"\]/[\"\/contact\", \"Contact\"],\n  [\"\/onboarding\", \"Onboarding\"]/s' components/navbar.tsx || true
fi

echo "✅ Onboarding patch applied."
