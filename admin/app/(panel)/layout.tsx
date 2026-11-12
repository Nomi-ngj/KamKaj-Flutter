'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { AdminUser, APP_ENV, API_URL, session, signOut } from '@/lib/api';
import { Loading } from '@/components/ui';

const NAV = [
  { href: '/', label: 'Dashboard', icon: '◧' },
  { href: '/orders', label: 'Orders', icon: '🧾' },
  { href: '/stores', label: 'Stores', icon: '🏪' },
  { href: '/products', label: 'Products', icon: '📦' },
  { href: '/categories', label: 'Categories', icon: '🏷️' },
  { href: '/users', label: 'Customers', icon: '👥' },
  { href: '/rides', label: 'Rides', icon: '🚗' },
  { href: '/services', label: 'Services & vehicles', icon: '🛠️' },
  { href: '/settings', label: 'Settings', icon: '⚙️' },
];

export default function PanelLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [user, setUser] = useState<AdminUser | null>(null);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    if (!session.access) {
      router.replace(`/login?next=${encodeURIComponent(pathname)}`);
      return;
    }
    setUser(session.user);
  }, [pathname, router]);

  useEffect(() => setMenuOpen(false), [pathname]);

  if (!user) return <Loading />;

  const isActive = (href: string) => (href === '/' ? pathname === '/' : pathname.startsWith(href));

  return (
    <div className="min-h-screen">
      {APP_ENV !== 'production' && (
        <div className="bg-accent px-4 py-1 text-center text-xs font-medium text-white">
          {APP_ENV.toUpperCase()} — test data only · API {API_URL}
        </div>
      )}
      <div className="flex">
        <aside
          className={`${menuOpen ? 'block' : 'hidden'} fixed inset-y-0 z-40 w-60 shrink-0 border-r border-gray-200 bg-white md:sticky md:top-0 md:block md:h-screen`}
        >
          <div className="flex h-14 items-center gap-2 border-b border-gray-100 px-5">
            <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand text-sm font-bold text-white">K</span>
            <span className="font-semibold text-gray-900">KamKaj Admin</span>
          </div>
          <nav className="space-y-0.5 p-3">
            {NAV.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 rounded-lg px-3 py-2 text-sm ${
                  isActive(item.href) ? 'bg-brand-soft font-medium text-brand' : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                }`}
              >
                <span className="w-5 text-center">{item.icon}</span>
                {item.label}
              </Link>
            ))}
          </nav>
          <div className="absolute bottom-0 w-full border-t border-gray-100 p-4">
            <p className="truncate text-sm font-medium text-gray-800">
              {user.firstName} {user.lastName}
            </p>
            <p className="truncate text-xs text-gray-500">
              {user.email} · {user.role}
            </p>
            <button onClick={() => void signOut()} className="mt-2 text-xs font-medium text-red-600 hover:underline">
              Sign out
            </button>
          </div>
        </aside>
        <div className="min-w-0 flex-1">
          <div className="flex h-14 items-center border-b border-gray-200 bg-white px-4 md:hidden">
            <button onClick={() => setMenuOpen((v) => !v)} className="rounded p-2 text-gray-600 hover:bg-gray-100" aria-label="Menu">
              ☰
            </button>
            <span className="ml-2 font-semibold">KamKaj Admin</span>
          </div>
          <main className="mx-auto max-w-7xl p-4 md:p-8">{children}</main>
        </div>
      </div>
    </div>
  );
}
