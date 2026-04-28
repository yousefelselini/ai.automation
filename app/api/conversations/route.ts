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
