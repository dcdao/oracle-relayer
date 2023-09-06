.PHONY: add clean deploy salt fee

-include .env

all    :; forge build
clean  :; forge clean
deploy :; forge script script/Deploy.s.sol:DeployScript --chain-id ${chain-id} --broadcast --verify

tools  :; foundry
foundry:; curl -L https://foundry.paradigm.xyz | bash

salt   :; @bash ./bin/salt.sh
fee    :; @bash ./bin/fee.sh ${local} ${remote}
