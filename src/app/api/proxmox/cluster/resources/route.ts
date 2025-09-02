import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    const authHeader = request.headers.get('authorization');
    const csrfToken = request.headers.get('csrfpreventiontoken');
    const { searchParams } = new URL(request.url);
    const type = searchParams.get('type') || '';

    if (!authHeader || !csrfToken) {
      return NextResponse.json({ error: 'Missing authentication' }, { status: 401 });
    }

    const url = `https://192.168.50.7:8006/api2/json/cluster/resources${type ? `?type=${type}` : ''}`;
    
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Authorization': authHeader,
        'CSRFPreventionToken': csrfToken,
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`Proxmox cluster resources failed with status ${response.status}:`, errorText);
      
      // If it's a 400/500 error and we're fetching LXCs, return empty array instead of error
      if ((response.status >= 400) && type === 'lxc') {
        console.log(`LXC endpoint returned ${response.status}, returning empty array (LXC not supported or no LXCs exist)`);
        return NextResponse.json({ data: [] });
      }
      
      throw new Error(`Failed to fetch cluster resources: ${response.status}`);
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Proxmox cluster resources error:', error);
    
    // If LXC fetch fails, return empty array instead of error
    if (request.url.includes('type=lxc')) {
      console.log('LXC fetch failed, returning empty array');
      return NextResponse.json({ data: [] });
    }
    
    return NextResponse.json(
      { error: 'Failed to fetch cluster resources' },
      { status: 500 }
    );
  }
}
