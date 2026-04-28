import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export async function PATCH(req: Request, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  const admin = session?.user as any;
  if (!admin?.id || admin.role !== "ADMIN") return NextResponse.json({ message: "Forbidden" }, { status: 403 });

  const data = await req.json();
  if (typeof data.isActive !== "boolean") {
    return NextResponse.json({ message: "isActive boolean required" }, { status: 400 });
  }

  const user = await prisma.user.update({
    where: { id: params.id },
    data: { isActive: data.isActive }
  });

  return NextResponse.json({ id: user.id, isActive: user.isActive });
}
