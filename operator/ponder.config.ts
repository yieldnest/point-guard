import { createConfig, mergeAbis } from "@ponder/core";
import { http } from "viem";

import { TransparentUpgradeableProxyAbi } from "./abis/TransparentUpgradeableProxyAbi";
import { ynETH_0x14dcAbi } from "./abis/ynETH_0x14dcAbi";
import { ReferralDepositAdapter } from "./abis/ReferralDepositAdapter";

export default createConfig({
  networks: {
    mainnet: { chainId: 1, transport: http(process.env.MAINNET_RPC_URL_1) },
    holesky: { chainId: 17000, transport: http(process.env.HOLESKY_RPC_URL_1)}
  },
  contracts: {
    ynETH: {
      abi: mergeAbis([TransparentUpgradeableProxyAbi, ynETH_0x14dcAbi]),
      network: {
        mainnet: {
          address: "0x09db87A538BD693E9d08544577d5cCfAA6373A48",
          startBlock: 19839557,
        },
        holesky: {
          address: "0xd9029669BC74878BCB5BE58c259ed0A277C5c16E",
          startBlock: 1353715
        }
      }
    },
    ReferralDepositAdapter: {
      abi: mergeAbis([TransparentUpgradeableProxyAbi, ReferralDepositAdapter]),
      network: {
        holesky: {
          address: "0xf5333c2a259e23795023a5bd63e937e5b365df52",
          startBlock: 1353715
        }
      }
    }
  }
});
