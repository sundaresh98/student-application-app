import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  try {
    // TODO: Fetch forms from database
    return NextResponse.json({ forms: [] })
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch forms' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    // TODO: Create form in database
    return NextResponse.json({ id: 'new-form-id' }, { status: 201 })
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to create form' },
      { status: 500 }
    )
  }
}
