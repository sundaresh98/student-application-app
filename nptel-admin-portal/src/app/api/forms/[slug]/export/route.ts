import { NextRequest, NextResponse } from 'next/server'

export async function GET(
  request: NextRequest,
  { params }: { params: { slug: string } }
) {
  try {
    // TODO: Export form responses as CSV
    const csv = 'id,email,timestamp\n'
    return new NextResponse(csv, {
      headers: {
        'Content-Type': 'text/csv',
        'Content-Disposition': `attachment; filename="responses_${params.slug}.csv"`,
      },
    })
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to export responses' },
      { status: 500 }
    )
  }
}
