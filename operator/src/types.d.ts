export const networks = ["mainnet", "holesky"] as const;

export interface Boost {
  name: string;
  description: string;
  network: string; // the evm network
  contract: string; // the token contract to apply user boosts based on transfer event balance
  threshold: number; // the minimal balance required to be eligible for the boost
  multiplier: number; // the boost multiplier applied against the base rate
  start: number; // the timestamp to start the boost
  end: number; // the timestamp to end the boost
}

export interface UserPoint {
  balance: string;
  contractAddress: string;
  id: string;
  lastUpdated: number;
  seeds: number;
  network: string;
  userAddress: string;
}

export interface Referral {
  amount: bigint;
  blockNumber: number;
  blockTimestamp: number;
  depositor: string;
  fromPublisher: string;
  id: string;
  network: string;
  receiver: string;
  referrer: string;
  shares: bigint;
  timestamp: number;
}

export interface Transfer {
  address: string;
  blockNumber: number;
  from: string;
  id: string;
  network: string;
  symbol: string;
  timestamp: number;
  to: string;
  type: string;
  value: bigint;
}

export interface User {
  id: string;
  userPoints: {
    items: UserPoint[];
  };
  referrals: {
    items: Referral[];
  };
  transfersTo: {
    items: Transfer[];
  };
  transfersFrom: {
    items: Transfer[];
  };
}

export interface PageInfo {
  endCursor: string;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
  startCursor: string;
}

export interface UsersResponse {
  users: {
    items: User[];
    pageInfo: PageInfo;
  };
}

export enum TokenType {
  ERC20 = "ERC20",
  ERC721 = "ERC721",
  ERC1155 = "ERC1155"
}

export interface Transfer {
  id: string;
  to: string;
  from: string;
  value: bigint;
  timestamp: number;
  blockNumber: number;
  network: string;
  address: string;
  type: TokenType;
  symbol: string;
}