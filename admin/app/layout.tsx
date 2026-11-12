import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'KamKaj Admin',
  description: 'Manage stores, products, orders and customers for KamKaj Pro.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen antialiased">{children}</body>
    </html>
  );
}
