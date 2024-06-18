## Point Guard

The Point Guard AVS Service is a TypeScript indexing service that indexes onchain Transfer events and calculates the points to be awarded to protocol users.

The Point Guard server indexes the points and balances for the configured protocol assets and provides the oeprator the ability to index the events required to respspond to tasks can challenges.

TODO:
Index the AVS contracts for newTasks and other Registry related events and respond to them accordingly.
Currently, this service is setup to index the ynETH asset.

1. Start local psql docker
```
docker compose up --build -d
```

This should start a local docker container for psql.

2. Create `.env.local`

```
# Mainnet RPC URL used for fetching blockchain data. Alchemy is recommended.
MAINNET_RPC_URL_1=https://rpc.ankr.com/eth
HOLESKY_RPC_URL_1=https://rpc.ankr.com/eth_holeskey

# Postgres database URL. If not provided, SQLite will be used. 
DATABASE_URL=postgres://postgres:postgres@localhost:5432/points
```

3. Start

```
npm i 
npm run start
```

4. See graphql in browser

http://localhost:42069
Use the url that was produced in the console. You can naviagte the entities via the book icon in the menu.

Example query in browser GraphQL Explorer:

```
query Users {
  users {
    items {
      id
      userPoints {
        items {
          id
          balance
          contractAddress
          lastUpdated
          seeds
          network
          userAddress
        }
      }
    }
  }
}
```