import { NextRequest, NextResponse } from 'next/server';

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ node: string; vmid: string; snapname: string }> }
) {
  try {
    const authHeader = request.headers.get('authorization');
    const csrfToken = request.headers.get('csrfpreventiontoken');

    if (!authHeader || !csrfToken) {
      return NextResponse.json({ error: 'Missing authentication' }, { status: 401 });
    }

    const { node, vmid, snapname } = await params;
    console.log(`Rolling back VM ${vmid} on node ${node} to snapshot ${snapname}`);

    const proxmoxHost = process.env.PROXMOX_HOST || 'https://192.168.50.7:8006';
    const response = await fetch(`${proxmoxHost}/api2/json/nodes/${node}/qemu/${vmid}/snapshot/${snapname}/rollback`, {
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
      console.error(`Failed to rollback VM ${vmid} to snapshot ${snapname} with status ${response.status}:`, errorText);
      throw new Error(`Failed to rollback snapshot: ${response.status}`);
    }

    const data = await response.json();
    console.log(`VM ${vmid} rollback to snapshot ${snapname} task initiated:`, data);
    return NextResponse.json(data);
  } catch (error) {
    console.error('Snapshot rollback error:', error);
    return NextResponse.json(
      { error: 'Failed to rollback snapshot' },
      { status: 500 }
    );
  }
}
