import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export async function GET() {
  const session = await getServerSession(authOptions);
  const userId = (session?.user as any)?.id;
  if (!userId) return NextResponse.json([], { status: 401 });

  // Return last 20 demo conversations with messages
  const convs = await prisma.demoConversation.findMany({
    take: 20,
    orderBy: { createdAt: "desc" },
    include: { messages: { orderBy: { createdAt: "asc" } } }
  });

  return NextResponse.json(convs);
}

export async function POST(req: Request) {
  const session = await getServerSession(authOptions);
  const userId = (session?.user as any)?.id;
  if (!userId) return NextResponse.json({ message: "Unauthorized" }, { status: 401 });

  const body = await req.json();
  const conversationId = body?.conversationId as string | undefined;
  const role = body?.role as "user" | "assistant";
  const content = String(body?.content || "").trim();

  if (!role || !content) {
    return NextResponse.json({ message: "Invalid payload" }, { status: 400 });
  }

  let convId = conversationId;
  if (!convId) {
    const created = await prisma.demoConversation.create({ data: {} });
    convId = created.id;
  }

  await prisma.demoMessage.create({
    data: {
      demoConversationId: convId,
      role,
      content
    }
  });

  return NextResponse.json({ conversationId: convId });
}
