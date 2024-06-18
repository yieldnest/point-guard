import { createSchema } from "@ponder/core";
import { Boost } from "./src/types";

export const Schema = createSchema((p) => ({
  TokenType: p.createEnum(['ERC20', 'ERC721', 'ERC1155']),
  Transfer: p.createTable({
    id: p.string(),
    to: p.string().references('User.id'), 
    from: p.string().references('User.id'),
    value: p.bigint(),
    timestamp: p.int(),
    blockNumber: p.int(),
    network: p.string(),
    address: p.string(),
    type: p.enum('TokenType'),
    symbol: p.string(),
  }),
  User: p.createTable({
    id: p.string(), // ethereum address
    userPoints: p.many('UserPoint.userAddress'),
    transfersTo: p.many('Transfer.to'),
    transfersFrom: p.many('Transfer.from'),
    referrals: p.many('Referral.referrer')
  }),
  Referral: p.createTable({
    id: p.string(),
    depositor: p.string(),
    receiver: p.string().references('User.id'),
    amount: p.bigint(),
    shares: p.bigint(),
    referrer: p.string().references('User.id'),
    timestamp: p.int(),
    fromPublisher: p.boolean(),
    network: p.string(),
    blockTimestamp: p.int(),
    blockNumber: p.int()
  }),
  UserPoint: p.createTable({
    id: p.string(), // uid userAddress-network-tokenAddress
    userAddress: p.string().references('User.id'),
    contractAddress: p.string(),
    network: p.string(),
    balance: p.bigint(),
    seeds: p.float(),
    lastUpdated: p.int()
  }),
  Boosts: p.createTable({
    id: p.string(),
    name: p.string(),
    description: p.string(),
    network: p.string(),
    contract: p.string(),
    threshold: p.int(),
    multiplier: p.int(),
    start: p.int(),
    end: p.int()
  })
}));

export default Schema;