#!/bin/bash
# Compilar e iniciar MovieSocial Web en producción local (Next.js + Prisma)
echo "🚀 Compilando MovieSocial Web..."
npm run build

echo "🎬 Iniciando servidor Next.js en http://localhost:3000..."
npm run start
