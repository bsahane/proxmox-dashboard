// Proxmox API Client
import axios from 'axios';

export interface ProxmoxConfig {
  host: string;
  username: string;
  password: string;
}

export interface ProxmoxTicket {
  ticket: string;
  CSRFPreventionToken: string;
  username: string;
}

export interface ProxmoxNode {
  node: string;
  status: 'online' | 'offline';
  uptime: number;
  cpu: number;
  mem: number;
  maxmem: number;
  disk: number;
  maxdisk: number;
}

export interface ProxmoxVM {
  vmid: number;
  name: string;
  node: string;
  status: 'running' | 'stopped' | 'suspended';
  cpu: number;
  mem: number;
  maxmem: number;
  disk: number;
  maxdisk: number;
  uptime?: number;
  template?: boolean;
}

export interface ProxmoxLXC {
  vmid: number;
  name: string;
  node: string;
  status: 'running' | 'stopped';
  cpu: number;
  mem: number;
  maxmem: number;
  disk: number;
  maxdisk: number;
  uptime?: number;
  template?: boolean;
}

export class ProxmoxAPI {
  private baseURL: string;
  private ticket?: ProxmoxTicket;

  constructor(_host: string) {
    // Use Next.js API routes for proxying to avoid CORS issues
    this.baseURL = `/api/proxmox`;
  }

  async authenticate(username: string, password: string): Promise<ProxmoxTicket> {
    try {
      const response = await axios.post('/api/proxmox/auth', {
        username,
        password,
      }, {
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: 10000,
      });

      this.ticket = response.data.data;
      return this.ticket!;
    } catch (error) {
      console.error('Proxmox authentication failed:', error);
      throw new Error('Authentication failed. Please check your credentials.');
    }
  }

  private getHeaders() {
    if (!this.ticket) {
      throw new Error('Not authenticated. Please login first.');
    }

    return {
      'Authorization': `PVEAuthCookie=${this.ticket.ticket}`,
      'CSRFPreventionToken': this.ticket.CSRFPreventionToken,
      'Content-Type': 'application/json',
    };
  }

  async getNodes(): Promise<ProxmoxNode[]> {
    try {
      const response = await axios.get('/api/proxmox/nodes', {
        headers: {
          'Authorization': `PVEAuthCookie=${this.ticket?.ticket}`,
          'CSRFPreventionToken': this.ticket?.CSRFPreventionToken || '',
        },
        timeout: 10000,
      });

      return response.data.data;
    } catch (error) {
      console.error('Failed to fetch nodes:', error);
      throw new Error('Failed to fetch nodes');
    }
  }

  async getVMs(_node?: string): Promise<ProxmoxVM[]> {
    try {
      const response = await axios.get('/api/proxmox/cluster/resources?type=vm', {
        headers: {
          'Authorization': `PVEAuthCookie=${this.ticket?.ticket}`,
          'CSRFPreventionToken': this.ticket?.CSRFPreventionToken || '',
        },
        timeout: 10000,
      });

      return response.data.data;
    } catch (error) {
      console.error('Failed to fetch VMs:', error);
      throw new Error('Failed to fetch VMs');
    }
  }

  async getLXCs(_node?: string): Promise<ProxmoxLXC[]> {
    try {
      const response = await axios.get('/api/proxmox/cluster/resources?type=lxc', {
        headers: {
          'Authorization': `PVEAuthCookie=${this.ticket?.ticket}`,
          'CSRFPreventionToken': this.ticket?.CSRFPreventionToken || '',
        },
        timeout: 10000,
      });

      return response.data.data;
    } catch (error) {
      console.error('Failed to fetch LXCs:', error);
      throw new Error('Failed to fetch LXCs');
    }
  }

  async startVM(node: string, vmid: number): Promise<string> {
    try {
      const response = await axios.post(
        `/api/proxmox/nodes/${node}/qemu/${vmid}/status/start`,
        {},
        {
          headers: {
            'Authorization': `PVEAuthCookie=${this.ticket?.ticket}`,
            'CSRFPreventionToken': this.ticket?.CSRFPreventionToken || '',
          },
          timeout: 30000,
        }
      );

      return response.data.data; // Task ID
    } catch (error) {
      console.error('Failed to start VM:', error);
      throw new Error('Failed to start VM');
    }
  }

