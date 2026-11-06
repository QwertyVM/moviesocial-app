import { NextRequest, NextResponse } from "next/server";
import { getMovieByIdAction } from "@/actions/movies";

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const movie = await getMovieByIdAction(id);

    if (!movie) {
      return NextResponse.json(
        { error: `Película con ID ${id} no encontrada` },
        { status: 404 }
      );
    }

    return NextResponse.json({ movie });
  } catch (error: any) {
    return NextResponse.json(
      { error: error?.message || "Error al obtener detalle de la película" },
      { status: 500 }
    );
  }
}
