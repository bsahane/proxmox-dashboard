'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { 
  DropdownMenu, 
  DropdownMenuContent, 
  DropdownMenuItem, 
  DropdownMenuTrigger,
  DropdownMenuSeparator
} from '@/components/ui/dropdown-menu';
import { 
  Play, 
  Square, 
  RotateCcw, 
  Monitor, 
  MoreVertical,
  Cpu,
  HardDrive,
  Clock
} from 'lucide-react';
import { ProxmoxVM, ProxmoxLXC } from '@/lib/proxmox';
import { cn } from '@/lib/utils';

interface VMCardProps {
  vm: ProxmoxVM | ProxmoxLXC;
  type: 'vm' | 'lxc';
  onStart: () => void;
  onStop: () => void;
  onReset: () => void;
  onConsole: () => void;
  onSnapshot?: () => void;
}

export function VMCard({ vm, type, onStart, onStop, onReset, onConsole, onSnapshot }: VMCardProps) {
  const isRunning = vm.status === 'running';
  const isStopped = vm.status === 'stopped';
  
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'running':
        return 'bg-green-500';
      case 'stopped':
        return 'bg-red-500';
      case 'suspended':
        return 'bg-yellow-500';
      default:
        return 'bg-gray-500';
    }
  };

  const formatUptime = (uptime?: number) => {
    if (!uptime) return 'N/A';
    const days = Math.floor(uptime / 86400);
    const hours = Math.floor((uptime % 86400) / 3600);
    const minutes = Math.floor((uptime % 3600) / 60);
    
    if (days > 0) return `${days}d ${hours}h`;
    if (hours > 0) return `${hours}h ${minutes}m`;
    return `${minutes}m`;
  };

  const formatBytes = (bytes: number) => {
    if (!bytes) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`;
  };

  const getMemoryPercentage = () => {
    if (!vm.maxmem || !vm.mem) return 0;
    return (vm.mem / vm.maxmem) * 100;
  };

  const getCPUPercentage = () => {
    return vm.cpu * 100;
  };

  return (
    <Card className="hover:shadow-lg transition-shadow duration-200">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <div className={cn(
              'w-3 h-3 rounded-full',
              getStatusColor(vm.status)
            )} />
            <CardTitle className="text-lg font-semibold truncate">
              {vm.name || `${type.toUpperCase()} ${vm.vmid}`}
            </CardTitle>
          </div>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" className="h-8 w-8">
                <MoreVertical className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem onClick={onConsole}>
                <Monitor className="mr-2 h-4 w-4" />
                Console
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              {isRunning && (
                <DropdownMenuItem onClick={onStop}>
                  <Square className="mr-2 h-4 w-4" />
                  Stop
                </DropdownMenuItem>
              )}
              {isStopped && (
                <DropdownMenuItem onClick={onStart}>
                  <Play className="mr-2 h-4 w-4" />
                  Start
                </DropdownMenuItem>
              )}
              {isRunning && (
                <DropdownMenuItem onClick={onReset}>
                  <RotateCcw className="mr-2 h-4 w-4" />
                  Reset
                </DropdownMenuItem>
              )}
              {onSnapshot && type === 'vm' && (
                <DropdownMenuItem onClick={onSnapshot}>
                  <Clock className="mr-2 h-4 w-4" />
                  Restore Snapshot
                </DropdownMenuItem>
              )}
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
        <div className="flex items-center space-x-2">
          <Badge variant="outline" className="text-xs">
            {type.toUpperCase()} {vm.vmid}
          </Badge>
          <Badge variant="outline" className="text-xs">
            {vm.node}
          </Badge>
          <Badge 
            variant={isRunning ? 'default' : 'secondary'}
            className="text-xs capitalize"
          >
            {vm.status}
          </Badge>
        </div>
      </CardHeader>
      
      <CardContent className="space-y-4">
        {/* Resource Usage */}
        <div className="space-y-2">
          <div className="flex items-center justify-between text-sm">
            <div className="flex items-center space-x-1">
              <Cpu className="h-4 w-4 text-muted-foreground" />
              <span>CPU</span>
            </div>
            <span className="font-medium">{getCPUPercentage().toFixed(1)}%</span>
          </div>
          <div className="w-full bg-muted rounded-full h-2">
            <div 
              className="bg-blue-500 h-2 rounded-full transition-all duration-300" 
              style={{ width: `${Math.min(getCPUPercentage(), 100)}%` }}
            />
          </div>
        </div>

        <div className="space-y-2">
          <div className="flex items-center justify-between text-sm">
            <div className="flex items-center space-x-1">
              <HardDrive className="h-4 w-4 text-muted-foreground" />
              <span>Memory</span>
            </div>
            <span className="font-medium">
              {formatBytes(vm.mem)} / {formatBytes(vm.maxmem)}
            </span>
          </div>
          <div className="w-full bg-muted rounded-full h-2">
            <div 
              className="bg-green-500 h-2 rounded-full transition-all duration-300" 
              style={{ width: `${Math.min(getMemoryPercentage(), 100)}%` }}
            />
          </div>
        </div>

        {/* Uptime */}
        {isRunning && vm.uptime && (
          <div className="flex items-center justify-between text-sm">
            <div className="flex items-center space-x-1">
              <Clock className="h-4 w-4 text-muted-foreground" />
              <span>Uptime</span>
            </div>
            <span className="font-medium">{formatUptime(vm.uptime)}</span>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex space-x-2 pt-2">
          {isStopped && (
            <Button size="sm" onClick={onStart} className="flex-1">
              <Play className="mr-1 h-4 w-4" />
              Start
            </Button>
          )}
          {isRunning && (
            <>
              <Button size="sm" variant="outline" onClick={onStop} className="flex-1">
                <Square className="mr-1 h-4 w-4" />
                Stop
              </Button>
              <Button size="sm" variant="outline" onClick={onConsole}>
                <Monitor className="mr-1 h-4 w-4" />
                Console
              </Button>
            </>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
