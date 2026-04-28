"use client";
import { useEffect, useState } from "react";

export default function SettingsPage() {
  const [state, setState] = useState<any>({});
  const [msg, setMsg] = useState("");

  useEffect(() => {
    fetch("/api/automation-settings").then((r) => r.json()).then(setState);
  }, []);

  const save = async () => {
    const res = await fetch("/api/automation-settings", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(state)
    });
    const data = await res.json();
    setMsg(data.message || "Saved");
  };

  return (
    <main className="mx-auto max-w-3xl px-4 py-16">
      <h1 className="text-3xl font-bold">Settings</h1>
      <p className="mt-2 text-[#6F665B]">General account + automation toggles.</p>

      <div className="card mt-6 grid gap-3 p-5">
        <input className="input" placeholder="Business Name" value={state.businessName || ""} onChange={(e) => setState({ ...state, businessName: e.target.value })} />
        <input className="input" placeholder="Tone of Voice" value={state.toneOfVoice || ""} onChange={(e) => setState({ ...state, toneOfVoice: e.target.value })} />
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={state.automationEnabled ?? true} onChange={(e) => setState({ ...state, automationEnabled: e.target.checked })} />
          Automation enabled
        </label>
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={state.requireApprovalBeforeSend ?? false} onChange={(e) => setState({ ...state, requireApprovalBeforeSend: e.target.checked })} />
          Require human approval
        </label>

        <button className="btn-primary" onClick={save}>Save settings</button>
      </div>

      {msg && <p className="mt-3 text-sm text-[#6F665B]">{msg}</p>}
    </main>
  );
}
