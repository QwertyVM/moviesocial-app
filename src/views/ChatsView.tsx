"use client";

import React, { useState, useEffect, useRef } from 'react';
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
  Lock,
  Globe,
  ArrowLeft,
  UserPlus,
  Search,
} from 'lucide-react';
import { CURATED_MOVIES } from '../data/curatedMovies';

interface ChatsViewProps {
  currentUser: User;
  onSelectMovieById: (movieId: string) => void;
  initialFriendForChat?: Friend | null;
  onOpenSubscriptionModal?: (reason?: string) => void;
}

export const ChatsView: React.FC<ChatsViewProps> = ({
  currentUser,
  onSelectMovieById,
  initialFriendForChat,
  onOpenSubscriptionModal,
}) => {
  const [chatType, setChatType] = useState<'direct' | 'groups'>('direct');
  const [conversations, setConversations] = useState<DirectConversation[]>([]);
  const [groups, setGroups] = useState<MovieGroup[]>([]);
  const [selectedConvoId, setSelectedConvoId] = useState<string | null>(null);
  const [selectedGroupId, setSelectedGroupId] = useState<string | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [inputText, setInputText] = useState<string>('');

  // Modales
  const [isNewChatOpen, setIsNewChatOpen] = useState(false);
  const [isCreateGroupOpen, setIsCreateGroupOpen] = useState(false);
  const [isJoinGroupOpen, setIsJoinGroupOpen] = useState(false);
  const [isShareMoviePickerOpen, setIsShareMoviePickerOpen] = useState(false);

  // Directorio para nuevos chats (amigos vs comunidad/extraños)
  const [availableFriends, setAvailableFriends] = useState<Friend[]>([]);
  const [availableCommunity, setAvailableCommunity] = useState<(Friend & { isFriend: boolean; isPremium?: boolean })[]>([]);
  const [searchContactText, setSearchContactText] = useState('');

  // Formularios
  const [newGroupName, setNewGroupName] = useState('');
  const [newGroupDesc, setNewGroupDesc] = useState('');
  const [newGroupEmoji, setNewGroupEmoji] = useState('🎬');
  const [joinCode, setJoinCode] = useState('');

  const messagesEndRef = useRef<HTMLDivElement | null>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  // Cargar lista de chats y cineclubs
  const loadChats = async () => {
    const convos = await api.getDirectConversations();
    const grps = await api.getGroups();
    setConversations(convos);
    setGroups(grps);

    // Si nos pasaron un amigo inicial, abrir su conversación
    if (initialFriendForChat) {
      try {
        const target = await api.getOrCreateDirectConversation(initialFriendForChat);
        setChatType('direct');
        setSelectedConvoId(target.id);
        const msgs = await api.getDirectMessages(target.id);
        setMessages(msgs);
        return;
      } catch (err: any) {
        if (err.requiresPro) {
          onOpenSubscriptionModal?.(
            'El chat 1 a 1 libre es exclusivo entre amigos. Para contactar a cinéfilos nuevos de la comunidad global necesitas la suscripción Cinéfilo Pro.'
          );
        }
      }
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

  // Cargar directorio de contactos para iniciar un chat nuevo
  const loadContactsDirectory = async () => {
    const data = await api.getFriendsAndCommunity();
    setAvailableFriends(data.friends || []);
    setAvailableCommunity(data.community || []);
  };

  useEffect(() => {
    loadChats();
    loadContactsDirectory();
  }, [initialFriendForChat]);

  useEffect(() => {
    scrollToBottom();
  }, [messages.length]);

  // =========================================================================
  // SMART CURSOR POLLING (Tiempo Real optimizado para Serverless + Neon DB)
  // Consulta mensajes nuevos cada 2.5s únicamente si la pestaña está activa.
  // =========================================================================
  useEffect(() => {
    if (!selectedConvoId && !selectedGroupId) return;

    const interval = setInterval(async () => {
      // Si la ventana no está visible, pausar polling (cero consumo de BD)
      if (typeof document !== 'undefined' && document.visibilityState !== 'visible') {
        return;
      }

      if (chatType === 'direct' && selectedConvoId) {
        const lastMsg = messages[messages.length - 1];
        const cursor = lastMsg?.createdAt;
        if (!cursor) return;

        const newMsgs = await api.getDirectMessages(selectedConvoId, cursor);
        if (newMsgs && newMsgs.length > 0) {
          // Filtrar duplicados
          setMessages((prev) => {
            const existingIds = new Set(prev.map((m) => m.id));
            const fresh = newMsgs.filter((m) => !existingIds.has(m.id));
            return fresh.length > 0 ? [...prev, ...fresh] : prev;
          });
        }
      } else if (chatType === 'groups' && selectedGroupId) {
        const lastMsg = messages[messages.length - 1];
        const cursor = lastMsg?.createdAt;
        if (!cursor) return;

        const newMsgs = await api.getGroupMessages(selectedGroupId, cursor);
        if (newMsgs && newMsgs.length > 0) {
          setMessages((prev) => {
            const existingIds = new Set(prev.map((m) => m.id));
            const fresh = newMsgs.filter((m) => !existingIds.has(m.id));
            return fresh.length > 0 ? [...prev, ...fresh] : prev;
          });
        }
      }
    }, 2500);

    return () => clearInterval(interval);
  }, [chatType, selectedConvoId, selectedGroupId, messages]);

  // Selección de conversación directa activa
  const handleSelectConvo = async (convoId: string) => {
    setSelectedConvoId(convoId);
    const msgs = await api.getDirectMessages(convoId);
    setMessages(msgs);
  };

  // Selección de cineclub activo
  const handleSelectGroup = async (groupId: string) => {
    setSelectedGroupId(groupId);
    const msgs = await api.getGroupMessages(groupId);
    setMessages(msgs);
  };

  // Iniciar conversación directa con amigo o extraño (Regla de negocio Backend)
  const handleStartDirectChat = async (target: Friend | { id: string; displayName: string; username: string; avatarUrl?: string; isFriend?: boolean }) => {
    const isFriend = (target as any).isFriend !== false;

    // Validación Pro preventiva en cliente para extraños
    if (!isFriend && !currentUser.isPremium) {
      setIsNewChatOpen(false);
      onOpenSubscriptionModal?.(
        'El chat 1 a 1 libre es exclusivo entre amigos. Para contactar a cinéfilos nuevos fuera de tu lista de amigos necesitas la suscripción Cinéfilo Pro.'
      );
      return;
    }

    try {
      const convo = await api.getOrCreateDirectConversation(target as Friend);
      setIsNewChatOpen(false);
      setChatType('direct');
      setSelectedConvoId(convo.id);
      const msgs = await api.getDirectMessages(convo.id);
      setMessages(msgs);
      // Refrescar conversaciones
      const updatedList = await api.getDirectConversations();
      setConversations(updatedList);
    } catch (err: any) {
      if (err.requiresPro) {
        setIsNewChatOpen(false);
        onOpenSubscriptionModal?.(
          'El chat 1 a 1 libre es exclusivo entre amigos. Para contactar a cinéfilos nuevos fuera de tu lista de amigos necesitas la suscripción Cinéfilo Pro.'
        );
      } else {
        alert(err.message || 'Error al iniciar conversación');
      }
    }
  };

  // Enviar mensaje
  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim()) return;

    if (chatType === 'direct' && selectedConvoId) {
      const activeConvo = conversations.find((c) => c.id === selectedConvoId);
      try {
        const msg = await api.sendDirectMessage(selectedConvoId, {
          text: inputText.trim(),
          messageType: 'text',
          recipientId: activeConvo?.participant.id,
        });
        setMessages((prev) => [...prev, msg]);
        setInputText('');
      } catch (err: any) {
        if (err.requiresPro) {
          onOpenSubscriptionModal?.(
            'El chat 1 a 1 libre es exclusivo entre amigos. Para contactar a cinéfilos nuevos requieres Cinéfilo Pro.'
          );
        } else {
          alert(err.message || 'Error al enviar mensaje');
        }
      }
    } else if (chatType === 'groups' && selectedGroupId) {
      if (!currentUser.isPremium) {
        onOpenSubscriptionModal?.(
          'Para participar y enviar mensajes en los Cineclubs de la Comunidad global necesitas la suscripción mensual. En el Plan Base puedes chatear libremente 1 a 1 con tus amigos.'
        );
        return;
      }
      try {
        const msg = await api.sendGroupMessage(selectedGroupId, {
          text: inputText.trim(),
          messageType: 'text',
        });
        setMessages((prev) => [...prev, msg]);
        setInputText('');
      } catch (err: any) {
        if (err.requiresPro) {
          onOpenSubscriptionModal?.(
            'Para participar y debatir en los Cineclubs de la Comunidad global necesitas la suscripción mensual.'
          );
        }
      }
    }
  };

  // Compartir tarjeta de película dentro del chat activo
  const handleShareMovie = async (movie: Movie) => {
    setIsShareMoviePickerOpen(false);
    if (chatType === 'direct' && selectedConvoId) {
      const activeConvo = conversations.find((c) => c.id === selectedConvoId);
      try {
        const msg = await api.sendDirectMessage(selectedConvoId, {
          text: `¡Te recomiendo ver esta película!`,
          messageType: 'movie',
          sharedMovie: movie,
          recipientId: activeConvo?.participant.id,
        });
        setMessages((prev) => [...prev, msg]);
      } catch (err: any) {
        if (err.requiresPro) {
          onOpenSubscriptionModal?.(
            'Para enviar mensajes a personas fuera de tu lista de amigos requieres Cinéfilo Pro.'
          );
        }
      }
    } else if (chatType === 'groups' && selectedGroupId) {
      if (!currentUser.isPremium) {
        onOpenSubscriptionModal?.(
          'Para participar y enviar mensajes en los Cineclubs de la Comunidad global necesitas la suscripción mensual. En el Plan Base puedes chatear libremente 1 a 1 con tus amigos.'
        );
        return;
      }
      try {
        const msg = await api.sendGroupMessage(selectedGroupId, {
          text: `Miren esta recomendación para el cineclub:`,
          messageType: 'movie',
          sharedMovie: movie,
        });
        setMessages((prev) => [...prev, msg]);
      } catch (err: any) {
        if (err.requiresPro) {
          onOpenSubscriptionModal?.(
            'Para participar en Cineclubs comunitarios necesitas la membresía Cinéfilo Pro.'
          );
        }
      }
    }
  };

  // Crear Cineclub (Requiere Pro)
  const handleCreateGroup = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newGroupName.trim()) return;

    if (!currentUser.isPremium) {
      setIsCreateGroupOpen(false);
      onOpenSubscriptionModal?.(
        'La creación de Cineclubs Comunitarios Públicos es exclusiva para miembros Cinéfilo Pro. En el Plan Base puedes chatear libremente 1 a 1 con tus amigos.'
      );
      return;
    }

    try {
      const grp = await api.createGroup(newGroupName.trim(), newGroupDesc.trim(), newGroupEmoji);
      setGroups([grp, ...groups]);
      setSelectedGroupId(grp.id);
      setMessages(await api.getGroupMessages(grp.id));
      setIsCreateGroupOpen(false);
      setNewGroupName('');
      setNewGroupDesc('');
    } catch (err: any) {
      if (err.requiresPro) {
        setIsCreateGroupOpen(false);
        onOpenSubscriptionModal?.(
          'La creación de Cineclubs Comunitarios Públicos es exclusiva para miembros Cinéfilo Pro.'
        );
      } else {
        alert(err.message || 'Error al crear cineclub');
      }
    }
  };

  // Unirse a Cineclub por Código
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
    } else {
      alert('No se encontró ningún cineclub con ese código de invitación.');
    }
  };

  const activeConvo = conversations.find((c) => c.id === selectedConvoId);
  const activeGroup = groups.find((g) => g.id === selectedGroupId);

  const filteredFriends = availableFriends.filter((f) =>
    f.displayName.toLowerCase().includes(searchContactText.toLowerCase()) ||
    f.username.toLowerCase().includes(searchContactText.toLowerCase())
  );

  const filteredCommunity = availableCommunity.filter((c) =>
    c.displayName.toLowerCase().includes(searchContactText.toLowerCase()) ||
    c.username.toLowerCase().includes(searchContactText.toLowerCase())
  );

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-6 h-[calc(100vh-4.5rem)] flex flex-col">
      {/* Selector Superior: 1 a 1 vs Cineclubs */}
      <div className="flex items-center justify-between pb-3 sm:pb-4 border-b border-cinema-border/70 flex-shrink-0">
        <div className="flex items-center gap-2 sm:gap-3">
          <div className="flex items-center bg-cinema-surface p-1 rounded-2xl border border-cinema-border">
            <button
              onClick={() => {
                setChatType('direct');
                if (conversations.length > 0) handleSelectConvo(conversations[0].id);
              }}
              className={`flex items-center gap-2 px-3 sm:px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                chatType === 'direct'
                  ? 'bg-cinema-card text-emerald-400 shadow-md border border-emerald-500/30'
                  : 'text-cinema-textSecondary hover:text-white'
              }`}
            >
              <MessageSquare className="w-3.5 h-3.5" />
              <span>Chats 1 a 1</span>
              <span className="px-1.5 py-0.2 rounded-full bg-black/50 text-[10px] text-emerald-400 font-mono">
                {conversations.length}
              </span>
            </button>

            <button
              onClick={() => {
                setChatType('groups');
                if (groups.length > 0) handleSelectGroup(groups[0].id);
              }}
              className={`flex items-center gap-2 px-3 sm:px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                chatType === 'groups'
                  ? 'bg-cinema-card text-cinema-gold shadow-md border border-cinema-gold/30'
                  : 'text-cinema-textSecondary hover:text-white'
              }`}
            >
              <Users className="w-3.5 h-3.5" />
              <span>Cineclubs</span>
              <span className="px-1.5 py-0.2 rounded-full bg-black/50 text-[10px] text-cinema-gold font-mono">
                {groups.length}
              </span>
            </button>
          </div>
        </div>

        {/* Acciones de Cabecera */}
        {chatType === 'direct' ? (
          <button
            onClick={() => {
              loadContactsDirectory();
              setIsNewChatOpen(true);
            }}
            className="px-3.5 py-1.5 rounded-xl bg-gradient-to-r from-emerald-600 to-emerald-500 hover:from-emerald-500 hover:to-emerald-400 text-black text-xs font-bold flex items-center gap-1.5 transition-all shadow"
          >
            <UserPlus className="w-3.5 h-3.5" />
            <span>Nuevo Chat</span>
          </button>
        ) : (
          <div className="flex items-center gap-2">
            <button
              onClick={() => setIsJoinGroupOpen(true)}
              className="px-3 py-1.5 rounded-xl bg-cinema-surface hover:bg-cinema-card border border-cinema-border text-cinema-textSecondary hover:text-white text-xs font-semibold flex items-center gap-1.5 transition-colors"
            >
              <KeyRound className="w-3.5 h-3.5 text-cinema-gold" />
              <span className="hidden sm:inline">Unirse con Código</span>
            </button>
            <button
              onClick={() => {
                if (!currentUser.isPremium) {
                  onOpenSubscriptionModal?.(
                    'La creación de Cineclubs Comunitarios Públicos es exclusiva para miembros Cinéfilo Pro. En el Plan Base puedes chatear libremente 1 a 1 con tus amigos.'
                  );
                } else {
                  setIsCreateGroupOpen(true);
                }
              }}
              className="px-3.5 py-1.5 rounded-xl bg-cinema-gold hover:bg-amber-400 text-black text-xs font-bold flex items-center gap-1.5 transition-transform hover:scale-105 shadow"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Crear Cineclub</span>
              {!currentUser.isPremium && <Lock className="w-3 h-3 text-black/70 ml-0.5" />}
            </button>
          </div>
        )}
      </div>

      {/* Contenedor Principal de Mensajería */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 flex-grow overflow-hidden pt-3 sm:pt-4">
        
        {/* Columna Izquierda: Lista de Conversaciones o Grupos */}
        <div className={`rounded-3xl bg-cinema-card border border-cinema-border p-3 overflow-y-auto flex flex-col gap-2 ${activeConvo || activeGroup ? 'hidden md:flex' : 'flex'}`}>
          {chatType === 'direct' ? (
            conversations.length > 0 ? (
              conversations.map((c) => {
                const isSelected = c.id === selectedConvoId;
                const isFriend = c.participant.isMutual;
                return (
                  <button
                    key={c.id}
                    onClick={() => handleSelectConvo(c.id)}
                    className={`w-full p-3 rounded-2xl flex items-center gap-3 text-left transition-all ${
                      isSelected
                        ? 'bg-cinema-surface border border-emerald-500/40 shadow-md'
                        : 'hover:bg-cinema-surface/60 border border-transparent'
                    }`}
                  >
                    <div className="relative flex-shrink-0">
                      <img
                        src={c.participant.avatarUrl}
                        alt={c.participant.displayName}
                        className="w-11 h-11 rounded-full object-cover border border-cinema-border"
                      />
                      {isFriend ? (
                        <span className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 bg-emerald-500 rounded-full border-2 border-cinema-card" title="Amigo mutuo" />
                      ) : (
                        <span className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 bg-indigo-500 rounded-full border-2 border-cinema-card" title="Comunidad" />
                      )}
                    </div>
                    <div className="flex flex-col flex-grow min-w-0">
                      <div className="flex items-center justify-between gap-1">
                        <span className="text-xs font-bold text-white truncate">
                          {c.participant.displayName}
                        </span>
                        <span className="text-[10px] text-cinema-textMuted font-mono flex-shrink-0">
                          {new Date(c.updatedAt).toLocaleTimeString('es-ES', {
                            hour: '2-digit',
                            minute: '2-digit',
                          })}
                        </span>
                      </div>
                      <div className="flex items-center justify-between mt-0.5">
                        <span className="text-[11px] text-cinema-textMuted truncate max-w-[170px]">
                          {c.lastMessage?.text || 'Nueva conversación'}
                        </span>
                        <span className="text-[9px] px-1.5 py-0.5 rounded bg-black/40 text-cinema-textMuted font-mono border border-white/5">
                          {isFriend ? 'Amigo' : 'Comunidad'}
                        </span>
                      </div>
                    </div>
                  </button>
                );
              })
            ) : (
              <div className="p-8 text-center flex flex-col items-center justify-center my-auto gap-2">
                <MessageSquare className="w-8 h-8 text-cinema-textMuted" />
                <p className="text-xs font-bold text-white">No tienes chats directos aún</p>
                <p className="text-[11px] text-cinema-textMuted max-w-[200px]">
                  Chatea gratis con tus amigos agregados o contacta cinéfilos de la comunidad.
                </p>
                <button
                  onClick={() => {
                    loadContactsDirectory();
                    setIsNewChatOpen(true);
                  }}
                  className="mt-2 px-3.5 py-1.5 rounded-xl bg-emerald-500 text-black text-xs font-bold"
                >
                  Iniciar Primer Chat
                </button>
              </div>
            )
          ) : (
            groups.map((g) => {
              const isSelected = g.id === selectedGroupId;
              return (
                <button
                  key={g.id}
                  onClick={() => handleSelectGroup(g.id)}
                  className={`w-full p-3 rounded-2xl flex items-center gap-3 text-left transition-all ${
                    isSelected
                      ? 'bg-cinema-surface border border-cinema-gold/40 shadow-md'
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

        {/* Columna Derecha: Hilo de la Conversación */}
        <div className={`md:col-span-2 rounded-3xl bg-cinema-card border border-cinema-border flex flex-col overflow-hidden shadow-2xl ${!(activeConvo || activeGroup) ? 'hidden md:flex' : 'flex'}`}>
          {!(activeConvo || activeGroup) ? (
            <div className="flex-grow flex flex-col items-center justify-center p-8 text-center min-h-[460px] bg-cinema-bg/30">
              <div className="w-16 h-16 rounded-2xl bg-cinema-surface border border-cinema-border flex items-center justify-center text-cinema-gold mb-4 shadow-inner">
                <Film className="w-8 h-8 opacity-80" />
              </div>
              <h3 className="text-base font-bold text-white mb-2">
                Tertulia Cinéfila & Conversaciones Privadas
              </h3>
              <p className="text-xs text-cinema-textSecondary max-w-sm leading-relaxed mb-6">
                Chatea libremente con tus amigos para coordinar salidas al cine, recomendar películas o debate en los Cineclubs de la comunidad.
              </p>
              <div className="flex flex-wrap items-center justify-center gap-3">
                <button
                  onClick={() => {
                    loadContactsDirectory();
                    setIsNewChatOpen(true);
                  }}
                  className="px-4 py-2 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-black text-xs font-bold flex items-center gap-2 shadow"
                >
                  <UserPlus className="w-3.5 h-3.5" />
                  <span>Nuevo Chat 1 a 1</span>
                </button>
                <button
                  onClick={() => setIsJoinGroupOpen(true)}
                  className="px-4 py-2 rounded-xl bg-cinema-surface hover:bg-cinema-card border border-cinema-border text-cinema-textSecondary hover:text-white text-xs font-semibold flex items-center gap-2"
                >
                  <KeyRound className="w-3.5 h-3.5 text-cinema-gold" />
                  <span>Unirse con Código</span>
                </button>
              </div>
            </div>
          ) : (
            <>
              {/* Encabezado del Chat */}
              <div className="p-3.5 sm:p-4 border-b border-cinema-border bg-cinema-surface/40 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => {
                      setSelectedConvoId(null);
                      setSelectedGroupId(null);
                    }}
                    className="md:hidden p-1.5 -ml-1 rounded-lg bg-cinema-surface hover:bg-cinema-card text-cinema-textSecondary hover:text-white"
                    title="Volver"
                  >
                    <ArrowLeft className="w-4 h-4" />
                  </button>

                  {chatType === 'direct' && activeConvo ? (
                    <div className="flex items-center gap-3">
                      <img
                        src={activeConvo.participant.avatarUrl}
                        alt={activeConvo.participant.displayName}
                        className="w-9 h-9 rounded-full object-cover border border-cinema-border"
                      />
                      <div className="flex flex-col">
                        <div className="flex items-center gap-1.5">
                          <span className="text-xs font-bold text-white">
                            {activeConvo.participant.displayName}
                          </span>
                          <span className="text-[9px] px-1.5 py-0.2 rounded-full bg-black/60 text-cinema-textMuted border border-white/10 font-mono">
                            {activeConvo.participant.isMutual ? 'Amigo' : 'Comunidad'}
                          </span>
                        </div>
                        <span className="text-[10px] text-cinema-textMuted">
                          {activeConvo.participant.username} • En línea (Sincronizado)
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
                          Cineclub de debate cinéfilo
                        </span>
                      </div>
                    </div>
                  ) : null}
                </div>

                {/* Botón rápido: Compartir película */}
                <button
                  onClick={() => setIsShareMoviePickerOpen(true)}
                  className="px-3 py-1.5 rounded-xl bg-cinema-surface hover:bg-cinema-card border border-cinema-border text-cinema-gold text-xs font-semibold flex items-center gap-1.5 transition-colors"
                >
                  <Film className="w-3.5 h-3.5" />
                  <span className="hidden sm:inline">Compartir Película</span>
                </button>
              </div>

              {/* Área de Mensajes */}
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
                      {chatType === 'groups' && !isMe && (
                        <span className="text-[10px] font-semibold text-cinema-textMuted mb-1 ml-2">
                          {m.senderName}
                        </span>
                      )}

                      <div
                        className={`p-3.5 rounded-2xl flex flex-col gap-2 ${
                          isMe
                            ? 'bg-cinema-surface border border-cinema-border text-white rounded-br-none shadow-md'
                            : 'bg-cinema-card border border-cinema-border text-gray-200 rounded-bl-none shadow-md'
                        }`}
                      >
                        {m.text && <p className="text-xs sm:text-sm leading-relaxed">{m.text}</p>}

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
                <div ref={messagesEndRef} />
              </div>

              {/* Composer Input o Gate de Suscripción para Cineclubs */}
              {chatType === 'groups' && !currentUser.isPremium ? (
                <div className="p-3.5 border-t border-cinema-border bg-cinema-surface/70 flex flex-col sm:flex-row items-center justify-between gap-3">
                  <div className="flex items-center gap-2.5 text-xs text-cinema-textSecondary">
                    <Lock className="w-4 h-4 text-cinema-gold flex-shrink-0" />
                    <span>
                      Los Cineclubs de la Comunidad global requieren <strong>Suscripción Mensual</strong>. En el <strong>Plan Base</strong> puedes chatear libremente 1 a 1 con tus amigos.
                    </span>
                  </div>
                  <button
                    type="button"
                    onClick={() =>
                      onOpenSubscriptionModal?.(
                        'Para participar y debatir en los Cineclubs de la Comunidad global necesitas la suscripción mensual. En el Plan Base puedes chatear libremente 1 a 1 con tus amigos.'
                      )
                    }
                    className="px-3.5 py-1.5 rounded-xl bg-cinema-gold hover:bg-amber-400 text-black text-xs font-bold transition-all shadow whitespace-nowrap flex-shrink-0"
                  >
                    Activar Suscripción
                  </button>
                </div>
              ) : (
                <form
                  onSubmit={handleSendMessage}
                  className="p-3 border-t border-cinema-border bg-cinema-surface/40 flex items-center gap-2"
                >
                  <input
                    type="text"
                    value={inputText}
                    onChange={(e) => setInputText(e.target.value)}
                    placeholder={
                      chatType === 'direct'
                        ? 'Escribe un mensaje privado...'
                        : 'Debate con el cineclub...'
                    }
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
              )}
            </>
          )}
        </div>
      </div>

      {/* Modal: Iniciar Nuevo Chat (Regla: Amigos = Gratis, Extraños = Requiere Pro) */}
      {isNewChatOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="w-full max-w-lg rounded-3xl bg-cinema-card border border-cinema-border p-6 shadow-2xl flex flex-col gap-4">
            <div className="flex items-center justify-between pb-2 border-b border-cinema-border">
              <div className="flex flex-col">
                <h3 className="text-sm font-bold text-white flex items-center gap-2">
                  <UserPlus className="w-4 h-4 text-emerald-400" />
                  Iniciar Conversación Directa 1 a 1
                </h3>
                <span className="text-[11px] text-cinema-textMuted">
                  Amigos: 100% libre • Extraños/Comunidad: Requiere Cinéfilo Pro
                </span>
              </div>
              <button
                onClick={() => setIsNewChatOpen(false)}
                className="text-cinema-textMuted hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Buscador de contactos */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-cinema-textMuted" />
              <input
                type="text"
                value={searchContactText}
                onChange={(e) => setSearchContactText(e.target.value)}
                placeholder="Buscar por nombre o @usuario..."
                className="w-full pl-9 pr-3 py-2 rounded-xl bg-cinema-surface border border-cinema-border text-xs text-white placeholder-cinema-textMuted outline-none focus:border-cinema-gold"
              />
            </div>

            <div className="max-h-80 overflow-y-auto flex flex-col gap-4 pr-1">
              {/* Sección 1: Tus Amigos */}
              <div className="flex flex-col gap-1.5">
                <span className="text-[10px] font-bold uppercase tracking-wider text-emerald-400 flex items-center gap-1">
                  <span>★</span> Tus Amigos Agregados (Plan Base Libre)
                </span>
                {filteredFriends.length > 0 ? (
                  filteredFriends.map((f) => (
                    <button
                      key={f.id}
                      onClick={() => handleStartDirectChat({ ...f, isFriend: true })}
                      className="p-2.5 rounded-xl bg-cinema-surface/70 hover:bg-cinema-surface border border-cinema-border/60 flex items-center justify-between text-left transition-colors group"
                    >
                      <div className="flex items-center gap-3">
                        <img
                          src={f.avatarUrl}
                          alt={f.displayName}
                          className="w-9 h-9 rounded-full object-cover border border-emerald-500/40"
                        />
                        <div className="flex flex-col">
                          <span className="text-xs font-bold text-white group-hover:text-emerald-400 transition-colors">
                            {f.displayName}
                          </span>
                          <span className="text-[10px] text-cinema-textMuted">{f.username}</span>
                        </div>
                      </div>
                      <span className="text-[11px] font-semibold text-emerald-400 px-2.5 py-1 rounded-lg bg-emerald-500/10 border border-emerald-500/20">
                        Chatear
                      </span>
                    </button>
                  ))
                ) : (
                  <p className="text-xs text-cinema-textMuted italic p-2">
                    No se encontraron amigos con ese nombre.
                  </p>
                )}
              </div>

              {/* Sección 2: Comunidad / Extraños (Requiere Pro para el iniciador) */}
              <div className="flex flex-col gap-1.5 pt-2 border-t border-cinema-border/50">
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-bold uppercase tracking-wider text-indigo-400 flex items-center gap-1">
                    <Globe className="w-3 h-3" /> Otros Cinéfilos de la Comunidad (Extraños)
                  </span>
                  <span className="text-[9px] px-1.5 py-0.5 rounded bg-amber-500/15 text-cinema-gold font-mono border border-amber-500/30 flex items-center gap-1">
                    <Sparkles className="w-2.5 h-2.5 fill-cinema-gold" />
                    Requiere Pro
                  </span>
                </div>

                {filteredCommunity.length > 0 ? (
                  filteredCommunity.map((c) => (
                    <button
                      key={c.id}
                      onClick={() => handleStartDirectChat({ ...c, isFriend: false })}
                      className="p-2.5 rounded-xl bg-cinema-surface/70 hover:bg-cinema-surface border border-cinema-border/60 flex items-center justify-between text-left transition-colors group"
                    >
                      <div className="flex items-center gap-3">
                        <img
                          src={c.avatarUrl}
                          alt={c.displayName}
                          className="w-9 h-9 rounded-full object-cover border border-indigo-500/40"
                        />
                        <div className="flex flex-col">
                          <span className="text-xs font-bold text-white group-hover:text-cinema-gold transition-colors flex items-center gap-1.5">
                            {c.displayName}
                            {c.isPremium && <Sparkles className="w-2.5 h-2.5 text-cinema-gold fill-cinema-gold" />}
                          </span>
                          <span className="text-[10px] text-cinema-textMuted">{c.username}</span>
                        </div>
                      </div>
                      <div className="flex items-center gap-1.5">
                        {!currentUser.isPremium && <Lock className="w-3 h-3 text-cinema-gold" />}
                        <span className={`text-[11px] font-semibold px-2.5 py-1 rounded-lg ${
                          currentUser.isPremium
                            ? 'text-cinema-gold bg-amber-500/10 border border-amber-500/20'
                            : 'text-cinema-textMuted bg-white/5 border border-white/10'
                        }`}>
                          {currentUser.isPremium ? 'Chatear (Pro)' : 'Bloqueado (Pro)'}
                        </span>
                      </div>
                    </button>
                  ))
                ) : (
                  <p className="text-xs text-cinema-textMuted italic p-2">
                    No hay otros usuarios registrados en este momento.
                  </p>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Modal: Compartir Película */}
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

      {/* Modal: Crear Cineclub */}
      {isCreateGroupOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-3xl bg-cinema-card border border-cinema-border p-6 shadow-2xl flex flex-col gap-4">
            <div className="flex items-center justify-between pb-2 border-b border-cinema-border">
              <div className="flex flex-col">
                <h3 className="text-sm font-bold text-white flex items-center gap-2">
                  <Sparkles className="w-4 h-4 text-cinema-gold fill-cinema-gold" />
                  Crear Nuevo Cineclub Comunitario
                </h3>
                <span className="text-[11px] text-cinema-gold">Exclusivo Cinéfilo Pro</span>
              </div>
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
                  Crear Cineclub
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Unirse con Código */}
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
