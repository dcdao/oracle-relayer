// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Constants.sol";
import "ORMP/src/interfaces/IOracle.sol";
import "ORMP/src/interfaces/IFeedOracle.sol";
import "ORMP/src/Verifier.sol";

contract DcdaoOracle is Constants, IOracle, Verifier {
    event Assigned(bytes32 indexed msgHash, uint256 fee);
    event SetFee(uint256 indexed chainId, uint256 fee);
    event SetDapi(uint256 indexed chainId, address dapi);

    address public immutable PROTOCOL;
    address public owner;

    // chainId => price
    mapping(uint256 => uint256) public feeOf;
    // chainId => dapi
    mapping(uint256 => address) public dapiOf;

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    constructor(address dao) {
        PROTOCOL = ORMP;
        owner = dao;
    }

    receive() external payable {}

    function changeOwner(address owner_) external onlyOwner {
        owner = owner_;
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        (bool success,) = to.call{value: amount}("");
        require(success, "!withdraw");
    }

    function setFee(uint256 chainId, uint256 fee_) external onlyOwner {
        feeOf[chainId] = fee_;
        emit SetFee(chainId, fee_);
    }

    function setDapi(uint256 chainId, address dapi) external onlyOwner {
        dapiOf[chainId] = dapi;
        emit SetDapi(chainId, dapi);
    }

    function fee(uint256 toChainId, address /*ua*/ ) public view returns (uint256) {
        return feeOf[toChainId];
    }

    function assign(bytes32 msgHash) external payable {
        require(msg.sender == PROTOCOL, "!enpoint");
        emit Assigned(msgHash, msg.value);
    }

    function merkleRoot(uint256 chainId, uint256 /*blockNumber*/ ) public view override returns (bytes32) {
        address dapi = dapiOf[chainId];
        return IFeedOracle(dapi).messageRoot();
    }
}
