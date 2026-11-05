import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "MovieSocial — Cine, Cartelera & Amigos",
  description: "Descubrimiento cinematográfico, cartelera local con salas y horarios, calificaciones oficiales (Rotten Tomatoes + IMDb) y conexión con amigos sin ruido.",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es" className="dark">
      <body className="bg-[#0B0C0E] text-gray-100 min-h-screen antialiased selection:bg-[#E5A93C]/30 selection:text-white">
        {children}
      </body>
    </html>
  );
}

