import { Card, CardHeader, CardTitle, CardValue } from '@/components/ui/card';

export function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>{label}</CardTitle>
        <CardValue>{value}</CardValue>
      </CardHeader>
    </Card>
  );
}
