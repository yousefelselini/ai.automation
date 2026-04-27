import type { Config } from "tailwindcss";
export default {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./lib/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        sand: "#F8F4ED",
        card: "#FFFDF8",
        beige: "#E8DCC8",
        accent: "#B89B72",
        ink: "#1F1F1F",
        muted: "#6F665B"
      },
      boxShadow: { soft: "0 10px 30px rgba(31,31,31,0.08)" }
    }
  },
  plugins: []
} satisfies Config;
