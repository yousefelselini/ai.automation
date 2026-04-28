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
