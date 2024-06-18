import { request } from "graphql-request";
import { UsersQuery } from "./graphql";
import { User, Transfer, Boost, networks } from "./types";
import { boosts } from "./boosts";
import system from "./system";

const baseRate = 2; // rate of points per hour
// const ratePerHour = baseRate * 10n ** 18n;
const writeDelay = 10;

setInterval(async () => {
  const promise = system.shiftQueue();

  try {
    if (promise) {
      await promise()
      // console.log(system.queueLength());
    }
  } catch(err) {
    system.pushQueue(promise);
  }
}, writeDelay);

function convertToFourDecimals(value: bigint): number {
  // Convert Wei to Ether by dividing by 10^18 and then scale to 4 decimal places
  const etherValue = (value * 10000n) / (10n ** 18n);
  return Number(etherValue) / 10000;
}

export async function updateUsers(event: any , network: string, db: any) {
  system.pushQueue(() => createToAddressUser(event, network, db));
  system.pushQueue(() => createFromAddressUser(event, network, db));
  system.pushQueue(() => upsertToAddressUserPoint(event, network, db));
  system.pushQueue(() => upsertFromAddressUserPoint(event, network, db));
}

export async function createToAddressUser(event: any, network: any, db: any) {
  try {
    const userId = event.args.to;
    const user = await db.User.findUnique({ id: userId });

    if (!user) {
      await db.User.upsert({ id: userId })
    }
  } catch(err) {
    console.log("updateToAddress", err);
  }
}

export async function createFromAddressUser(event: any, network: any, db: any) {
  try {
    const userId = event.args.from;
    const user = await db.User.findUnique({ id: userId });

    if (!user) {
      await db.User.upsert({ id: userId })
    }
  } catch(err) {
    console.log("updateToAddress", err);
  }
}

export async function upsertToAddressUserPoint(_event: any, _network: string, _db: any) {
  const event = _event;
  const network = _network;
  const db = _db;
  try {
    const userId = event.args.to;
    const symbol = getTokenSymbol(event.log.address);
    const userPointId = `${userId}-${network}-${symbol}`;

    const userPoints = await db.UserPoint.findUnique({ id: userPointId });

    if (userPoints) {
      await db.UserPoint.update({
        id: userPointId,
        data: {
          balance: userPoints.balance + event.args.value,
          lastUpdated: Math.floor(Date.now() / 1000)
        }
      });

    } else {
      await db.UserPoint.upsert({
        id: userPointId,
        create: {
          userAddress: userId,
          contractAddress: event.log.address,
          network,
          balance: event.args.value,
          seeds: 0,
          lastUpdated: Math.floor(Date.now() / 1000)
        },
        update: ({ current }: { current: any }) => ({
          userAddress: userId,
          contractAddress: event.log.address,
          network,
          balance: current.balance + event.args.value,
          seeds: 0,
          lastUpdated: Math.floor(Date.now() / 1000)
        })
      });
    }
  } catch(err) {
    console.log("updateToAddressUserPoint", err);
    system.pushQueue(() => upsertToAddressUserPoint(event, network, db));
  }
}

export async function upsertFromAddressUserPoint(_event: any, _network: string, _db: any) {
  const event = _event;
  const network = _network;
  const db = _db;  
  try {
    const userId = event.args.from;
    const symbol = getTokenSymbol(event.log.address);
    const userPointId = `${userId}-${network}-${symbol}`;

    const userPoints = await db.UserPoint.findUnique({ id: userPointId });

    if (userPoints) {
      await db.UserPoint.update({
        id: userPointId,
        data: {
          balance: userPoints.balance - event.args.value,
          lastUpdated: Math.floor(Date.now() / 1000)
        }
      });

    } else {
      await db.UserPoint.upsert({
        id: userPointId,
        create: {
          userAddress: userId,
          contractAddress: event.log.address,
          network,
          balance: 0n -event.args.value,
          seeds: 0,
          lastUpdated: Math.floor(Date.now() / 1000)
        },
        update: ({ current }: { current: any }) => ({
          userAddress: userId,
          contractAddress: event.log.address,
          network,
          balance: current.balance - event.args.value,
          seeds: 0,
          lastUpdated: Math.floor(Date.now() / 1000)
        })
      });
    }
  } catch(err) {
    console.log("updateFromAddressUserPoint", err);
    system.pushQueue(() => upsertFromAddressUserPoint(event, network, db));
  }
}

function getTokenSymbol(address: string): string {
  if (address === "0x09db87A538BD693E9d08544577d5cCfAA6373A48") {
    return "ynETH"
  }

  if (address === "0xd9029669BC74878BCB5BE58c259ed0A277C5c16E") {
    return "ynETH"
  }

  return "";
}

const POINTS_PER_HOUR = 2;

async function updateUserPoints(users: User[], db: any) {
  for (const user of users) {
    const balanceChanges: { timestamp: number; balance: bigint }[] = [];

    // Collect balance changes from transfersTo
    user.transfersTo.items.forEach((transfer: Transfer) => {
      balanceChanges.push({ timestamp: transfer.timestamp, balance: transfer.value });
    });

    // Collect balance changes from transfersFrom (negative balance)
    user.transfersFrom.items.forEach((transfer: Transfer) => {
      balanceChanges.push({ timestamp: transfer.timestamp, balance: -transfer.value });
    });

    // Sort balance changes by timestamp
    balanceChanges.sort((a, b) => a.timestamp - b.timestamp);

    // Calculate points based on balance held over time
    for (const userPoint of user.userPoints.items) {
      let lastTimestamp = userPoint.lastUpdated;
      let currentBalance = convertToFourDecimals(BigInt(userPoint.balance));
      let accruedPoints = 0;

      for (const change of balanceChanges) {
        if (change.timestamp > lastTimestamp) {
          const hoursHeld = (change.timestamp - lastTimestamp) / 3600;
          accruedPoints += currentBalance * hoursHeld * POINTS_PER_HOUR / (10 ** 18); // Assuming balance is in Wei
          currentBalance += convertToFourDecimals(change.balance);
          lastTimestamp = change.timestamp;
        }
      }

      // Update the user point balance and last updated timestamp
      userPoint.balance = currentBalance.toString();
      userPoint.lastUpdated = Math.floor(Date.now() / 1000);

      // Save the accrued points to the database (assuming a method to update points exists)
      // await db.UserPoint.update({
      //   id: userPoint.id,
      //   data: {
      //     balance: userPoint.balance,
      //     lastUpdated: userPoint.lastUpdated,
      //     seeds: { increment: accruedPoints } // Assuming points field exists
      //   }
      // });
    }
  }
}

export async function batchAllUsers() {
  let hasNextPage = true;
  let endCursor = "";
  const allUsers: any = [];

  const endpoint = 'http://localhost:42069';

  let variables: { limit: number; after?: string } = { limit: 1000 }

  while(hasNextPage) {
    try {
    const result: any = await request(endpoint, UsersQuery, variables);
    if (!result) return;
    result.users?.items.forEach((user: any) => allUsers.push(user));

    hasNextPage = result.users?.pageInfo.hasNextPage;
    variables.after = result.users?.pageInfo.endCursor;;
    if (!hasNextPage) {
      return allUsers;
    }
    return allUsers;
    } catch(err) {
      console.log("Error", err);
    }
  }

}


// async function main() {
//   console.log("Running main");
//   const users = await batchAllUsers();
//   await updateUserPoints(users, system.db);
//   console.log("Users", users.length)
// }

// setTimeout(() => {
//   setInterval(main, 5000);
// })