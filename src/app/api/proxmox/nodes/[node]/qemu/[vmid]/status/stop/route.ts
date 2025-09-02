import { NextRequest, NextResponse } from 'next/server';

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ node: string; vmid: string }> }
) {
  try {
    const authHeader = request.headers.get('authorization');
    const csrfToken = request.headers.get('csrfpreventiontoken');

    if (!authHeader || !csrfToken) {
      return NextResponse.json({ error: 'Missing authentication' }, { status: 401 });
    }

    const { node, vmid } = await params;
    console.log(`Stopping VM ${vmid} on node ${node}`);

    const proxmoxHost = process.env.PROXMOX_HOST || 'https://192.168.50.7:8006';
    const response = await fetch(`${proxmoxHost}/api2/json/nodes/${node}/qemu/${vmid}/status/stop`, {
      method: 'POST',
      headers: {
        'Authorization': authHeader,
        'CSRFPreventionToken': csrfToken,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: '', // Proxmox expects form data, not JSON
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`Failed to stop VM ${vmid} with status ${response.status}:`, errorText);
      throw new Error(`Failed to stop VM: ${response.status}`);
    }

    const data = await response.json();
    console.log(`VM ${vmid} stop task initiated:`, data);
    return NextResponse.json(data);
  } catch (error) {
    console.error('VM stop error:', error);
    return NextResponse.json(
      { error: 'Failed to stop VM' },
      { status: 500 }
    );
  }
}
