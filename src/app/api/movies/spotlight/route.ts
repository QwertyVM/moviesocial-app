import { NextRequest, NextResponse } from "next/server";
import { getCinephileSpotlight } from "@/actions/movies";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const country = searchParams.get("country") || "PE";

    const spotlight = await getCinephileSpotlight(country);

    return NextResponse.json({ spotlight });
  } catch (error: any) {
    return NextResponse.json(
      { error: error?.message || "Error al obtener spotlight cinéfilo" },
      { status: 500 }
    );
  }
}
