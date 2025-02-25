import { ItemUpdate } from 'lightstreamer-client-node';
import { KinesisClient, PutRecordCommand, PutRecordCommandInput } from '@aws-sdk/client-kinesis';

const kinesisClient = new KinesisClient({ region: 'us-east-1' }); // Change to your AWS region

export const getListeners = (name: string) => {
  return {
    onSubscription: function () {
      console.log(`${new Date().getHours()}:${new Date().getMinutes()}:${new Date().getSeconds()}: SUBSCRIBED TO ${name}`);
    },
    onUnubscription: function () {
      console.log(`${new Date().getHours()}:${new Date().getMinutes()}:${new Date().getSeconds()}: UNSUBSCRIBED TO ${name}`);
    },
    onItemUpdate: async function (update: ItemUpdate) {
      const value = update.getValue('Value');
      console.log(`${new Date().toISOString()}: UPDATE FOR ${name}`, value);

      const params: PutRecordCommandInput = {
        StreamName: 'iss_data_stream', // Your Kinesis stream name
        PartitionKey: name, // Use a unique identifier for partitioning
        Data: Buffer.from(JSON.stringify({ name, value, timestamp: new Date().toISOString() })),
      };

      try {
        await kinesisClient.send(new PutRecordCommand(params));
        console.log('Sent data to Kinesis:', params);
      } catch (error) {
        console.error('Error sending data to Kinesis:', error);
      }
    },
  };
};
