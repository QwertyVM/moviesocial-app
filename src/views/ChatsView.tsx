"use client";

import React, { useState, useEffect } from 'react';
import {
  ChatMessage,
  DirectConversation,
  MovieGroup,
  Friend,
  User,
  Movie,
} from '../types';
import { api } from '../services/api';
import {
  MessageSquare,
  Users,
  Send,
  Film,
  Plus,
  KeyRound,
  X,
  Sparkles,
  Share2,
} from 'lucide-react';
import { CURATED_MOVIES } from '../data/curatedMovies';

interface ChatsViewProps {
  currentUser: User;
  onSelectMovieById: (movieId: string) => void;
  initialFriendForChat?: Friend | null;
}

export const ChatsView: React.FC<ChatsViewProps> = ({
  currentUser,
  onSelectMovieById,
  initialFriendForChat,
}) => {
  const [chatType, setChatType] = useState<'direct' | 'groups'>('direct');
  const [conversations, setConversations] = useState<DirectConversation[]>([]);
  const [groups, setGroups] = useState<MovieGroup[]>([]);
  const [selectedConvoId, setSelectedConvoId] = useState<string | null>(null);
  const [selectedGroupId, setSelectedGroupId] = useState<string | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [inputText, setInputText] = useState<string>('');

  // Modals
  const [isCreateGroupOpen, setIsCreateGroupOpen] = useState(false);
  const [isJoinGroupOpen, setIsJoinGroupOpen] = useState(false);
  const [isShareMoviePickerOpen, setIsShareMoviePickerOpen] = useState(false);

  // Form states
  const [newGroupName, setNewGroupName] = useState('');
  const [newGroupDesc, setNewGroupDesc] = useState('');
  const [newGroupEmoji, setNewGroupEmoji] = useState('🎬');
  const [joinCode, setJoinCode] = useState('');

  // Load chats & groups
  const loadChats = async () => {
    const convos = await api.getDirectConversations();
    const grps = await api.getGroups();
    setConversations(convos);
    setGroups(grps);

    // Si nos pasaron un amigo inicial, abrir su conversación
    if (initialFriendForChat) {
      const target = await api.getOrCreateDirectConversation(initialFriendForChat);
      setChatType('direct');
      setSelectedConvoId(target.id);
      const msgs = await api.getDirectMessages(target.id);
      setMessages(msgs);
      return;
    }

    if (chatType === 'direct' && convos.length > 0 && !selectedConvoId) {
      setSelectedConvoId(convos[0].id);
      const msgs = await api.getDirectMessages(convos[0].id);
      setMessages(msgs);
    } else if (chatType === 'groups' && grps.length > 0 && !selectedGroupId) {
      setSelectedGroupId(grps[0].id);
      const msgs = await api.getGroupMessages(grps[0].id);
      setMessages(msgs);
    }
  };

  useEffect(() => {
    loadChats();
  }, [initialFriendForChat]);

  // Handle switching active conversation
  const handleSelectConvo = async (convoId: string) => {
    setSelectedConvoId(convoId);
    const msgs = await api.getDirectMessages(convoId);
    setMessages(msgs);
  };

  // Handle switching active group
  const handleSelectGroup = async (groupId: string) => {
    setSelectedGroupId(groupId);
    const msgs = await api.getGroupMessages(groupId);
    setMessages(msgs);
  };

  // Send message
  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim()) return;

    if (chatType === 'direct' && selectedConvoId) {
      const msg = await api.sendDirectMessage(selectedConvoId, {
        text: inputText.trim(),
        messageType: 'text',
      });
      setMessages([...messages, msg]);
      setInputText('');
    } else if (chatType === 'groups' && selectedGroupId) {
      const msg = await api.sendGroupMessage(selectedGroupId, {
        text: inputText.trim(),
        messageType: 'text',
      });
      setMessages([...messages, msg]);
      setInputText('');
    }
  };

  // Share movie directly in the active chat
  const handleShareMovie = async (movie: Movie) => {
    setIsShareMoviePickerOpen(false);
    if (chatType === 'direct' && selectedConvoId) {
      const msg = await api.sendDirectMessage(selectedConvoId, {
        text: `¡Te recomiendo ver esta película!`,
        messageType: 'movie',
        sharedMovie: movie,
      });
      setMessages([...messages, msg]);
    } else if (chatType === 'groups' && selectedGroupId) {
      const msg = await api.sendGroupMessage(selectedGroupId, {
        text: `Miren esta recomendación para el cineclub:`,
        messageType: 'movie',
        sharedMovie: movie,
      });
      setMessages([...messages, msg]);
    }
  };

  // Create Group
  const handleCreateGroup = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newGroupName.trim()) return;
    const grp = await api.createGroup(newGroupName.trim(), newGroupDesc.trim(), newGroupEmoji);
    setGroups([grp, ...groups]);
    setSelectedGroupId(grp.id);
    setMessages(await api.getGroupMessages(grp.id));
    setIsCreateGroupOpen(false);
    setNewGroupName('');
    setNewGroupDesc('');
  };

  // Join Group
  const handleJoinGroup = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!joinCode.trim()) return;
    const grp = await api.joinGroupByCode(joinCode.trim());
    if (grp) {
      setGroups(await api.getGroups());
      setSelectedGroupId(grp.id);
      setMessages(await api.getGroupMessages(grp.id));
      setIsJoinGroupOpen(false);
      setJoinCode('');
    }
  };

  const activeConvo = conversations.find((c) => c.id === selectedConvoId);
  const activeGroup = groups.find((g) => g.id === selectedGroupId);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 h-[calc(100vh-5rem)] flex flex-col">
      {/* Top Segmented Header */}
      <div className="flex items-center justify-between pb-4 border-b border-cinema-border flex-shrink-0">
        <div className="flex items-center gap-3">
          <div className="flex items-center bg-cinema-surface p-1 rounded-2xl border border-cinema-border">
            <button
              onClick={() => {
                setChatType('direct');
                if (conversations.length > 0) handleSelectConvo(conversations[0].id);
              }}
              className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                chatType === 'direct'
                  ? 'bg-cinema-card text-emerald-400 shadow-md border border-cinema-border'
                  : 'text-cinema-textSecondary hover:text-white'
              }`}
            >
              <MessageSquare className="w-3.5 h-3.5" />
              <span>Chats 1 a 1 ({conversations.length})</span>
            </button>

            <button
              onClick={() => {
                setChatType('groups');
                if (groups.length > 0) handleSelectGroup(groups[0].id);
              }}
              className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                chatType === 'groups'
                  ? 'bg-cinema-card text-cinema-gold shadow-md border border-cinema-border'
                  : 'text-cinema-textSecondary hover:text-white'
              }`}
            >
              <Users className="w-3.5 h-3.5" />
              <span>Cineclubs ({groups.length})</span>
            </button>
          </div>
        </div>

        {chatType === 'groups' && (
          <div className="flex items-center gap-2">
            <button
              onClick={() => setIsJoinGroupOpen(true)}
              className="px-3 py-1.5 rounded-xl bg-cinema-surface hover:bg-cinema-card border border-cinema-border text-cinema-textSecondary hover:text-white text-xs font-semibold flex items-center gap-1.5 transition-colors"
            >
              <KeyRound className="w-3.5 h-3.5 text-cinema-gold" />
              <span className="hidden sm:inline">Unirse con Código</span>
            </button>
            <button
              onClick={() => setIsCreateGroupOpen(true)}
              className="px-3.5 py-1.5 rounded-xl bg-cinema-gold hover:bg-amber-400 text-black text-xs font-bold flex items-center gap-1.5 transition-transform hover:scale-105 shadow"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Crear Cineclub</span>
            </button>
          </div>
        )}
      </div>

      {/* Main Messaging Interface */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 flex-grow overflow-hidden pt-4">
        
        {/* Left Column: List of conversations or groups */}
        <div className="rounded-3xl bg-cinema-card border border-cinema-border p-3 overflow-y-auto flex flex-col gap-2">
          {chatType === 'direct' ? (
            conversations.map((c) => {
              const isSelected = c.id === selectedConvoId;
              return (
                <button
                  key={c.id}
                  onClick={() => handleSelectConvo(c.id)}
                  className={`w-full p-3 rounded-2xl flex items-center gap-3 text-left transition-all ${
                    isSelected
                      ? 'bg-cinema-surface border border-emerald-500/30 shadow-md'
                      : 'hover:bg-cinema-surface/60 border border-transparent'
                  }`}
                >
                  <img
                    src={c.participant.avatarUrl}
                    alt={c.participant.displayName}
                    className="w-11 h-11 rounded-full object-cover border border-cinema-border"
                  />
                  <div className="flex flex-col flex-grow min-w-0">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-white truncate">
                        {c.participant.displayName}
                      </span>
                      <span className="text-[10px] text-cinema-textMuted font-mono">
                        {new Date(c.updatedAt).toLocaleTimeString('es-ES', {
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </span>
                    </div>
                    <span className="text-[11px] text-cinema-textMuted truncate">
                      {c.lastMessage?.text || 'Nueva conversación'}
                    </span>
                  </div>
                </button>
              );
            })
          ) : (
            groups.map((g) => {
              const isSelected = g.id === selectedGroupId;
              return (
                <button
                  key={g.id}
                  onClick={() => handleSelectGroup(g.id)}
                  className={`w-full p-3 rounded-2xl flex items-center gap-3 text-left transition-all ${
                    isSelected
                      ? 'bg-cinema-surface border border-cinema-gold/30 shadow-md'
                      : 'hover:bg-cinema-surface/60 border border-transparent'
                  }`}
                >
                  <div className="w-11 h-11 rounded-2xl bg-black/50 border border-cinema-border flex items-center justify-center text-xl flex-shrink-0">
                    {g.iconEmoji}
                  </div>
                  <div className="flex flex-col flex-grow min-w-0">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-white truncate">{g.name}</span>
                      <span className="text-[9px] px-1.5 py-0.5 rounded bg-cinema-surface text-cinema-gold font-mono border border-cinema-gold/20">
                        {g.inviteCode}
                      </span>
                    </div>
                    <span className="text-[11px] text-cinema-textMuted truncate">
                      {g.description || `${g.messagesCount} mensajes`}
                    </span>
                  </div>
                </button>
              );
            })
          )}
        </div>

        {/* Right 2 Columns: Active Conversation Thread */}
        <div className="md:col-span-2 rounded-3xl bg-cinema-card border border-cinema-border flex flex-col overflow-hidden shadow-2xl">
          {/* Thread Header */}
          <div className="p-4 border-b border-cinema-border bg-cinema-surface/40 flex items-center justify-between">
            {chatType === 'direct' && activeConvo ? (
              <div className="flex items-center gap-3">
                <img
                  src={activeConvo.participant.avatarUrl}
                  alt={activeConvo.participant.displayName}
                  className="w-9 h-9 rounded-full object-cover border border-cinema-border"
                />
                <div className="flex flex-col">
                  <span className="text-xs font-bold text-white">
                    {activeConvo.participant.displayName}
                  </span>
                  <span className="text-[10px] text-cinema-textMuted">
                    {activeConvo.participant.username} • En línea
                  </span>
                </div>
              </div>
            ) : chatType === 'groups' && activeGroup ? (
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-black/60 border border-cinema-border flex items-center justify-center text-lg">
                  {activeGroup.iconEmoji}
                </div>
                <div className="flex flex-col">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-white">{activeGroup.name}</span>
                    <span className="text-[9px] px-1.5 py-0.5 rounded bg-cinema-surface text-cinema-gold font-mono border border-cinema-gold/30">
                      Código: {activeGroup.inviteCode}
                    </span>
                  </div>
                  <span className="text-[10px] text-cinema-textMuted">
                    {activeGroup.membersCount || 1} cinéfilos miembros • Creado por {activeGroup.creatorName}
                  </span>
                </div>
              </div>
            ) : (
              <span className="text-xs text-cinema-textMuted">Selecciona una conversación</span>
            )}

            {/* Quick action: Share movie button */}
            <button
              onClick={() => setIsShareMoviePickerOpen(true)}
              className="px-3 py-1.5 rounded-xl bg-cinema-surface hover:bg-cinema-card border border-cinema-border text-cinema-gold text-xs font-semibold flex items-center gap-1.5 transition-colors"
            >
              <Film className="w-3.5 h-3.5" />
              <span>Compartir Película</span>
            </button>
          </div>

          {/* Messages Scroll Area */}
          <div className="flex-grow p-4 sm:p-6 overflow-y-auto flex flex-col gap-3.5 bg-cinema-bg/40">
            {messages.map((m) => {
              const isMe = m.senderId === currentUser.id;
              return (
                <div
                  key={m.id}
                  className={`flex flex-col max-w-[85%] sm:max-w-[70%] ${
                    isMe ? 'self-end items-end' : 'self-start items-start'
                  }`}
                >
                  {/* Sender Name if in group */}
                  {chatType === 'groups' && !isMe && (
                    <span className="text-[10px] font-semibold text-cinema-textMuted mb-1 ml-2">
                      {m.senderName}
                    </span>
                  )}

                  {/* Message Bubble */}
                  <div
                    className={`p-3.5 rounded-2xl flex flex-col gap-2 ${
                      isMe
                        ? 'bg-cinema-surface border border-cinema-border text-white rounded-br-none shadow-md'
                        : 'bg-cinema-card border border-cinema-border text-gray-200 rounded-bl-none shadow-md'
                    }`}
                  >
                    {/* Text */}
                    {m.text && <p className="text-xs sm:text-sm leading-relaxed">{m.text}</p>}

                    {/* Shared Movie Card */}
                    {m.messageType === 'movie' && m.sharedMovieId && (
                      <div
                        onClick={() => onSelectMovieById(m.sharedMovieId!)}
                        className="p-2.5 rounded-xl bg-cinema-bg/80 border border-cinema-gold/40 hover:border-cinema-gold cursor-pointer transition-all flex items-center gap-3 group mt-1"
                      >
                        {m.sharedMoviePosterUrl && (
                          <img
                            src={m.sharedMoviePosterUrl}
                            alt={m.sharedMovieTitle}
                            className="w-12 h-16 rounded-lg object-cover border border-cinema-border group-hover:scale-105 transition-transform"
                          />
                        )}
                        <div className="flex flex-col flex-grow">
                          <span className="text-[9px] uppercase tracking-wider text-cinema-gold font-mono">
                            Recomendación Cinéfila
                          </span>
                          <h4 className="text-xs font-bold text-white group-hover:text-cinema-gold transition-colors line-clamp-1">
                            {m.sharedMovieTitle}
                          </h4>
                          {m.sharedMovieScore && (
                            <span className="text-[10px] font-mono font-semibold text-cinema-textSecondary mt-0.5">
                              MovieScore: ★ {m.sharedMovieScore.toFixed(1)}
                            </span>
                          )}
                          <span className="text-[10px] font-semibold text-cinema-gold underline mt-1">
                            Ver salas y ficha →
                          </span>
                        </div>
                      </div>
                    )}

                    <span className="text-[9px] text-cinema-textMuted font-mono self-end">
                      {new Date(m.createdAt).toLocaleTimeString('es-ES', {
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Composer Input */}
          <form
            onSubmit={handleSendMessage}
            className="p-3 border-t border-cinema-border bg-cinema-surface/40 flex items-center gap-2"
          >
            <input
              type="text"
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              placeholder="Escribe un mensaje en el chat..."
              className="flex-grow px-4 py-2.5 rounded-xl bg-cinema-card border border-cinema-border focus:border-cinema-gold text-xs text-white placeholder-cinema-textMuted outline-none"
            />
            <button
              type="submit"
              disabled={!inputText.trim()}
              className="p-2.5 rounded-xl bg-cinema-gold hover:bg-amber-400 disabled:opacity-40 text-black transition-transform hover:scale-105 shadow"
            >
              <Send className="w-4 h-4" />
            </button>
          </form>
        </div>
      </div>

      {/* Modal: Share Movie Picker */}
      {isShareMoviePickerOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-3xl bg-cinema-card border border-cinema-border p-6 shadow-2xl flex flex-col gap-4">
            <div className="flex items-center justify-between pb-2 border-b border-cinema-border">
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                <Film className="w-4 h-4 text-cinema-gold" />
                Compartir Película en el Chat
              </h3>
              <button
                onClick={() => setIsShareMoviePickerOpen(false)}
                className="text-cinema-textMuted hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            <div className="max-h-80 overflow-y-auto flex flex-col gap-2">
              {CURATED_MOVIES.map((m) => (
                <button
                  key={m.id}
                  onClick={() => handleShareMovie(m)}
                  className="p-2.5 rounded-2xl bg-cinema-surface hover:bg-cinema-surface/80 border border-cinema-border flex items-center gap-3 text-left transition-colors"
                >
                  <img
                    src={m.posterURL}
                    alt={m.title}
                    className="w-10 h-14 rounded-lg object-cover border border-cinema-border"
                  />
                  <div className="flex flex-col flex-grow">
                    <span className="text-xs font-bold text-white">{m.title}</span>
                    <span className="text-[10px] text-cinema-textMuted">
                      {m.releaseYear} • MovieScore {m.ratings.compositeScore?.toFixed(1)}
                    </span>
                  </div>
                  <Share2 className="w-4 h-4 text-cinema-gold mr-2" />
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Modal: Create Cineclub */}
      {isCreateGroupOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-3xl bg-cinema-card border border-cinema-border p-6 shadow-2xl flex flex-col gap-4">
            <div className="flex items-center justify-between pb-2 border-b border-cinema-border">
              <h3 className="text-sm font-bold text-white">Crear Nuevo Cineclub</h3>
              <button
                onClick={() => setIsCreateGroupOpen(false)}
                className="text-cinema-textMuted hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            <form onSubmit={handleCreateGroup} className="flex flex-col gap-4">
              <div>
                <label className="text-xs font-semibold text-cinema-textSecondary uppercase">
                  Nombre del Cineclub
                </label>
                <input
                  type="text"
                  value={newGroupName}
                  onChange={(e) => setNewGroupName(e.target.value)}
                  placeholder="Ej: Amantes de 70mm, Cine Nórdico..."
                  required
                  className="w-full mt-1 px-3.5 py-2 rounded-xl bg-cinema-surface border border-cinema-border text-xs text-white outline-none focus:border-cinema-gold"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-cinema-textSecondary uppercase">
                  Descripción
                </label>
                <textarea
                  value={newGroupDesc}
                  onChange={(e) => setNewGroupDesc(e.target.value)}
                  placeholder="¿De qué trata este cineclub?"
                  rows={3}
                  className="w-full mt-1 px-3.5 py-2 rounded-xl bg-cinema-surface border border-cinema-border text-xs text-white outline-none focus:border-cinema-gold resize-none"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-cinema-textSecondary uppercase">
                  Emoji de Identificación
                </label>
                <input
                  type="text"
                  value={newGroupEmoji}
                  onChange={(e) => setNewGroupEmoji(e.target.value)}
                  className="w-20 mt-1 px-3 py-2 rounded-xl bg-cinema-surface border border-cinema-border text-center text-lg text-white outline-none focus:border-cinema-gold"
                />
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setIsCreateGroupOpen(false)}
                  className="px-4 py-2 text-xs text-cinema-textSecondary"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl bg-cinema-gold text-black font-bold text-xs"
                >
                  Crear
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Join Cineclub with Code */}
      {isJoinGroupOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="w-full max-w-sm rounded-3xl bg-cinema-card border border-cinema-border p-6 shadow-2xl flex flex-col gap-4">
            <div className="flex items-center justify-between pb-2 border-b border-cinema-border">
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                <KeyRound className="w-4 h-4 text-cinema-gold" />
                Unirse con Código
              </h3>
              <button
                onClick={() => setIsJoinGroupOpen(false)}
                className="text-cinema-textMuted hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            <form onSubmit={handleJoinGroup} className="flex flex-col gap-4">
              <div>
                <label className="text-xs font-semibold text-cinema-textSecondary uppercase">
                  Código de Invitación
                </label>
                <input
                  type="text"
                  value={joinCode}
                  onChange={(e) => setJoinCode(e.target.value.toUpperCase())}
                  placeholder="Ej: CINE-PERU"
                  required
                  className="w-full mt-1 px-3.5 py-2.5 rounded-xl bg-cinema-surface border border-cinema-border text-sm font-mono text-center tracking-widest text-cinema-gold outline-none focus:border-cinema-gold"
                />
              </div>
              <button
                type="submit"
                className="w-full py-2.5 rounded-xl bg-cinema-gold text-black font-bold text-xs"
              >
                Unirse al Cineclub
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
