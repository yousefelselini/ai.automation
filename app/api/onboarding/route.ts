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
