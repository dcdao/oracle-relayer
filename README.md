# Darwinia community dao deployed oracle and relayer

## Deployments

### Canonical Cross-chain Deployment Addresses

| Contract | Canonical Cross-chain Deployment Address   |
| -------- | ------------------------------------------ |
| ORMP     | 0x0000000000BD9dcFDa5C60697039E2b3B28b079b |
| Oracle   | 0x000000768175E42873650D05B4D138dF7DaDEe43 |
| Relayer  | 0x0000001207bC87Df42403F0898efBF79A28222BE |

## Develop your own oracle and relayer contracts

0. clone this repo to your local.

1. run dev container and enter the container.

    * if you use vscode, you can open this repo in vscode, and press `ctrl+shift+p` to open command palette, then select `Dev Containers: Reopen in Container`.

    * if you don't like vscode, 

      enter the repo folder, run command:

      ```bash
      docker build -t <image_name> .
      docker run -it <image_name> bash
      ```

After this, you will enter a container with everthing you need to dev contracts.

2. (optional) rename your contracts.
   
    1. Rename your contracts in `src/` folder. 
    2. Update `script/Deploy.s.sol` file.

3. (optional) set ormp endpoint address

    1. Update `src/Constants.sol` file to use the correct ormp endpoint address.

4. do your own dev

    1. code your contracts in `src/` folder.

5. deploy

    1. `export PRIVATE_KEY=...`
    2. `source ./bin/deploy.sh <RELAY_ADDRESS>`

       RELAY_ADDRESS is the address you used to send transaction in ormpipe

Note:

* `PRIVATE_KEY` should have enough gas fee on all chains. Currently, `arbitrum-goerli` and `pangolin` are supported.
