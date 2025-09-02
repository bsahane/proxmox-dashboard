import { NextResponse } from 'next/server';
import { config, validateConfig } from '@/lib/config';

export async function GET() {
  try {
    // Validate configuration
    const validation = validateConfig();
    
    if (!validation.valid) {
      return NextResponse.json(
        { 
          error: 'Invalid configuration',
          details: validation.errors 
        },
        { status: 400 }
      );
    }

    // Return safe client configuration
    const clientConfig = {
      guacamole: {
        host: config.guacamole.host,
      },
      dashboard: {
        refreshInterval: config.dashboard.refreshInterval,
      },
      app: {
        debugLogging: config.app.debugLogging,
      },
    };

    return NextResponse.json({
      success: true,
      config: clientConfig,
    });
  } catch (error) {
    console.error('Config API error:', error);
    return NextResponse.json(
      { error: 'Failed to get configuration' },
      { status: 500 }
    );
  }
}
