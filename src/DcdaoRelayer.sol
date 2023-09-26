// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Constants.sol";
import "ORMP/src/interfaces/IEndpoint.sol";
import "ORMP/src/interfaces/IRelayer.sol";

contract DcdaoRelayer is Constants, IRelayer {
    event Assigned(bytes32 indexed msgHash, uint256 fee, bytes params, bytes32[32] proof);
    event SetDstPrice(uint256 indexed chainId, uint128 dstPriceRatio, uint128 dstGasPriceInWei);
    event SetDstConfig(uint256 indexed chainId, uint64 baseGas, uint64 gasPerByte);

    struct DstPrice {
        uint128 dstPriceRatio; // dstPrice / localPrice * 10^10
        uint128 dstGasPriceInWei;
    }

    struct DstConfig {
        uint64 baseGas;
        uint64 gasPerByte;
    }

    address public immutable PROTOCOL;
    address public owner;

    // chainId => price
    mapping(uint256 => DstPrice) public priceOf;
    mapping(uint256 => DstConfig) public configOf;

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

    function setDstPrice(uint256 chainId, uint128 dstPriceRatio, uint128 dstGasPriceInWei) external onlyOwner {
        priceOf[chainId] = DstPrice(dstPriceRatio, dstGasPriceInWei);
        emit SetDstPrice(chainId, dstPriceRatio, dstGasPriceInWei);
    }

    function setDstConfig(uint256 chainId, uint64 baseGas, uint64 gasPerByte) external onlyOwner {
        configOf[chainId] = DstConfig(baseGas, gasPerByte);
        emit SetDstConfig(chainId, baseGas, gasPerByte);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        (bool success,) = to.call{value: amount}("");
        require(success, "!withdraw");
    }

    // params = [extraGas]
    function fee(uint256 toChainId, address, /*ua*/ uint256 size, bytes calldata params)
        public
        view
        returns (uint256)
    {
        uint256 extraGas = abi.decode(params, (uint256));
        DstPrice memory p = priceOf[toChainId];
        DstConfig memory c = configOf[toChainId];

        // remoteToken = dstGasPriceInWei * (baseGas + extraGas)
        uint256 remoteToken = p.dstGasPriceInWei * (c.baseGas + extraGas);
        // dstPriceRatio = dstPrice / localPrice * 10^10
        // sourceToken = RemoteToken * dstPriceRatio
        uint256 sourceToken = remoteToken * p.dstPriceRatio / (10 ** 10);
        uint256 payloadToken = c.gasPerByte * size * p.dstGasPriceInWei * p.dstPriceRatio / (10 ** 10);
        return sourceToken + payloadToken;
    }

    function assign(bytes32 msgHash, bytes calldata params) external payable {
        require(msg.sender == PROTOCOL, "!ormp");
        emit Assigned(msgHash, msg.value, params, IEndpoint(PROTOCOL).prove());
    }

    function relay(Message calldata message, bytes calldata proof, uint256 gasLimit) external {
        IEndpoint(PROTOCOL).recv(message, proof, gasLimit);
    }
}
