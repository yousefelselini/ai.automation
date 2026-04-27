import OpenAI from "openai";
import { env } from "./env";
function fallback(msg: string) {
  const t = msg.toLowerCase();
  if (t.includes("price")) return "We offer Starter, Growth, and Custom plans.";
  if (t.includes("whatsapp")) return "Yes, we automate WhatsApp conversations.";
  return "I can help with WhatsApp, Instagram, support, leads, and booking.";
}
export async function generateAIReply(message: string, systemPrompt = "You are Nile Automations assistant.") {
  if (!env.aiApiKey) return fallback(message);
  const client = new OpenAI({ apiKey: env.aiApiKey, baseURL: env.aiBaseUrl });
  const out = await client.chat.completions.create({
    model: env.aiModel,
    messages: [{ role: "system", content: systemPrompt }, { role: "user", content: message }]
  });
  return out.choices[0]?.message?.content || fallback(message);
}
