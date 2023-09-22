#!/bin/bash

# how to use:
# 1. export PRIVATE_KEY=...
# 2. source ./bin/deploy.sh <RELAY_ADDRESS>

# 检查参数数量
if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <RELAY_ADDRESS>"
	exit 1
fi

root_dir=$PWD

bin_dir="$root_dir/bin"
script_dir="$root_dir/script"

DEPLOY_ADDRESS=$(cast wallet address $PRIVATE_KEY)
RELAY_ADDRESS=$1

# 编译
forge build

# 调用salt.sh并将结果存储到一个变量中
echo "++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ Generate oracle and relayer addresses."
echo "++++++++++++++++++++++++++++++++++++++++++++++++"
OUTPUT=$($bin_dir/salt.sh $DEPLOY_ADDRESS)

# 使用正则表达式解析结果
ORACLE_ADDR=$(echo "$OUTPUT" | grep "Oracle:" -A 1 | grep "Address:" | awk '{print $2}')
ORACLE_SALT=$(echo "$OUTPUT" | grep "Oracle:" -A 2 | grep "Salt:" | awk '{print $2}')
RELAYER_ADDR=$(echo "$OUTPUT" | grep "Relayer:" -A 1 | grep "Address:" | awk '{print $2}')
RELAYER_SALT=$(echo "$OUTPUT" | grep "Relayer:" -A 2 | grep "Salt:" | awk '{print $2}')

# 打印结果
echo "Oracle Address  : $ORACLE_ADDR"
echo "Oracle Salt     : $ORACLE_SALT"
echo "Relayer Address : $RELAYER_ADDR"
echo "Relayer Salt    : $RELAYER_SALT"

echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ Modify Deploy.s.sol and deploy.c.json."
echo "++++++++++++++++++++++++++++++++++++++++++++++++"
# 替换Deploy.s.sol文件中的内容
sed -i "s/address immutable ORACLE_ADDR = .*/address immutable ORACLE_ADDR = $ORACLE_ADDR;/g" $script_dir/Deploy.s.sol
sed -i "s/bytes32 immutable ORACLE_SALT = .*/bytes32 immutable ORACLE_SALT = $ORACLE_SALT;/g" $script_dir/Deploy.s.sol
sed -i "s/address immutable RELAYER_ADDR = .*/address immutable RELAYER_ADDR = $RELAYER_ADDR;/g" $script_dir/Deploy.s.sol
sed -i "s/bytes32 immutable RELAYER_SALT = .*/bytes32 immutable RELAYER_SALT = $RELAYER_SALT;/g" $script_dir/Deploy.s.sol

echo "File Deploy.s.sol has been modified successfully."

# 替换deploy.c.json文件中的内容
sed -i 's/"DAO":.*/"DAO": "'$DEPLOY_ADDRESS'",/' $script_dir/input/43/deploy.c.json
sed -i 's/"DEPLOYER":.*/"DEPLOYER": "'$DEPLOY_ADDRESS'",/' $script_dir/input/43/deploy.c.json
sed -i 's/"ORACLE_OPERATOR":.*/"ORACLE_OPERATOR": "'$RELAY_ADDRESS'",/' $script_dir/input/43/deploy.c.json
sed -i 's/"RELAYER_OPERATOR":.*/"RELAYER_OPERATOR": "'$RELAY_ADDRESS'"/' $script_dir/input/43/deploy.c.json

sed -i 's/"DAO":.*/"DAO": "'$DEPLOY_ADDRESS'",/' $script_dir/input/421613/deploy.c.json
sed -i 's/"DEPLOYER":.*/"DEPLOYER": "'$DEPLOY_ADDRESS'",/' $script_dir/input/421613/deploy.c.json
sed -i 's/"ORACLE_OPERATOR":.*/"ORACLE_OPERATOR": "'$RELAY_ADDRESS'",/' $script_dir/input/421613/deploy.c.json
sed -i 's/"RELAYER_OPERATOR":.*/"RELAYER_OPERATOR": "'$RELAY_ADDRESS'"/' $script_dir/input/421613/deploy.c.json

echo "File deploy.c.json has been modified successfully."

# 部署
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ Deploy: arbitrum oracle and relayer contracts."
echo "++++++++++++++++++++++++++++++++++++++++++++++++"
forge script $script_dir/Deploy.s.sol:DeployScript --private-key $PRIVATE_KEY --chain-id 421613 --broadcast --verify

echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ Deploy: pangolin oracle and relayer contracts."
echo "++++++++++++++++++++++++++++++++++++++++++++++++"
forge script $script_dir/Deploy.s.sol:DeployScript --private-key $PRIVATE_KEY --chain-id 43 --broadcast --verify

echo ""
echo "Oracle Address  : $ORACLE_ADDR"
echo "Oracle Salt     : $ORACLE_SALT"
echo "Relayer Address : $RELAYER_ADDR"
echo "Relayer Salt    : $RELAYER_SALT"
echo "Deployed successfully."
