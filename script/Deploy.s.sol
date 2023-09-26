// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {stdJson} from "forge-std/StdJson.sol";
import {Script} from "forge-std/Script.sol";
import "ORMP/script/Common.s.sol";

import "../src/DcdaoOracle.sol";
import "../src/DcdaoRelayer.sol";

interface III {
    function owner() external view returns (address);
    function changeOwner(address owner_) external;
    function setter() external view returns (address);
    function changeSetter(address setter_) external;
}

contract DeployScript is Common {
    using stdJson for string;
    using ScriptTools for string;

    address immutable ORACLE_ADDR = 0x000000768175E42873650D05B4D138dF7DaDEe43;
    bytes32 immutable ORACLE_SALT = 0xafa5eed2eea48ddadfa65fd33324257d20d58880f8903a7d99a9df4dfa395aec;
    address immutable RELAYER_ADDR = 0x0000001207bC87Df42403F0898efBF79A28222BE;
    bytes32 immutable RELAYER_SALT = 0xa526e97cd16eef26d31b69f973d0d6d4909370e9fdf2fdf0061c1993e4f6cc21;

    string config;
    string instanceId;
    string outputName;
    address deployer;
    address dao;
    address oracleOperator;
    address relayerOperator;

    function name() public pure override returns (string memory) {
        return "Deploy";
    }

    function setUp() public override {
        super.setUp();

        instanceId = vm.envOr("INSTANCE_ID", string("deploy.c"));
        outputName = "deploy.a";
        config = ScriptTools.readInput(instanceId);

        deployer = config.readAddress(".DEPLOYER");
        dao = config.readAddress(".DAO");
        oracleOperator = config.readAddress(".ORACLE_OPERATOR");
        relayerOperator = config.readAddress(".RELAYER_OPERATOR");
    }

    function run() public {
        require(deployer == msg.sender, "!deployer");

        address oracle = deployOralce();
        address relayer = deployRelayer();

        setConfig(oracle, relayer);

        ScriptTools.exportContract(outputName, "DAO", dao);
        ScriptTools.exportContract(outputName, "ORACLE", oracle);
        ScriptTools.exportContract(outputName, "RELAYER", relayer);
    }

    function deployOralce() public broadcast returns (address) {
        bytes memory byteCode = type(DcdaoOracle).creationCode;
        bytes memory initCode = bytes.concat(byteCode, abi.encode(deployer));
        address oracle = _deploy(ORACLE_SALT, initCode);
        require(oracle == ORACLE_ADDR, "!oracle");

        require(III(oracle).owner() == deployer);
        console.log("Oracle  deployed at %s", oracle);
        return oracle;
    }

    function deployRelayer() public broadcast returns (address) {
        bytes memory byteCode = type(DcdaoRelayer).creationCode;
        bytes memory initCode = bytes.concat(byteCode, abi.encode(deployer));
        address relayer = _deploy(RELAYER_SALT, initCode);
        require(relayer == RELAYER_ADDR, "!relayer");

        require(III(relayer).owner() == deployer);
        console.log("Relayer deployed at %s", relayer);
        return relayer;
    }

    function setConfig(address oracle, address relayer) public broadcast {
        III(oracle).changeOwner(dao);
        require(III(oracle).owner() == dao, "!dao");

        III(relayer).changeOwner(dao);
        require(III(relayer).owner() == dao, "!dao");
    }
}
