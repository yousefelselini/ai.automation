"use client";
import { useEffect, useState } from "react";

type Msg = { role: "user" | "assistant"; content: string };
type DemoConversation = { id: string; createdAt: string; messages: Msg[] };

export default function AIDemoPage() {
  const [messages, setMessages] = useState<Msg[]>([
    { role: "assistant", content: "Hi! I am your AI assistant. Ask me about setup, plans, or support flows." }
  ]);
  const [input, setInput] = useState("");
  const [conversationId, setConversationId] = useState<string | undefined>();
  const [loading, setLoading] = useState(false);
  const [history, setHistory] = useState<DemoConversation[]>([]);

  const loadHistory = async () => {
    const res = await fetch("/api/demo-chat");
    if (res.ok) setHistory(await res.json());
  };

  useEffect(() => {
    loadHistory();
  }, []);

  const persist = async (role: "user" | "assistant", content: string, currentConvId?: string) => {
    const res = await fetch("/api/demo-chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ role, content, conversationId: currentConvId })
    });
    if (!res.ok) return currentConvId;
    const data = await res.json();
    return data.conversationId as string;
  };

  const send = async (text: string) => {
    if (!text.trim()) return;
    setLoading(true);

    setMessages((m) => [...m, { role: "user", content: text }]);
    setInput("");

    let convId = await persist("user", text, conversationId);

    const res = await fetch("/api/ai/chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message: text, conversationId: convId })
    });
    const data = await res.json();

    convId = data.conversationId || convId;
    setConversationId(convId);
    setMessages((m) => [...m, { role: "assistant", content: data.reply }]);

    await persist("assistant", data.reply, convId);
    await loadHistory();

    setLoading(false);
  };

  return (
    <main className="mx-auto max-w-5xl px-4 py-16">
      <h1 className="text-3xl font-bold">Try Your AI Assistant</h1>
      <p className="mt-2 text-[#6F665B]">Test business-aware replies before enabling automation.</p>

      <div className="mt-6 grid gap-4 lg:grid-cols-[1fr_320px]">
        <div className="card p-4">
          <div className="space-y-3">
            {messages.map((m, i) => (
              <div key={i} className={m.role === "user" ? "text-right" : "text-left"}>
                <span className="inline-block rounded-xl border border-[#E5DED3] bg-white px-3 py-2 text-sm">{m.content}</span>
              </div>
            ))}
            {loading && <p className="text-sm text-[#6F665B]">Assistant is typing...</p>}
          </div>

          <div className="mt-4 flex gap-2">
            <input className="input" value={input} onChange={(e) => setInput(e.target.value)} placeholder="Type your message" />
            <button className="btn-primary" onClick={() => send(input)}>Send</button>
          </div>
        </div>

        <aside className="card p-4">
          <p className="font-semibold">Saved Test Chats</p>
          <div className="mt-3 space-y-2">
            {history.map((c) => (
              <button
                key={c.id}
                className="w-full rounded-lg border border-[#E5DED3] bg-white p-2 text-left text-xs hover:bg-[#f8f4ed]"
                onClick={() => {
                  setConversationId(c.id);
                  setMessages(c.messages.length ? c.messages : [{ role: "assistant", content: "New chat loaded." }]);
                }}
              >
                <p className="font-semibold">#{c.id.slice(-6)}</p>
                <p className="text-[#6F665B]">{new Date(c.createdAt).toLocaleString()}</p>
              </button>
            ))}
            {history.length === 0 && <p className="text-sm text-[#6F665B]">No saved chats yet.</p>}
          </div>
        </aside>
      </div>
    </main>
  );
}
