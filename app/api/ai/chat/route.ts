import { NextResponse } from "next/server";
import { demoSchema } from "@/lib/validators";
import { prisma } from "@/lib/prisma";
import { generateAIReply } from "@/lib/ai";

export async function POST(req: Request) {
  const body = await req.json();
  const parsed = demoSchema.safeParse(body);
  if (!parsed.success) return NextResponse.json({ message: "Invalid input" }, { status: 400 });

  const conv = parsed.data.conversationId
    ? await prisma.demoConversation.findUnique({ where: { id: parsed.data.conversationId } })
    : await prisma.demoConversation.create({ data: {} });

  if (!conv) return NextResponse.json({ message: "Conversation not found" }, { status: 404 });

  await prisma.demoMessage.create({ data: { demoConversationId: conv.id, role: "user", content: parsed.data.message } });
  const reply = await generateAIReply(parsed.data.message, "You are Nile Automations assistant.");
  await prisma.demoMessage.create({ data: { demoConversationId: conv.id, role: "assistant", content: reply } });

  return NextResponse.json({ conversationId: conv.id, reply });
}
