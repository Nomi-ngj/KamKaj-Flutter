'use client';

import Link from 'next/link';
import { useState } from 'react';
import { Page } from '@/lib/api';
import { useApi, useDebounced } from '@/lib/hooks';
import { timeAgo } from '@/lib/format';
import { Badge, Card, ErrorBox, Input, Loading, PageHeader, Pagination, Select, Table, Td } from '@/components/ui';

interface UserRow {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  emailVerified: boolean;
  role: string;
  status: string;
  createdAt: string;
  lastLoginAt: string | null;
  orderCount: number;
}

export default function UsersPage() {
  const [search, setSearch] = useState('');
  const [role, setRole] = useState('');
  const [status, setStatus] = useState('');
  const [page, setPage] = useState(1);
  const q = useDebounced(search);
  const { data, error, loading, reload } = useApi<Page<UserRow>>('/admin/users', { search: q, role, status, page, pageSize: 25 });

  return (
    <>
      <PageHeader title="Customers & staff" subtitle="Block an account to sign it out everywhere immediately." />
      <div className="mb-4 flex flex-wrap gap-2">
        <Input className="max-w-xs" placeholder="Search name or email" value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} />
        <Select className="max-w-40" value={role} onChange={(e) => { setRole(e.target.value); setPage(1); }}>
          <option value="">All roles</option>
          <option value="customer">Customers</option>
          <option value="staff">Staff</option>
          <option value="admin">Admins</option>
        </Select>
        <Select className="max-w-40" value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }}>
          <option value="">Any status</option>
          <option value="active">Active</option>
          <option value="blocked">Blocked</option>
        </Select>
      </div>
      {error && <ErrorBox message={error} onRetry={reload} />}
      <Card padded={false}>
        {loading && !data ? (
          <Loading />
        ) : (
          <Table head={['Name', 'Role', 'Orders', 'Joined', 'Last sign-in', 'Status']} empty={!data?.data.length}>
            {data?.data.map((u) => (
              <tr key={u.id} className="hover:bg-gray-50">
                <Td>
                  <Link href={`/users/${u.id}`} className="font-medium text-gray-900 hover:text-brand">{u.firstName} {u.lastName}</Link>
                  <div className="text-xs text-gray-500">{u.email}</div>
                </Td>
                <Td className="capitalize">{u.role}</Td>
                <Td>{u.orderCount}</Td>
                <Td className="text-gray-500">{timeAgo(u.createdAt)}</Td>
                <Td className="text-gray-500">{timeAgo(u.lastLoginAt)}</Td>
                <Td>
                  <div className="flex gap-1">
                    <Badge tone={u.status === 'active' ? 'green' : 'red'}>{u.status === 'active' ? 'Active' : 'Blocked'}</Badge>
                    {!u.emailVerified && <Badge tone="amber">Unverified</Badge>}
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
