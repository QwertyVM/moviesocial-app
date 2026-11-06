import { NextRequest, NextResponse } from "next/server";
import prisma from "@/lib/prisma";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get("userId");

    // Traer todas las conversaciones directas con su último mensaje
    const convos = await prisma.directConversation.findMany({
      include: {
        messages: {
          orderBy: { createdAt: "desc" },
          take: 1,
        },
      },
      orderBy: { updatedAt: "desc" },
    });

    // Mapear cada conversación resolviendo los datos del participante
    const formatted = await Promise.all(
      convos.map(async (c) => {
        let friend = await prisma.friend.findUnique({
          where: { id: c.participantId },
        });

        // Si no está en friends, buscar en users
        let isFriend = Boolean(friend);
        let displayName = friend?.displayName;
        let username = friend?.username;
        let avatarUrl = friend?.avatarUrl;

        if (!friend) {
          const userParticipant = await prisma.user.findUnique({
            where: { id: c.participantId },
          });
          if (userParticipant) {
            displayName = userParticipant.displayName;
            username = userParticipant.username;
            avatarUrl = userParticipant.avatarUrl || undefined;
          }
        }

        const lastDbMsg = c.messages[0];
        const lastMessage = lastDbMsg
          ? {
              id: lastDbMsg.id,
              conversationId: lastDbMsg.conversationId,
              senderId: lastDbMsg.senderId,
              senderName: lastDbMsg.senderName,
              senderAvatarUrl: lastDbMsg.senderAvatarUrl || undefined,
              text: lastDbMsg.text,
              messageType: (lastDbMsg.messageType as any) || "text",
              sharedMovieId: lastDbMsg.sharedMovieId || undefined,
              sharedMovieTitle: lastDbMsg.sharedMovieTitle || undefined,
              createdAt: lastDbMsg.createdAt
                ? lastDbMsg.createdAt.toISOString()
                : new Date().toISOString(),
            }
          : undefined;

        return {
          id: c.id,
          participant: {
            id: c.participantId,
            displayName: displayName || "Cinéfilo",
            username: username || "@cinefilo",
            avatarUrl:
              avatarUrl ||
              `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(
                username || c.participantId
              )}`,
            isMutual: isFriend,
            mutualMoviesCount: friend?.mutualMoviesCount || 0,
          },
          lastMessage,
          unreadCount: c.unreadCount || 0,
          updatedAt: c.updatedAt
            ? c.updatedAt.toISOString()
            : new Date().toISOString(),
        };
      })
    );

    return NextResponse.json({ conversations: formatted });
  } catch (error: any) {
    console.error("GET /api/chats/direct error:", error);
    return NextResponse.json(
      { error: error?.message || "Error al cargar conversaciones directas" },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { senderId, participantId, initialText } = body;

    if (!senderId || !participantId) {
      return NextResponse.json(
        { error: "senderId y participantId son obligatorios" },
        { status: 400 }
      );
    }

    if (senderId === participantId) {
      return NextResponse.json(
        { error: "No puedes iniciar una conversación contigo mismo" },
        { status: 400 }
      );
    }

    // 1. Verificar si el participante es un amigo registrado
    const friendRecord = await prisma.friend.findUnique({
      where: { id: participantId },
    });
    const isFriend = Boolean(friendRecord);

    // 2. Si NO es amigo (es un "extraño"), validar que el emisor sea Pro
    let senderUser = await prisma.user.findUnique({
      where: { id: senderId },
    });

    if (!isFriend) {
      const isSenderPro = senderUser?.isPremium === true;
      if (!isSenderPro) {
        return NextResponse.json(
          {
            error: "PREMIUM_REQUIRED",
            message:
              "El chat 1 a 1 libre es exclusivo entre amigos. Para contactar a cinéfilos nuevos fuera de tu círculo necesitas la suscripción Cinéfilo Pro.",
            requiresPro: true,
          },
          { status: 403 }
        );
      }
    }

    // 3. Crear o recuperar la conversación directa en Prisma
    const convoId = `conv_${[senderId, participantId].sort().join("_")}`;

    let conversation = await prisma.directConversation.findUnique({
      where: { id: convoId },
    });

    if (!conversation) {
      conversation = await prisma.directConversation.create({
        data: {
          id: convoId,
          participantId: participantId,
          unreadCount: 0,
          updatedAt: new Date(),
        },
      });

      // Si se envió un texto inicial, persistir el primer mensaje
      if (initialText && initialText.trim()) {
        await prisma.directMessage.create({
          data: {
            id: `dmsg_${Date.now()}`,
            conversationId: convoId,
            senderId,
            senderName: senderUser?.displayName || "Yo",
            senderAvatarUrl: senderUser?.avatarUrl || null,
            recipientId: participantId,
            text: initialText.trim(),
            messageType: "text",
          },
        });
      }
    }

    // Resolver info del participante
    let displayName = friendRecord?.displayName;
    let username = friendRecord?.username;
    let avatarUrl = friendRecord?.avatarUrl;

    if (!friendRecord) {
      const targetUser = await prisma.user.findUnique({
        where: { id: participantId },
      });
      if (targetUser) {
        displayName = targetUser.displayName;
        username = targetUser.username;
        avatarUrl = targetUser.avatarUrl || undefined;
      }
    }

    return NextResponse.json({
      conversation: {
        id: conversation.id,
        participant: {
          id: participantId,
          displayName: displayName || "Cinéfilo",
          username: username || "@cinefilo",
          avatarUrl:
            avatarUrl ||
            `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(
              username || participantId
            )}`,
          isMutual: isFriend,
          mutualMoviesCount: friendRecord?.mutualMoviesCount || 0,
        },
        unreadCount: conversation.unreadCount,
        updatedAt: conversation.updatedAt
          ? conversation.updatedAt.toISOString()
          : new Date().toISOString(),
      },
      isFriend,
      initiatorIsPro: senderUser?.isPremium ?? false,
    });
  } catch (error: any) {
    console.error("POST /api/chats/direct error:", error);
    return NextResponse.json(
      { error: error?.message || "Error al procesar la conversación directa" },
      { status: 500 }
    );
  }
}
