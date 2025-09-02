import { NextRequest, NextResponse } from 'next/server';

export async function GET(
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
    console.log(`Getting snapshots for VM ${vmid} on node ${node}`);

    const proxmoxHost = process.env.PROXMOX_HOST || 'https://192.168.50.7:8006';
    const response = await fetch(`${proxmoxHost}/api2/json/nodes/${node}/qemu/${vmid}/snapshot`, {
      method: 'GET',
      headers: {
        'Authorization': authHeader,
        'CSRFPreventionToken': csrfToken,
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`Failed to get snapshots for VM ${vmid} with status ${response.status}:`, errorText);
      throw new Error(`Failed to get snapshots: ${response.status}`);
    }

    const data = await response.json();
    console.log(`Snapshots for VM ${vmid}:`, data);
    return NextResponse.json(data);
  } catch (error) {
    console.error('Snapshot list error:', error);
    return NextResponse.json(
      { error: 'Failed to get snapshots' },
      { status: 500 }
    );
  }
}
