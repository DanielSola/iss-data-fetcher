import { LightstreamerClient } from 'lightstreamer-client-node';
import { subscriptions } from './subscriptions';

const client = new LightstreamerClient('https://push.lightstreamer.com', 'ISSLIVE');

subscriptions.forEach((sub) => client.subscribe(sub));

client.connect();
