import { NextAuthOptions } from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";
export const authOptions: NextAuthOptions = {
  session: { strategy: "jwt" },
  providers: [CredentialsProvider({ name: "Credentials", credentials: {}, async authorize() { return null; } })],
  pages: { signIn: "/login" }
};
