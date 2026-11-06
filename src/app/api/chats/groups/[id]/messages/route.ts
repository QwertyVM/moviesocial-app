import { NextRequest, NextResponse } from "next/server";
import prisma from "@/lib/prisma";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: groupId } = await params;
    const { searchParams } = new URL(request.url);
    const after = searchParams.get("after");

    const whereClause: any = { groupId };
    if (after) {
      const parsedDate = new Date(after);
      if (!isNaN(parsedDate.getTime())) {
        whereClause.createdAt = { gt: parsedDate };
      }
    }

    const messages = await prisma.groupMessage.findMany({
      where: whereClause,
      orderBy: { createdAt: "asc" },
    });

    const formatted = messages.map((m) => ({
      id: m.id,
      groupId: m.groupId,
      senderId: m.userId,
      senderName: m.userName,
      text: m.text,
      messageType: (m.messageType as any) || "text",
      sharedMovieId: m.sharedMovieId || undefined,
      sharedMovieTitle: m.sharedMovieTitle || undefined,
      createdAt: m.createdAt ? m.createdAt.toISOString() : new Date().toISOString(),
    }));

    return NextResponse.json({
      messages: formatted,
      count: formatted.length,
      cursor: formatted.length > 0 ? formatted[formatted.length - 1].createdAt : after,
    });
  } catch (error: any) {
    console.error("GET /api/chats/groups/[id]/messages error:", error);
    return NextResponse.json(
      { error: error?.message || "Error al obtener mensajes del cineclub" },
      { status: 500 }
    );
  }
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: groupId } = await params;
    const body = await request.json();
    const {
      userId,
      userName,
      text,
      messageType = "text",
      sharedMovieId,
      sharedMovieTitle,
    } = body;

    if (!userId || !text?.trim()) {
      return NextResponse.json(
        { error: "userId y text son obligatorios" },
        { status: 400 }
      );
    }

    const sender = await prisma.user.findUnique({
      where: { id: userId },
    });

    // Regla: En Cineclubs de la Comunidad Global, participar activamente requiere Pro
    if (!sender?.isPremium) {
      return NextResponse.json(
        {
          error: "PREMIUM_REQUIRED",
          message:
            "Para participar y enviar mensajes en los Cineclubs de la comunidad abierta necesitas la membresía Cinéfilo Pro. En el Plan Base puedes chatear libremente 1 a 1 con tus amigos.",
          requiresPro: true,
        },
        { status: 403 }
      );
    }

    const created = await prisma.groupMessage.create({
      data: {
        id: `gmsg_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        groupId,
        userId,
        userName: userName || sender.displayName || "Cinéfilo Pro",
        text: text.trim(),
        messageType,
        sharedMovieId: sharedMovieId || null,
        sharedMovieTitle: sharedMovieTitle || null,
      },
    });

    // Actualizar conteo de mensajes en el grupo
    await prisma.movieGroup.update({
      where: { id: groupId },
      data: { messagesCount: { increment: 1 } },
    });

    return NextResponse.json({
      message: {
        id: created.id,
        groupId: created.groupId,
        senderId: created.userId,
        senderName: created.userName,
        text: created.text,
        messageType: (created.messageType as any) || "text",
        sharedMovieId: created.sharedMovieId || undefined,
        sharedMovieTitle: created.sharedMovieTitle || undefined,
        createdAt: created.createdAt
          ? created.createdAt.toISOString()
          : new Date().toISOString(),
      },
    });
  } catch (error: any) {
    console.error("POST /api/chats/groups/[id]/messages error:", error);
    return NextResponse.json(
      { error: error?.message || "Error al enviar mensaje al cineclub" },
      { status: 500 }
    );
  }
}
