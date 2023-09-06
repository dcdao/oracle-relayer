// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Constants.sol";
import "ORMP/src/eco/Relayer.sol";

contract DcdaoRelayer is Constants, Relayer {
    constructor(address dcdao) Relayer(dcdao, ORMP) {}
}
