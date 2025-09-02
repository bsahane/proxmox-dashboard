'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore, useDashboardStore, useUIStore } from '@/lib/store';
import { proxmoxAPI, ProxmoxVM, ProxmoxLXC } from '@/lib/proxmox';
import { VMCard } from '@/components/dashboard/vm-card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { 
  Select, 
  SelectContent, 
  SelectItem, 
  SelectTrigger, 
  SelectValue 
} from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';

import { Skeleton } from '@/components/ui/skeleton';
import { 
  Search, 
  Grid3X3, 
  List, 
  RefreshCw,
  Server,
  Monitor,
  Container,
  LogOut,
  Settings
} from 'lucide-react';
import { toast } from 'sonner';

export default function DashboardPage() {
  const router = useRouter();
  const { isAuthenticated, user, logout } = useAuthStore();
  const { 
    nodes, vms, lxcs, selectedNode, isLoading, error,
    setNodes, setVMs, setLXCs, setSelectedNode, setLoading, setError
  } = useDashboardStore();
  const { viewMode, setViewMode } = useUIStore();

  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [autoRefresh, setAutoRefresh] = useState(true);

  // Redirect if not authenticated
  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login');
    }
  }, [isAuthenticated, router]);

  // Load initial data
  // Load application configuration
  useEffect(() => {
    const loadConfig = async () => {
      try {
        const response = await fetch('/api/config');
        if (response.ok) {
          const data = await response.json();
          if (setAppConfig) {
            setAppConfig(data.config);
          }
        }
      } catch (error) {
        console.error('Failed to load config:', error);
      }
    };
    loadConfig();
  }, [setAppConfig]);

  useEffect(() => {
    if (isAuthenticated) {
      loadDashboardData();
    }
  }, [isAuthenticated]); // loadDashboardData is defined inside component, so excluding it is intentional

  // Auto-refresh data
  useEffect(() => {
    if (!autoRefresh || !isAuthenticated) return;

    const interval = setInterval(() => {
      loadDashboardData();
    }, 30000); // 30 seconds

    return () => clearInterval(interval);
  }, [autoRefresh, isAuthenticated]); // loadDashboardData is defined inside component, so excluding it is intentional

  const loadDashboardData = async () => {
    setLoading(true);
    setError(null);

    try {
      // Load nodes first, then VMs and LXCs
      const nodesData = await proxmoxAPI.getNodes();
      setNodes(nodesData);

      // Load VMs and LXCs in parallel, but handle LXC failures gracefully
      const [vmsResult, lxcsResult] = await Promise.allSettled([
        proxmoxAPI.getVMs(),
        proxmoxAPI.getLXCs()
      ]);

      // Handle VMs
      if (vmsResult.status === 'fulfilled') {
        setVMs(vmsResult.value || []);
      } else {
        console.error('Failed to load VMs:', vmsResult.reason);
        setVMs([]);
      }

      // Handle LXCs - don't fail if LXCs can't be loaded
      if (lxcsResult.status === 'fulfilled') {
        setLXCs(lxcsResult.value || []);
      } else {
        console.warn('Failed to load LXCs (this is okay if none exist):', lxcsResult.reason);
        setLXCs([]);
      }

      toast.success('Dashboard data loaded successfully');
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
      setError(error instanceof Error ? error.message : 'Failed to load data');
      toast.error('Failed to load basic dashboard data');
    } finally {
      setLoading(false);
    }
  };

  const handleVMAction = async (action: string, vm: ProxmoxVM | ProxmoxLXC, type: 'vm' | 'lxc', snapname?: string) => {
    try {
      
      switch (action) {
        case 'start':
          await (type === 'vm' 
            ? proxmoxAPI.startVM(vm.node, vm.vmid)
            : proxmoxAPI.startLXC(vm.node, vm.vmid));
          toast.success(`${type.toUpperCase()} ${vm.vmid} start initiated`);
          break;
        case 'stop':
          await (type === 'vm'
            ? proxmoxAPI.stopVM(vm.node, vm.vmid)
            : proxmoxAPI.stopLXC(vm.node, vm.vmid));
          toast.success(`${type.toUpperCase()} ${vm.vmid} stop initiated`);
          break;
        case 'reset':
          if (type === 'vm') {
            await proxmoxAPI.resetVM(vm.node, vm.vmid);
            toast.success(`VM ${vm.vmid} reset initiated`);
          }
          break;
        case 'console':
          // Open Guacamole console in new tab using configured host
          const guacamoleHost = appConfig?.guacamole?.host || 'http://192.168.50.183:8080';
          const guacamoleUrl = `${guacamoleHost}/guacamole/#/client/${vm.vmid}`;
          window.open(guacamoleUrl, '_blank');
          return;
        case 'snapshot':
          if (snapname && type === 'vm') {
            await proxmoxAPI.rollbackSnapshot(vm.node, vm.vmid, snapname);
            toast.success(`VM ${vm.vmid} restored to snapshot: ${snapname}`);
          }
          break;
      }

      // Refresh data after action
      setTimeout(loadDashboardData, 2000);
    } catch (error) {
      console.error(`Failed to ${action} ${type}:`, error);
      toast.error(`Failed to ${action} ${type.toUpperCase()}`);
    }
  };

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  // Filter and search logic
  const filteredVMs = vms.filter(vm => {
    const matchesSearch = !searchQuery || 
      vm.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      vm.vmid.toString().includes(searchQuery);
    
    const matchesStatus = statusFilter === 'all' || vm.status === statusFilter;
    const matchesNode = !selectedNode || vm.node === selectedNode;
    
    return matchesSearch && matchesStatus && matchesNode;
  });

  const filteredLXCs = lxcs.filter(lxc => {
    const matchesSearch = !searchQuery || 
      lxc.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      lxc.vmid.toString().includes(searchQuery);
    
    const matchesStatus = statusFilter === 'all' || lxc.status === statusFilter;
    const matchesNode = !selectedNode || lxc.node === selectedNode;
    
    return matchesSearch && matchesStatus && matchesNode;
  });

  const allItems = [...filteredVMs, ...filteredLXCs].sort((a, b) => a.vmid - b.vmid);

  const getStatusCounts = () => {
    const allVMs = [...vms, ...lxcs];
    return {
      total: allVMs.length,
      running: allVMs.filter(vm => vm.status === 'running').length,
      stopped: allVMs.filter(vm => vm.status === 'stopped').length,
    };
  };

  const statusCounts = getStatusCounts();

  if (!isAuthenticated) {
    return <div>Redirecting...</div>;
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <Server className="h-6 w-6 text-blue-600" />
                <h1 className="text-xl font-bold">Proxmox Dashboard</h1>
              </div>
              <Badge variant="outline">
                Welcome, {user}
              </Badge>
            </div>
            
            <div className="flex items-center space-x-4">
              <Button
                variant="ghost"
                size="icon"
                onClick={loadDashboardData}
                disabled={isLoading}
              >
                <RefreshCw className={`h-4 w-4 ${isLoading ? 'animate-spin' : ''}`} />
              </Button>
              <Button variant="ghost" size="icon">
                <Settings className="h-4 w-4" />
              </Button>
              <Button variant="ghost" size="icon" onClick={handleLogout}>
                <LogOut className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-6">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-card rounded-lg border p-4">
            <div className="flex items-center space-x-2">
              <Monitor className="h-5 w-5 text-blue-600" />
              <span className="text-sm font-medium">Total VMs</span>
            </div>
            <p className="text-2xl font-bold">{vms.length}</p>
          </div>
          <div className="bg-card rounded-lg border p-4">
            <div className="flex items-center space-x-2">
              <Container className="h-5 w-5 text-green-600" />
              <span className="text-sm font-medium">Total LXCs</span>
            </div>
            <p className="text-2xl font-bold">{lxcs.length}</p>
          </div>
          <div className="bg-card rounded-lg border p-4">
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 bg-green-500 rounded-full" />
              <span className="text-sm font-medium">Running</span>
            </div>
            <p className="text-2xl font-bold">{statusCounts.running}</p>
          </div>
          <div className="bg-card rounded-lg border p-4">
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 bg-red-500 rounded-full" />
              <span className="text-sm font-medium">Stopped</span>
            </div>
            <p className="text-2xl font-bold">{statusCounts.stopped}</p>
          </div>
        </div>

        {/* Filters and Controls */}
        <div className="flex flex-col sm:flex-row gap-4 mb-6">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search VMs and LXCs..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10"
            />
          </div>
          
          <Select value={statusFilter} onValueChange={setStatusFilter}>
            <SelectTrigger className="w-full sm:w-40">
              <SelectValue placeholder="Status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Status</SelectItem>
              <SelectItem value="running">Running</SelectItem>
              <SelectItem value="stopped">Stopped</SelectItem>
              <SelectItem value="suspended">Suspended</SelectItem>
            </SelectContent>
          </Select>

          <Select value={selectedNode || 'all'} onValueChange={(value) => 
            setSelectedNode(value === 'all' ? null : value)
          }>
            <SelectTrigger className="w-full sm:w-40">
              <SelectValue placeholder="Node" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Nodes</SelectItem>
              {nodes.map(node => (
                <SelectItem key={node.node} value={node.node}>
                  {node.node}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          <div className="flex items-center space-x-2">
            <Button
              variant={viewMode === 'grid' ? 'default' : 'outline'}
              size="icon"
              onClick={() => setViewMode('grid')}
            >
              <Grid3X3 className="h-4 w-4" />
            </Button>
            <Button
              variant={viewMode === 'table' ? 'default' : 'outline'}
              size="icon"
              onClick={() => setViewMode('table')}
            >
              <List className="h-4 w-4" />
            </Button>
          </div>

          <div className="flex items-center space-x-2">
            <label htmlFor="auto-refresh" className="text-sm font-medium">
              Auto-refresh
            </label>
            <Switch
              id="auto-refresh"
              checked={autoRefresh}
              onCheckedChange={setAutoRefresh}
            />
          </div>
        </div>

        {/* Loading State */}
        {isLoading && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {Array.from({ length: 6 }).map((_, i) => (
              <Skeleton key={i} className="h-64 rounded-lg" />
            ))}
          </div>
        )}

        {/* Error State */}
        {error && (
          <div className="text-center py-8">
            <p className="text-red-600 mb-4">{error}</p>
            <Button onClick={loadDashboardData}>
              <RefreshCw className="mr-2 h-4 w-4" />
              Retry
            </Button>
          </div>
        )}

        {/* VM/LXC Grid */}
        {!isLoading && !error && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {allItems.map((item) => {

              const type = vms.find(vm => vm.vmid === item.vmid) ? 'vm' : 'lxc';
              
              return (
                <VMCard
                  key={`${type}-${item.vmid}`}
                  vm={item}
                  type={type}
                  onStart={() => handleVMAction('start', item, type)}
                  onStop={() => handleVMAction('stop', item, type)}
                  onReset={() => handleVMAction('reset', item, type)}
                  onConsole={() => handleVMAction('console', item, type)}
                  onSnapshot={type === 'vm' ? (snapname: string) => handleVMAction('snapshot', item, type, snapname) : undefined}
                />
              );
            })}
          </div>
        )}

        {/* Empty State */}
        {!isLoading && !error && allItems.length === 0 && (
          <div className="text-center py-8">
            <Server className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
            <h3 className="text-lg font-medium mb-2">No VMs or LXCs found</h3>
            <p className="text-muted-foreground">
              {searchQuery || statusFilter !== 'all' || selectedNode
                ? 'Try adjusting your filters'
                : 'No virtual machines or containers available'
              }
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
