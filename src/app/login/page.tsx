'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useAuthStore } from '@/lib/store';
import { proxmoxAPI } from '@/lib/proxmox';
import { toast } from 'sonner';
import { Server, Lock, User, Eye, EyeOff } from 'lucide-react';

export default function LoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [realm, setRealm] = useState('pam');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();
  const login = useAuthStore((state) => state.login);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!username || !password) {
      toast.error('Please enter both username and password');
      return;
    }

    setIsLoading(true);
    
    try {
      // Proxmox requires username@realm format
      const fullUsername = username.includes('@') ? username : `${username}@${realm}`;
      const ticket = await proxmoxAPI.authenticate(fullUsername, password);
      login(ticket);
      toast.success('Login successful!');
      router.push('/dashboard');
    } catch (error) {
      console.error('Login error:', error);
      toast.error(error instanceof Error ? error.message : 'Login failed');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800 p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-2 text-center">
          <div className="mx-auto w-12 h-12 bg-blue-600 rounded-lg flex items-center justify-center mb-4">
            <Server className="h-6 w-6 text-white" />
          </div>
          <CardTitle className="text-2xl font-bold">Proxmox Dashboard</CardTitle>
          <CardDescription>
            Sign in to manage your virtual machines and containers
          </CardDescription>
        </CardHeader>
        
        <CardContent>
          <form onSubmit={handleLogin} className="space-y-4">
            <div className="space-y-2">
              <label htmlFor="username" className="text-sm font-medium">
                Username
              </label>
              <div className="relative">
                <User className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  id="username"
                  type="text"
                  placeholder="Enter your username"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="pl-10"
                  disabled={isLoading}
                  autoComplete="username"
                />
              </div>
            </div>
            
            <div className="space-y-2">
              <label htmlFor="realm" className="text-sm font-medium">
                Authentication Realm
              </label>
              <Select value={realm} onValueChange={setRealm} disabled={isLoading}>
                <SelectTrigger>
                  <SelectValue placeholder="Select realm" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="pam">PAM (Local Users)</SelectItem>
                  <SelectItem value="pve">PVE (Proxmox Users)</SelectItem>
                  <SelectItem value="ad">Active Directory</SelectItem>
                  <SelectItem value="ldap">LDAP</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <label htmlFor="password" className="text-sm font-medium">
                Password
              </label>
              <div className="relative">
                <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Enter your password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="pl-10 pr-10"
                  disabled={isLoading}
                  autoComplete="current-password"
                />
                <Button
                  type="button"
                  variant="ghost"
                  size="icon"
                  className="absolute right-0 top-0 h-full px-3 hover:bg-transparent"
                  onClick={() => setShowPassword(!showPassword)}
                  disabled={isLoading}
                >
                  {showPassword ? (
                    <EyeOff className="h-4 w-4 text-muted-foreground" />
                  ) : (
                    <Eye className="h-4 w-4 text-muted-foreground" />
                  )}
                </Button>
              </div>
            </div>
            
            <Button 
              type="submit" 
              className="w-full" 
              disabled={isLoading}
            >
              {isLoading ? 'Signing in...' : 'Sign in'}
            </Button>
          </form>
          
          <div className="mt-6 text-center text-sm text-muted-foreground">
            <div className="bg-muted/50 rounded-lg p-3">
              <p className="font-medium mb-1">Proxmox Server</p>
              <p className="text-xs">https://192.168.50.7:8006</p>
              <p className="text-xs mt-2 text-blue-600">
                💡 Try: root@pam or your-user@pve
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
