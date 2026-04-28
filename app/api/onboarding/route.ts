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
