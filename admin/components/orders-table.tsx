'use client';

import Link from 'next/link';
import { money, ORDER_STATUS_LABEL, ORDER_STATUS_TONE, timeAgo } from '@/lib/format';
import { Badge, Table, Td } from './ui';

export interface OrderRow {
  id: string;
  number: number;
  status: string;
  total: number;
  createdAt: string;
  storeName: string;
  customerName: string;
  customerEmail: string;
  itemCount: number;
}

export function OrdersTable({ rows }: { rows: OrderRow[] }) {
  return (
    <Table head={['Order', 'Customer', 'Store', 'Items', 'Total', 'Status', 'Placed']} empty={!rows.length}>
      {rows.map((o) => (
        <tr key={o.id} className="hover:bg-gray-50">
          <Td>
            <Link href={`/orders/${o.id}`} className="font-medium text-brand hover:underline">
              #{o.number}
            </Link>
          </Td>
          <Td>
            <div className="font-medium text-gray-800">{o.customerName}</div>
            <div className="text-xs text-gray-500">{o.customerEmail}</div>
          </Td>
          <Td>{o.storeName}</Td>
          <Td>{o.itemCount}</Td>
          <Td className="whitespace-nowrap">{money(o.total)}</Td>
          <Td>
            <Badge tone={ORDER_STATUS_TONE[o.status]}>{ORDER_STATUS_LABEL[o.status] ?? o.status}</Badge>
          </Td>
          <Td className="whitespace-nowrap text-gray-500">{timeAgo(o.createdAt)}</Td>
        </tr>
      ))}
    </Table>
  );
}
