import { NextRequest, NextResponse } from 'next/server';

// Disable SSL certificate verification for self-signed certificates
process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = "0";

export async function POST(request: NextRequest) {
  try {
    const { username, password } = await request.json();

    // Log authentication attempt
    console.log(`Authentication attempt for user: ${username}`);

    const response = await fetch('https://192.168.50.7:8006/api2/json/access/ticket', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        username,
        password,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`Proxmox auth failed with status ${response.status}:`, errorText);
      throw new Error(`Authentication failed: ${response.status}`);
    }

    const data = await response.json();
    console.log('Authentication successful for user:', username);
    
    return NextResponse.json(data);
  } catch (error) {
    console.error('Proxmox auth error:', error);
    
    // More detailed error messages
    let errorMessage = 'Authentication failed';
    if (error instanceof Error) {
      if (error.message.includes('ECONNREFUSED')) {
        errorMessage = 'Cannot connect to Proxmox server. Please check if the server is running.';
      } else if (error.message.includes('CERT')) {
        errorMessage = 'SSL certificate error. Please check Proxmox SSL configuration.';
      } else if (error.message.includes('401') || error.message.includes('Authentication failed')) {
        errorMessage = 'Invalid username or password. Please check your credentials and realm.';
      } else {
        errorMessage = error.message;
      }
    }
    
    return NextResponse.json(
      { error: errorMessage },
      { status: 401 }
    );
  }
}
