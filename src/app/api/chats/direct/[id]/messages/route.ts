import { NextRequest, NextResponse } from "next/server";
import prisma from "@/lib/prisma";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: conversationId } = await params;
    const { searchParams } = new URL(request.url);
    const after = searchParams.get("after");

    const whereClause: any = { conversationId };
    if (after) {
      const parsedDate = new Date(after);
      if (!isNaN(parsedDate.getTime())) {
        whereClause.createdAt = { gt: parsedDate };
      }
    }

    const messages = await prisma.directMessage.findMany({
      where: whereClause,
      orderBy: { createdAt: "asc" },
    });

    const formatted = messages.map((m) => ({
      id: m.id,
      conversationId: m.conversationId,
      senderId: m.senderId,
      senderName: m.senderName,
      senderAvatarUrl: m.senderAvatarUrl || undefined,
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
    console.error("GET /api/chats/direct/[id]/messages error:", error);
    return NextResponse.json(
      { error: error?.message || "Error al cargar mensajes directos" },
      { status: 500 }
    );
  }
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: conversationId } = await params;
    const body = await request.json();
    const {
      senderId,
      senderName,
      senderAvatarUrl,
      recipientId,
      text,
      messageType = "text",
      sharedMovieId,
      sharedMovieTitle,
    } = body;

    if (!senderId || !text?.trim()) {
      return NextResponse.json(
        { error: "senderId y text son obligatorios" },
        { status: 400 }
      );
    }

    // Asegurar que la conversación exista
    let conversation = await prisma.directConversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      conversation = await prisma.directConversation.create({
        data: {
          id: conversationId,
          participantId: recipientId || "external_user",
          unreadCount: 0,
          updatedAt: new Date(),
        },
      });
    }

    const msgId = `dmsg_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const created = await prisma.directMessage.create({
      data: {
        id: msgId,
        conversationId,
        senderId,
        senderName: senderName || "Usuario",
        senderAvatarUrl: senderAvatarUrl || null,
        recipientId: recipientId || conversation.participantId,
        text: text.trim(),
        messageType,
        sharedMovieId: sharedMovieId || null,
        sharedMovieTitle: sharedMovieTitle || null,
      },
    });

    // Actualizar timestamp de la conversación para ordenarla primera
    await prisma.directConversation.update({
      where: { id: conversationId },
      data: {
        updatedAt: new Date(),
      },
    });

    return NextResponse.json({
      message: {
        id: created.id,
        conversationId: created.conversationId,
        senderId: created.senderId,
        senderName: created.senderName,
        senderAvatarUrl: created.senderAvatarUrl || undefined,
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
    console.error("POST /api/chats/direct/[id]/messages error:", error);
    return NextResponse.json(
      { error: error?.message || "Error al enviar mensaje directo" },
      { status: 500 }
    );
  }
}
