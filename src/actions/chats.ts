"use server";

import prisma from "@/lib/prisma";
import { MovieGroup, ChatMessage, DirectConversation, Friend } from "@/types";
import { INITIAL_GROUPS, INITIAL_FRIENDS } from "@/data/curatedMovies";

export async function getGroups(): Promise<MovieGroup[]> {
  try {
    const dbGroups = await prisma.movieGroup.findMany({
      orderBy: { createdAt: "desc" },
    });

    if (dbGroups.length > 0) {
      return dbGroups.map((g) => ({
        id: g.id,
        name: g.name,
        description: g.description || "",
        iconEmoji: g.iconEmoji || "🎬",
        creatorId: g.creatorId,
        creatorName: g.creatorName,
        inviteCode: g.inviteCode || `CINE-${g.id.slice(-6).toUpperCase()}`,
        messagesCount: g.messagesCount,
        membersCount: 4,
        createdAt: g.createdAt ? g.createdAt.toISOString() : new Date().toISOString(),
      }));
    }
  } catch (err) {
    console.warn("Neon DB getGroups fallback:", err);
  }

  return INITIAL_GROUPS;
}

export async function createGroup(data: {
  name: string;
  description: string;
  iconEmoji?: string;
  creatorId: string;
  creatorName: string;
}): Promise<MovieGroup> {
  const grpId = `grp_${Date.now()}`;
  const code = `CINE-${grpId.slice(-6).toUpperCase()}`;

  const newGroup: MovieGroup = {
    id: grpId,
    name: data.name,
    description: data.description,
    iconEmoji: data.iconEmoji || "🎬",
    creatorId: data.creatorId,
    creatorName: data.creatorName,
    inviteCode: code,
    messagesCount: 1,
    membersCount: 1,
    createdAt: new Date().toISOString(),
  };

  try {
    await prisma.movieGroup.create({
      data: {
        id: newGroup.id,
        name: newGroup.name,
        description: newGroup.description,
        iconEmoji: newGroup.iconEmoji,
        creatorId: newGroup.creatorId,
        creatorName: newGroup.creatorName,
        inviteCode: newGroup.inviteCode,
        messagesCount: 1,
      },
    });
  } catch (err) {
    console.warn("Neon DB createGroup fallback:", err);
  }

  return newGroup;
}

export async function getGroupMessages(groupId: string): Promise<ChatMessage[]> {
  try {
    const dbMsgs = await prisma.groupMessage.findMany({
      where: { groupId },
      orderBy: { createdAt: "asc" },
    });

    if (dbMsgs.length > 0) {
      return dbMsgs.map((m) => ({
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
    }
  } catch (err) {
    console.warn("Neon DB getGroupMessages fallback:", err);
  }

  return [
    {
      id: "gm_default_1",
      groupId,
      senderId: "friend_valeria",
      senderName: "Valeria Gómez",
      text: "¡Hola a todos! Bienvenidos al debate de cineclub.",
      messageType: "text",
      createdAt: new Date().toISOString(),
    },
  ];
}

