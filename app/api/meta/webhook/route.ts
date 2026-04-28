import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { env } from "@/lib/env";
import { generateAIReply } from "@/lib/ai";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const mode = searchParams.get("hub.mode");
  const token = searchParams.get("hub.verify_token");
  const challenge = searchParams.get("hub.challenge");

  if (mode === "subscribe" && token && token === env.metaVerifyToken) {
    return new NextResponse(challenge || "", { status: 200 });
  }

  return NextResponse.json({ message: "Verification failed" }, { status: 403 });
}

export async function POST(req: Request) {
  const body = await req.json();

  try {
    const entries = body?.entry || [];
    for (const entry of entries) {
      const changes = entry?.changes || [];
      for (const change of changes) {
        const value = change?.value;
        const messages = value?.messages || [];
        const phoneNumberId = value?.metadata?.phone_number_id;

        for (const incoming of messages) {
          const from = incoming?.from || "unknown";
          const text = incoming?.text?.body || "";
          if (!text) continue;

          // find channel by phone_number_id if available, otherwise fallback to any mock connected channel
          const channel = await prisma.channelConnection.findFirst({
            where: phoneNumberId
              ? { whatsappPhoneNumberId: phoneNumberId }
              : { type: "MOCK", isConnected: true },
            orderBy: { updatedAt: "desc" }
          });

          if (!channel) {
            console.log("[META MOCK] message received with no mapped channel", { from, text });
            continue;
          }

          let conversation = await prisma.conversation.findFirst({
            where: { userId: channel.userId, customerPhone: from },
            orderBy: { updatedAt: "desc" }
          });

          if (!conversation) {
            conversation = await prisma.conversation.create({
              data: {
                userId: channel.userId,
                channel: channel.type,
                customerName: `Customer ${from.slice(-4)}`,
                customerPhone: from,
                status: "OPEN",
                lastMessage: text
              }
            });
          } else {
            await prisma.conversation.update({
              where: { id: conversation.id },
              data: { lastMessage: text }
            });
          }

          await prisma.message.create({
            data: {
              conversationId: conversation.id,
              role: "user",
              content: text
            }
          });

          const [settings, profile] = await Promise.all([
            prisma.automationSettings.findUnique({ where: { userId: channel.userId } }),
            prisma.businessProfile.findUnique({ where: { userId: channel.userId } })
          ]);

          const reply = await generateAIReply({
            message: text,
            settings: {
              businessName: profile?.businessName || settings?.businessName,
              businessType: profile?.businessType,
              businessDescription: profile?.description || settings?.businessDescription,
              toneOfVoice: settings?.toneOfVoice,
              openingHours: settings?.openingHours,
              handoffMessage: settings?.handoffMessage,
              productsServices: settings?.productsServices,
              faqs: settings?.faqs,
              blockedWords: settings?.blockedWords
            }
          });

          await prisma.message.create({
            data: {
              conversationId: conversation.id,
              role: "assistant",
              content: reply,
              aiGenerated: true
            }
          });

          // If real WhatsApp token exists, here is where you'd call Graph API send endpoint.
          // For sandbox/no keys: log mock send.
          if (!env.whatsappToken || !env.whatsappPhoneId) {
            console.log("[META MOCK SEND]", { to: from, reply });
          } else {
            // Keep as non-breaking placeholder; can be replaced with actual POST to Meta Graph API.
            console.log("[META LIVE READY] would send reply using configured keys", { to: from });
          }
        }
      }
    }

    return NextResponse.json({ received: true });
  } catch (error) {
    console.error("[META WEBHOOK ERROR]", error);
    return NextResponse.json({ message: "Webhook processing failed" }, { status: 500 });
  }
}
