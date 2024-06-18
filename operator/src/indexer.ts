import { ponder } from "@/generated";
import { updateUsers } from "./points";
import system from "./system";

ponder.on("ynETH:setup", async ({ context }) => {
  // hook into the first network event
  system.db = context.db;
  context.network.name;
});

ponder.on("ynETH:Transfer", async ({ event, context }) => {
  try {
    if (context.network.name !== 'mainnet') return;
    const { db } = context;
    const network = context.network.name

    // save transfer event
    await db.Transfer.create({
      id: event.transaction.hash + "-" + event.log.logIndex,
      data: {
        from: event.args.from,
        to: event.args.to,
        value: event.args.value,
        timestamp: Number(event.block.timestamp),
        blockNumber: Number(event.block.number),
        network: network,
        address: event.log.address,
        type: "ERC20",
        symbol: "ynETH"
      }
    })
    updateUsers(event, network, db);
  } catch(err) {
    console.error(err);
  }
});

ponder.on("ReferralDepositAdapter:ReferralDepositProcessed", async ({ event, context }) => {
  const { db } = context;
  const network = context.network.name;

  // save transfer event
  await db.Referral.create({
    id: event.transaction.hash + "-" + event.log.logIndex,
    data: {
      depositor: event.args.depositor,
      receiver: event.args.receiver,
      amount: event.args.amount,
      shares: event.args.shares,
      referrer: event.args.referrer,
      timestamp: Number(event.args.timestamp),
      fromPublisher: event.args.fromPublisher,
      network: network,
      blockTimestamp: Number(event.block.timestamp),
      blockNumber: Number(event.block.number)
    }
  })
});
