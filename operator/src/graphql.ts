import { gql } from "graphql-request";


export const UsersQuery = gql`
  query Users($limit: Int, $after: String) {
    users(limit: $limit, after: $after) {
      items {
        id
        userPoints {
          items {
            balance
            contractAddress
            id
            lastUpdated
            seeds
            network
            userAddress
          }
        }
        transfersFrom {
          items {
            address
            blockNumber
            from
            id
            network
            symbol
            timestamp
            to
            type
            value
          }
        }
        referrals {
          items {
            amount
            blockNumber
            blockTimestamp
            depositor
            fromPublisher
            id
            network
            receiver
            referrer
            shares
            timestamp
          }
        }
        transfersTo {
          items {
            address
            blockNumber
            from
            id
            network
            symbol
            timestamp
            to
            type
            value
          }
        }
      }
      pageInfo {
        endCursor
        hasNextPage
        hasPreviousPage
        startCursor
      }
    }
  }
  `;