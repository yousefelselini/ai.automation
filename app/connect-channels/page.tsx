"use client";
import { useEffect, useState } from "react";

export default function ConnectChannelsPage() {
  const [msg, setMsg] = useState("");
  const [connected, setConnected] = useState(false);

  const refresh = async () => {
    const res = await fetch("/api/dashboard/stats");
    if (res.ok) {
      const data = await res.json();
      setConnected((data.connectedChannels || 0) > 0);
    }
  };

  useEffect(() => {
    refresh();
  }, []);

  const connectMock = async () => {
    const res = await fetch("/api/channels/mock-connect", { method: "POST" });
    const data = await res.json();
    setMsg(data.message);
    refresh();
  };

  return (
    <main className="mx-auto max-w-5xl px-4 py-16">
      <h1 className="text-3xl font-bold">Connect WhatsApp</h1>
      <p className="mt-2 text-[#6F665B]">Use sandbox mode first. Real Meta sending can be enabled later with keys.</p>

      <div className="mt-4 rounded-xl border border-[#E5DED3] bg-[#FFFDF8] p-4">
        <p className="text-sm">Current status: <span className={connected ? "font-semibold text-green-700" : "font-semibold text-[#6F665B]"}>{connected ? "Connected" : "Not connected"}</span></p>
      </div>

      <div className="mt-6 grid gap-4 md:grid-cols-2">
        <div className="card p-5">
          <h3 className="font-semibold">Meta OAuth (Production-ready path)</h3>
          <p className="mt-2 text-sm text-[#6F665B]">Connect a real WhatsApp Business account through Meta OAuth.</p>
          <a href="/api/meta/oauth/start?channel=whatsapp" className="btn-secondary mt-4">Start OAuth</a>
        </div>

        <div className="card p-5">
          <h3 className="font-semibold">Sandbox Mock Connect</h3>
          <p className="mt-2 text-sm text-[#6F665B]">Works without Meta keys and updates dashboard status.</p>
          <button className="btn-primary mt-4" onClick={connectMock}>Connect Sandbox</button>
        </div>
      </div>

      {msg && <p className="mt-3 text-sm text-[#6F665B]">{msg}</p>}
    </main>
  );
}
