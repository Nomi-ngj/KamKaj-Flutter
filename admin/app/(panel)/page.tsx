'use client';

import Link from 'next/link';
import { useApi } from '@/lib/hooks';
import { money } from '@/lib/format';
import { Card, ErrorBox, Loading, PageHeader, Stat } from '@/components/ui';
import { OrderRow, OrdersTable } from '@/components/orders-table';
import { BarChart } from '@/components/extras';

interface Dashboard {
  today: { orders: number; revenue: number };
  activeOrders: number;
  statusCounts: Record<string, number>;
  customers: { total: number; newThisWeek: number };
  stores: { total: number; active: number };
  series: { day: string; orders: number; revenue: number }[];
  topStores: { storeId: string; name: string; orders: number; revenue: number }[];
  recentOrders: OrderRow[];
}

export default function DashboardPage() {
  const { data, error, loading, reload } = useApi<Dashboard>('/admin/dashboard');

  if (loading && !data) return <Loading />;
  if (error) return <ErrorBox message={error} onRetry={reload} />;
  if (!data) return null;

  return (
    <>
      <PageHeader title="Dashboard" subtitle="Today’s numbers use Pakistan time." />
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <Stat label="Orders today" value={data.today.orders} hint="Excluding cancelled" />
        <Stat label="Revenue today" value={money(data.today.revenue)} />
        <Stat
          label="Active orders"
          value={<Link href="/orders?status=awaitingPayment,pending,inTransit" className="hover:text-brand">{data.activeOrders}</Link>}
          hint={`${data.statusCounts.awaitingPayment ?? 0} awaiting payment · ${data.statusCounts.inTransit ?? 0} in transit`}
        />
        <Stat label="Customers" value={data.customers.total} hint={`${data.customers.newThisWeek} new this week · ${data.stores.active}/${data.stores.total} stores active`} />
      </div>

      <div className="mt-6 grid gap-6 lg:grid-cols-3">
        <Card title="Revenue — last 14 days" className="lg:col-span-2">
          <BarChart data={data.series.map((d) => ({ label: d.day, value: d.revenue }))} format={money} />
        </Card>
        <Card title="Top stores (30 days)" padded={false}>
          <ul className="divide-y divide-gray-100">
            {data.topStores.map((s) => (
              <li key={s.storeId} className="flex items-center justify-between px-5 py-3 text-sm">
                <Link href={`/stores/${s.storeId}`} className="font-medium text-gray-800 hover:text-brand">
                  {s.name}
                </Link>
                <span className="text-right text-gray-500">
                  {s.orders} orders
                  <br />
                  <span className="text-xs">{money(s.revenue)}</span>
                </span>
              </li>
            ))}
            {!data.topStores.length && <li className="px-5 py-6 text-sm text-gray-500">No orders yet.</li>}
          </ul>
        </Card>
      </div>

      <Card title="Latest orders" className="mt-6" padded={false} actions={<Link href="/orders" className="text-sm text-brand hover:underline">View all</Link>}>
        <OrdersTable rows={data.recentOrders} />
      </Card>
    </>
  );
}
