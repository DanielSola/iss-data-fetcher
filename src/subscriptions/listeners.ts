import { ItemUpdate } from 'lightstreamer-client-node';
import { KinesisClient, PutRecordCommand, PutRecordCommandInput } from '@aws-sdk/client-kinesis';

const kinesisClient = new KinesisClient({ region: 'eu-west-1' }); // Change to your AWS region

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
        StreamName: 'iss-data-stream',
        PartitionKey: name,
        Data: Buffer.from(JSON.stringify({ name, value, timestamp: new Date().toISOString() })),
      };

      try {
        const response = await kinesisClient.send(new PutRecordCommand(params));
        console.log('Kinesis response:', response);
      } catch (error) {
        console.error('Error sending data to Kinesis:', error);
      }
    },
  };
};
