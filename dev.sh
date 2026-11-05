#!/bin/bash
# Iniciar MovieSocial Web en modo desarrollo (Next.js + Prisma + Neon DB)
echo "🎬 Iniciando MovieSocial Web (Next.js + Prisma + Neon DB)..."

# Liberar puerto 3000 si está ocupado
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

npm run dev
