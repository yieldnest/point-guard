#!/bin/bash

RPC_URL=http://localhost:8545

# Source the .env file from the parent directory
if [ -f ../.env ]; then
    source ../.env
else
    echo ".env file not found in the parent directory!"
    exit 1
fi

# Access the variable
echo "The value of MY_VARIABLE is: $ETHEREUM_RPC_URL"

# 1. spin up a local forked anvil
anvil --fork-url $ETHEREUM_RPC_URL

# 2. deploy contracts
# 3. initialize contracts (register a protocol)
