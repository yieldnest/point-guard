import config from "../ponder.config";
import { Boost } from "./types";

export const boosts: Boost[] = [
  {
    name: "Holesky Launch Epoch 1",
    description: "The Holesky Protocol Launch boost.",
    network: 'holesky',
    contract: config.contracts.ynETH.network.holesky.address,
    threshold: 0,
    multiplier: 5,
    start: 1713267488,
    end: 1713696044
  },
  {
    name: "Mainnet Launch Epoch 1",
    description: "The Mainnet Protocol Launch boost Epoch 1.",
    network: 'mainnet',
    contract: config.contracts.ynETH.network.mainnet.address,
    threshold: 0,
    multiplier: 5,
    start: 1715299200,
    end: 1716940799
  },
  {
    name: "Holesky Launch Epoch 2",
    description: "The Holesky Protocol Launch boost Epoch 2.",
    network: 'holesky',
    contract: config.contracts.ynETH.network.holesky.address,
    threshold: 0,
    multiplier: 1,
    start: 1713696045,
    end: 1722470399
  },
  {
    name: "Mainnet Launch Epoch 2",
    description: "The Mainnet Protocol Launch boost Epoch 2.",
    network: 'mainnet',
    contract: config.contracts.ynETH.network.mainnet.address,
    threshold: 0,
    multiplier: 1,
    start: 1716940800,
    end: 1722470399
  }
  // new boosts here
]