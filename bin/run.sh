#!/bin/bash

# how to use:
# source ./bin/run.sh <DEPLOY_ADDRESS> <RELAYER_ADDRESS>

set -eo pipefail

# 检查参数数量
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <DEPLOY_ADDRESS> <RELAYER_ADDRESS>"
    exit 1
fi

DEPLOY_ADDRESS=$1
RELAYER_ADDRESS=$2

# 编译
forge build

# 调用salt.sh并将结果存储到一个变量中
echo "Generate oracle and relayer address..."
OUTPUT=$(./bin/salt.sh $DEPLOY_ADDRESS)

# 使用正则表达式解析结果
ORACLE_ADDR=$(echo "$OUTPUT" | grep "Oracle:" -A 1 | grep "Address:" | awk '{print $2}')
ORACLE_SALT=$(echo "$OUTPUT" | grep "Oracle:" -A 2 | grep "Salt:" | awk '{print $2}')
RELAYER_ADDR=$(echo "$OUTPUT" | grep "Relayer:" -A 1 | grep "Address:" | awk '{print $2}')
RELAYER_SALT=$(echo "$OUTPUT" | grep "Relayer:" -A 2 | grep "Salt:" | awk '{print $2}')

# 打印结果
echo "  Oracle Address  : $ORACLE_ADDR"
echo "  Oracle Salt     : $ORACLE_SALT"
echo "  Relayer Address : $RELAYER_ADDR"
echo "  Relayer Salt    : $RELAYER_SALT"

# 替换Deploy.s.sol文件中的内容
sed -i "s/address immutable ORACLE_ADDR = .*/address immutable ORACLE_ADDR = $ORACLE_ADDR;/g" ./script/Deploy.s.sol
sed -i "s/bytes32 immutable ORACLE_SALT = .*/bytes32 immutable ORACLE_SALT = $ORACLE_SALT;/g" ./script/Deploy.s.sol
sed -i "s/address immutable RELAYER_ADDR = .*/address immutable RELAYER_ADDR = $RELAYER_ADDR;/g" ./script/Deploy.s.sol
sed -i "s/bytes32 immutable RELAYER_SALT = .*/bytes32 immutable RELAYER_SALT = $RELAYER_SALT;/g" ./script/Deploy.s.sol

echo "File Deploy.s.sol has been modified successfully."

# 替换deploy.c.json文件中的内容
sed -i 's/"DAO":.*/"DAO": "'$DEPLOY_ADDRESS'",/' ./script/input/43/deploy.c.json
sed -i 's/"DEPLOYER":.*/"DEPLOYER": "'$DEPLOY_ADDRESS'",/' ./script/input/43/deploy.c.json
sed -i 's/"ORACLE_OPERATOR":.*/"ORACLE_OPERATOR": "'$RELAYER_ADDRESS'",/' ./script/input/43/deploy.c.json
sed -i 's/"RELAYER_OPERATOR":.*/"RELAYER_OPERATOR": "'$RELAYER_ADDRESS'"/' ./script/input/43/deploy.c.json

sed -i 's/"DAO":.*/"DAO": "'$DEPLOY_ADDRESS'",/' ./script/input/421613/deploy.c.json
sed -i 's/"DEPLOYER":.*/"DEPLOYER": "'$DEPLOY_ADDRESS'",/' ./script/input/421613/deploy.c.json
sed -i 's/"ORACLE_OPERATOR":.*/"ORACLE_OPERATOR": "'$RELAYER_ADDRESS'",/' ./script/input/421613/deploy.c.json
sed -i 's/"RELAYER_OPERATOR":.*/"RELAYER_OPERATOR": "'$RELAYER_ADDRESS'"/' ./script/input/421613/deploy.c.json

echo "File deploy.c.json has been modified successfully."

# 部署
echo "Deploying..."
forge script ./script/Deploy.s.sol:DeployScript --private-key $PRIVATE_KEY --chain-id 421613 --broadcast --verify
forge script ./script/Deploy.s.sol:DeployScript --private-key $PRIVATE_KEY --chain-id 43 --broadcast --verify

echo "Deployed successfully."
