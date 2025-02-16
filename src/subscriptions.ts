import { Subscription } from 'lightstreamer-client-node';
import { getListeners } from './subscriptions/listeners';

type SubscriptionData = { id: string; name: string };

const node3Subscriptions: SubscriptionData[] = [
  { id: 'NODE3000001', name: 'pp02 (torr)' },
  { id: 'NODE3000002', name: 'ppN2 (torr)' },
  { id: 'NODE3000003', name: 'ppC02 (torr)' },
  { id: 'NODE3000005', name: 'Urine Tank (%)' },
  { id: 'NODE3000008', name: 'Waste Water Tank (%)' },
  { id: 'NODE3000009', name: 'Clean Water Tank (%)' },
  { id: 'NODE3000011', name: 'O2 Production Rate (lb/day)' },
  { id: 'NODE3000017', name: 'Coolant Water Quantity (%)' },
];

export const subscriptions: Subscription[] = node3Subscriptions.map((sub) => {
  const subscription = new Subscription('MERGE', [sub.id], ['Value']);

  subscription.addListener(getListeners(sub.name));

  return subscription;
});
