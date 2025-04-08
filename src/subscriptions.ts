import { Subscription } from 'lightstreamer-client-node';
import { getListeners } from './subscriptions/listeners';

type SubscriptionData = { id: string; name: string; description?: string };

const loopBSubscriptions: SubscriptionData[] = [
  { id: 'P1000001', name: 'Loop B Pump Flowrate (kg/hr)' },
  { id: 'P1000002', name: 'Loop B PM Out Press (kPa)' },
  { id: 'P1000003', name: 'Loop B PM Out Temp (deg C)' },
];

const loopASubscriptions: SubscriptionData[] = [
  { id: 'S1000001', name: 'FLOWRATE', description: 'Loop A Pump Flowrate (kg/hr)' },
  { id: 'S1000002', name: 'PRESSURE', description: 'Loop A PM Out Press (kPa)' },
  { id: 'S1000003', name: 'TEMPERATURE', description: 'Loop A PM Out Temp (deg C)' },
];

export const subscriptions: Subscription[] = loopASubscriptions.map((sub) => {
  const subscription = new Subscription('MERGE', [sub.id], ['Value']);

  subscription.addListener(getListeners(sub.name));

  return subscription;
});
