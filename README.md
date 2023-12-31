# Darwinia community dao deployed oracle and relayer

## Deployments

### Canonical Cross-chain Deployment Addresses
|  Contract |  Canonical Cross-chain Deployment Address  |
|-----------|--------------------------------------------|
| ORMP      | 0x00000000001523057a05d6293C1e5171eE33eE0A |
| Oracle    | 0x000000768175E42873650D05B4D138dF7DaDEe43 |
| Relayer   | 0x0000001207bC87Df42403F0898efBF79A28222BE |

## Deploy your own oracle and relayer contracts

1. prepare your env_file

   ```
   # this is the private key you used to deploy oracle and relayer contracts
   PRIVATE_KEY=... 
   ```

2. run command:

   ```bash
   docker run --rm \
     --env-file /path/to/env_file \
     -it ghcr.io/dcdao/oracle-relayer:v0.1.x \
       "<RELAY_ADDRESS>" # this is the address you used to send transaction in ormpipe
   ```

Note:

* `PRIVATE_KEY` should have enough gas fee on all chains. Currently, `arbitrum-goerli` and `pangolin` are supported.
