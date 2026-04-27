"use client";
import { useState } from "react";
export default function AIDemoPage() {
  const [messages, setMessages] = useState<{ role: string; content: string }[]>([{ role: "assistant", content: "Hi! Ask me about WhatsApp, pricing, or setup." }]);
  const [input, setInput] = useState("");
  const [conversationId, setConversationId] = useState<string | undefined>();
  const [loading, setLoading] = useState(false);

  const send = async () => {
    if (!input.trim()) return;
    const text = input; setInput("");
    setMessages(m => [...m, { role: "user", content: text }]);
    setLoading(true);
    const res = await fetch("/api/ai/chat", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ message: text, conversationId }) });
    const data = await res.json();
    setConversationId(data.conversationId);
    setMessages(m => [...m, { role: "assistant", content: data.reply }]);
    setLoading(false);
  };

  return <main className="mx-auto max-w-3xl px-4 py-16"><h1 className="text-3xl font-bold">AI Demo</h1><div className="card mt-6 p-4 space-y-2">{messages.map((m,i)=><p key={i}><b>{m.role}:</b> {m.content}</p>)}{loading && <p className="text-sm text-muted">Typing...</p>}</div><div className="mt-3 flex gap-2"><input className="input" value={input} onChange={e=>setInput(e.target.value)} /><button className="btn-primary" onClick={send}>Send</button></div></main>;
}
