import { ItemUpdate } from 'lightstreamer-client-node';

export const getListeners = (name: string) => {
  return {
    onSubscription: function () {
      console.log(`${new Date().getHours()}:${new Date().getMinutes()}:${new Date().getSeconds()}: SUBSCRIBED TO ${name}`);
    },
    onUnubscription: function () {
      console.log(`${new Date().getHours()}:${new Date().getMinutes()}:${new Date().getSeconds()}: UNSUBSCRIBED TO ${name}`);
    },
    onItemUpdate: function (update: ItemUpdate) {
      //console.log(JSON.stringify(update));
      console.log(`${new Date().getHours()}:${new Date().getMinutes()}:${new Date().getSeconds()}: UPDATE FOR ${name}`, update.getValue('Value'));
    },
  };
};