  async stopVM(node: string, vmid: number): Promise<string> {
    try {
      const response = await axios.post(
        `/api/proxmox/nodes/${node}/qemu/${vmid}/status/stop`,
        {},
        {
          headers: {
            'Authorization': `PVEAuthCookie=${this.ticket?.ticket}`,
            'CSRFPreventionToken': this.ticket?.CSRFPreventionToken || '',
          },
          timeout: 30000,
        }
      );

      return response.data.data; // Task ID
    } catch (error) {
      console.error('Failed to stop VM:', error);
      throw new Error('Failed to stop VM');
    }
  }

  async resetVM(node: string, vmid: number): Promise<string> {
    try {
      const response = await axios.post(
        `/api/proxmox/nodes/${node}/qemu/${vmid}/status/reset`,
        {},
        {
          headers: {
            'Authorization': `PVEAuthCookie=${this.ticket?.ticket}`,
            'CSRFPreventionToken': this.ticket?.CSRFPreventionToken || '',
          },
          timeout: 30000,
        }
      );

      return response.data.data; // Task ID
    } catch (error) {
      console.error('Failed to reset VM:', error);
      throw new Error('Failed to reset VM');
    }
  }

  async startLXC(node: string, vmid: number): Promise<string> {
    try {
      const response = await axios.post(
        `${this.baseURL}/nodes/${node}/lxc/${vmid}/status/start`,
        {},
        {
          headers: this.getHeaders(),
          timeout: 30000,
        }
      );

      return response.data.data; // Task ID
    } catch (error) {
      console.error('Failed to start LXC:', error);
      throw new Error('Failed to start LXC');
    }
  }

  async stopLXC(node: string, vmid: number): Promise<string> {
    try {
      const response = await axios.post(
        `${this.baseURL}/nodes/${node}/lxc/${vmid}/status/stop`,
        {},
        {
          headers: this.getHeaders(),
          timeout: 30000,
        }
      );

      return response.data.data; // Task ID
    } catch (error) {
      console.error('Failed to stop LXC:', error);
      throw new Error('Failed to stop LXC');
    }
  }

  async getSnapshots(node: string, vmid: number): Promise<Array<Record<string, unknown>>> {
    try {
      const response = await axios.get(
        `/api/proxmox/nodes/${node}/qemu/${vmid}/snapshot`,
        {
          headers: {
            'Authorization': `PVEAuthCookie=${this.ticket?.ticket}`,
            'CSRFPreventionToken': this.ticket?.CSRFPreventionToken || '',
          },
          timeout: 10000,
        }
      );

      return response.data.data;
    } catch (error) {
      console.error('Failed to fetch snapshots:', error);
      throw new Error('Failed to fetch snapshots');
    }
  }

  async rollbackSnapshot(node: string, vmid: number, snapname: string): Promise<string> {
    try {
      const response = await axios.post(
        `${this.baseURL}/nodes/${node}/qemu/${vmid}/snapshot/${snapname}/rollback`,
        {},
        {
          headers: this.getHeaders(),
          timeout: 30000,
        }
      );

      return response.data.data; // Task ID
    } catch (error) {
      console.error('Failed to rollback snapshot:', error);
      throw new Error('Failed to rollback snapshot');
    }
  }

  async getTaskStatus(node: string, upid: string): Promise<Record<string, unknown>> {
    try {
      const response = await axios.get(
        `${this.baseURL}/nodes/${node}/tasks/${upid}/status`,
        {
          headers: this.getHeaders(),
          timeout: 10000,
        }
      );

      return response.data.data;
    } catch (error) {
      console.error('Failed to get task status:', error);
      throw new Error('Failed to get task status');
    }
  }
}

// Singleton instance
export const proxmoxAPI = new ProxmoxAPI('https://192.168.50.7:8006');
