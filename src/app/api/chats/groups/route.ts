import { NextRequest, NextResponse } from "next/server";
import prisma from "@/lib/prisma";

export async function GET() {
  try {
    const groups = await prisma.movieGroup.findMany({
      orderBy: { createdAt: "desc" },
    });

    const formatted = groups.map((g) => ({
      id: g.id,
      name: g.name,
      description: g.description || "",
      iconEmoji: g.iconEmoji || "🎬",
      creatorId: g.creatorId,
      creatorName: g.creatorName,
      inviteCode: g.inviteCode || `CINE-${g.id.slice(-6).toUpperCase()}`,
      messagesCount: g.messagesCount,
      membersCount: 1,
      createdAt: g.createdAt ? g.createdAt.toISOString() : new Date().toISOString(),
    }));

    return NextResponse.json({ groups: formatted });
  } catch (error: any) {
    console.error("GET /api/chats/groups error:", error);
    return NextResponse.json(
      { error: error?.message || "Error al obtener grupos" },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, description, iconEmoji = "🎬", creatorId, creatorName } = body;

    if (!name || !creatorId) {
      return NextResponse.json(
        { error: "Nombre y creatorId son requeridos" },
        { status: 400 }
      );
    }

    // Regla de Negocio: Validar que el creador de un nuevo cineclub tenga Pro
    const creatorUser = await prisma.user.findUnique({
      where: { id: creatorId },
    });

    if (!creatorUser?.isPremium) {
      return NextResponse.json(
        {
          error: "PREMIUM_REQUIRED",
          message:
            "La creación de Cineclubs Comunitarios Públicos es exclusiva para miembros Cinéfilo Pro. Puedes unirte y chatear 1 a 1 libremente con tus amigos.",
          requiresPro: true,
        },
        { status: 403 }
      );
    }

    const grpId = `grp_${Date.now()}`;
    const inviteCode = `CINE-${grpId.slice(-6).toUpperCase()}`;

    const created = await prisma.movieGroup.create({
      data: {
        id: grpId,
        name: name.trim(),
        description: description?.trim() || "Cineclub de debate cinéfilo",
        iconEmoji,
        creatorId,
        creatorName: creatorName || creatorUser?.displayName || "Cinéfilo Pro",
        inviteCode,
        messagesCount: 1,
      },
    });

    // Mensaje de bienvenida inicial en el grupo
    await prisma.groupMessage.create({
      data: {
        id: `gmsg_${Date.now()}`,
        groupId: created.id,
        userId: creatorId,
        userName: created.creatorName,
        text: `¡Bienvenidos al Cineclub "${created.name}"! Usa el código ${created.inviteCode} para invitar a más cinéfilos.`,
        messageType: "text",
      },
    });

    return NextResponse.json({
      group: {
        id: created.id,
        name: created.name,
        description: created.description || "",
        iconEmoji: created.iconEmoji || "🎬",
        creatorId: created.creatorId,
        creatorName: created.creatorName,
        inviteCode: created.inviteCode || inviteCode,
        messagesCount: 1,
        membersCount: 1,
        createdAt: created.createdAt ? created.createdAt.toISOString() : new Date().toISOString(),
      },
    });
  } catch (error: any) {
    console.error("POST /api/chats/groups error:", error);
    return NextResponse.json(
      { error: error?.message || "Error al crear cineclub" },
      { status: 500 }
    );
  }
}
