'use client';

import Link from 'next/link';
import { Suspense, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Page } from '@/lib/api';
import { useApi, useDebounced } from '@/lib/hooks';
import { money } from '@/lib/format';
import type { ProductRow, StoreRow } from '@/lib/types';
import { Badge, Card, ErrorBox, Input, LinkButton, Loading, PageHeader, Pagination, Select, Table, Td, Thumb } from '@/components/ui';

function ProductsList() {
  const router = useRouter();
  const params = useSearchParams();
  const storeId = params.get('storeId') ?? '';
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const q = useDebounced(search);
  const stores = useApi<Page<StoreRow>>('/admin/stores', { pageSize: 100 });
  const { data, error, loading, reload } = useApi<Page<ProductRow>>('/admin/products', { storeId, search: q, page, pageSize: 25 });

  return (
    <>
      <PageHeader
        title="Products"
        subtitle="“Daily pick” products appear on the home screen for customers near their store."
        actions={<LinkButton href={`/products/new${storeId ? `?storeId=${storeId}` : ''}`}>+ Add product</LinkButton>}
      />
      <div className="mb-4 flex flex-wrap gap-2">
        <Select
          className="max-w-64"
          value={storeId}
          onChange={(e) => {
            setPage(1);
            router.replace(e.target.value ? `/products?storeId=${e.target.value}` : '/products');
          }}
        >
          <option value="">All stores</option>
          {stores.data?.data.map((s) => (
            <option key={s.id} value={s.id}>
              {s.name} ({s.city})
            </option>
          ))}
        </Select>
        <Input className="max-w-xs" placeholder="Search products" value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} />
      </div>
      {error && <ErrorBox message={error} onRetry={reload} />}
      <Card padded={false}>
        {loading && !data ? (
          <Loading />
        ) : (
          <Table head={['Product', 'Store', 'Section', 'Price', 'Status']} empty={!data?.data.length}>
            {data?.data.map((p) => (
              <tr key={p.id} className="hover:bg-gray-50">
                <Td>
                  <Link href={`/products/${p.id}`} className="flex items-center gap-3">
                    <Thumb src={p.imageUrl} alt={p.name} />
                    <span>
                      <span className="block font-medium text-gray-900 hover:text-brand">{p.name}</span>
                      {p.unit && <span className="block text-xs text-gray-500">per {p.unit}</span>}
                    </span>
                  </Link>
                </Td>
                <Td>{p.storeName}</Td>
                <Td>{p.section ?? '—'}</Td>
                <Td className="whitespace-nowrap">{money(p.price)}</Td>
                <Td>
                  <div className="flex flex-wrap gap-1">
                    <Badge tone={p.isAvailable ? 'green' : 'red'}>{p.isAvailable ? 'In stock' : 'Out of stock'}</Badge>
                    {p.isDailyPick && <Badge tone="amber">Daily pick</Badge>}
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

export default function ProductsPage() {
  return (
    <Suspense fallback={<Loading />}>
      <ProductsList />
    </Suspense>
  );
}
