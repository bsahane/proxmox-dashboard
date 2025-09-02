// Global State Management with Zustand
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { ProxmoxTicket, ProxmoxVM, ProxmoxLXC, ProxmoxNode } from './proxmox';

interface AuthState {
  isAuthenticated: boolean;
  ticket: ProxmoxTicket | null;
  user: string | null;
  login: (ticket: ProxmoxTicket) => void;
  logout: () => void;
}

interface DashboardState {
  nodes: ProxmoxNode[];
  vms: ProxmoxVM[];
  lxcs: ProxmoxLXC[];
  selectedNode: string | null;
  refreshInterval: number;
  isLoading: boolean;
  error: string | null;
  setNodes: (nodes: ProxmoxNode[]) => void;
  setVMs: (vms: ProxmoxVM[]) => void;
  setLXCs: (lxcs: ProxmoxLXC[]) => void;
  setSelectedNode: (node: string | null) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  setRefreshInterval: (interval: number) => void;
}

interface UIState {
  theme: 'light' | 'dark' | 'system';
  sidebarCollapsed: boolean;
  viewMode: 'grid' | 'table';
  setTheme: (theme: 'light' | 'dark' | 'system') => void;
  toggleSidebar: () => void;
  setViewMode: (mode: 'grid' | 'table') => void;
}

// Authentication Store with persistence
export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      isAuthenticated: false,
      ticket: null,
      user: null,
      login: (ticket) => set({ 
        isAuthenticated: true, 
        ticket, 
        user: ticket.username 
      }),
      logout: () => set({ 
        isAuthenticated: false, 
        ticket: null, 
        user: null 
      }),
    }),
    {
      name: 'auth-store',
      partialize: (state) => ({ 
        isAuthenticated: state.isAuthenticated,
        ticket: state.ticket,
        user: state.user,
      }),
    }
  )
);

// Dashboard State Store
export const useDashboardStore = create<DashboardState>((set) => ({
  nodes: [],
  vms: [],
  lxcs: [],
  selectedNode: null,
  refreshInterval: 30000, // 30 seconds
  isLoading: false,
  error: null,
  setNodes: (nodes) => set({ nodes }),
  setVMs: (vms) => set({ vms }),
  setLXCs: (lxcs) => set({ lxcs }),
  setSelectedNode: (selectedNode) => set({ selectedNode }),
  setLoading: (isLoading) => set({ isLoading }),
  setError: (error) => set({ error }),
  setRefreshInterval: (refreshInterval) => set({ refreshInterval }),
}));

// UI State Store with persistence
export const useUIStore = create<UIState>()(
  persist(
    (set) => ({
      theme: 'system',
      sidebarCollapsed: false,
      viewMode: 'grid',
      setTheme: (theme) => set({ theme }),
      toggleSidebar: () => set((state) => ({ 
        sidebarCollapsed: !state.sidebarCollapsed 
      })),
      setViewMode: (viewMode) => set({ viewMode }),
    }),
    {
      name: 'ui-store',
    }
  )
);
