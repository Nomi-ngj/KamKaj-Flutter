'use client';

import Link from 'next/link';
import { useState } from 'react';
import { Page } from '@/lib/api';
import type { StoreRow } from '@/lib/types';
import { useApi, useDebounced } from '@/lib/hooks';
import { money } from '@/lib/format';
import { Badge, Card, ErrorBox, Input, LinkButton, Loading, PageHeader, Pagination, Select, Table, Td, Thumb } from '@/components/ui';

export default function StoresPage() {
  const [search, setSearch] = useState('');
  const [active, setActive] = useState('');
  const [page, setPage] = useState(1);
  const q = useDebounced(search);
  const { data, error, loading, reload } = useApi<Page<StoreRow>>('/admin/stores', { search: q, active, page, pageSize: 20 });

  return (
    <>
      <PageHeader
        title="Stores"
        subtitle="Customers only see active stores whose delivery radius covers their location."
        actions={<LinkButton href="/stores/new">+ Add store</LinkButton>}
      />
      <div className="mb-4 flex flex-wrap gap-2">
        <Input className="max-w-xs" placeholder="Search name or address" value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} />
        <Select className="max-w-40" value={active} onChange={(e) => { setActive(e.target.value); setPage(1); }}>
          <option value="">All stores</option>
          <option value="true">Active</option>
          <option value="false">Inactive</option>
        </Select>
      </div>
      {error && <ErrorBox message={error} onRetry={reload} />}
      <Card padded={false}>
        {loading && !data ? (
          <Loading />
        ) : (
          <Table head={['Store', 'City', 'Radius', 'Hours', 'Fee', 'Products', 'Orders', 'Status']} empty={!data?.data.length}>
            {data?.data.map((s) => (
              <tr key={s.id} className="hover:bg-gray-50">
                <Td>
                  <Link href={`/stores/${s.id}`} className="flex items-center gap-3">
                    <Thumb src={s.imageUrl} alt={s.name} />
                    <span>
                      <span className="block font-medium text-gray-900 hover:text-brand">{s.name}</span>
                      <span className="block text-xs text-gray-500">{s.address}</span>
                    </span>
                  </Link>
                </Td>
                <Td>{s.city}</Td>
                <Td>{s.deliveryRadiusKm} km</Td>
                <Td className="whitespace-nowrap">{s.opensAt && s.closesAt ? `${s.opensAt}–${s.closesAt}` : '24/7'}</Td>
                <Td className="whitespace-nowrap">{money(s.deliveryFee)}</Td>
                <Td>
                  <Link href={`/products?storeId=${s.id}`} className="text-brand hover:underline">{s.productCount}</Link>
                </Td>
                <Td>{s.orderCount}</Td>
                <Td>
                  <div className="flex flex-wrap gap-1">
                    <Badge tone={s.isActive ? 'green' : 'gray'}>{s.isActive ? 'Active' : 'Inactive'}</Badge>
                    {s.isFeatured && <Badge tone="amber">Featured</Badge>}
                  </div>
                </Td>
              </tr>
            ))}
          </Table>
        )}
        {data && <Pagination page={data.page} pageSize={data.pageSize} total={data.total} onPage={setPage} />}
      </Card>
    </>
  );
}
