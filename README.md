# Darwinia community dao deployed oracle and relayer

## Deployments

### Canonical Cross-chain Deployment Addresses

| Contract | Canonical Cross-chain Deployment Address   |
| -------- | ------------------------------------------ |
| ORMP     | 0x0000000000BD9dcFDa5C60697039E2b3B28b079b |
| Oracle   | 0x000000768175E42873650D05B4D138dF7DaDEe43 |
| Relayer  | 0x0000001207bC87Df42403F0898efBF79A28222BE |

## Deploy your own oracle and relayer contracts

1. prepare your env_file

   ```
   ETHERSCAN_ARBITRUM_KEY=...
   ETHERSCAN_PANGOLIN_KEY=...
   PRIVATE_KEY=0x...
   ```

2. run command:

   ```bash
   docker run --rm \
     --env-file /path/to/env_file
     -it ghcr.io/dcdao/oracle-relayer:v0.1.0 \
       "<DEPLOY_ADDRESS>" \
       "<YOUR_RELAYER_ADDRESS>" # this is the address you used to run ormpipe
   ```

Note:

1. `DEPLOY_ADDRESS` is the address of `PRIVATE_KEY`.
2. `YOUR_RELAYER_ADDRESS` should have enough gas fee on all chains. Currently, `arbitrum-goerli` and `pangolin` are supported.
