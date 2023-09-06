// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Constants.sol";
import "ORMP/src/eco/Oracle.sol";

contract DcdaoOracle is Constants, Oracle {
    constructor(address dcdao) Oracle(dcdao, ORMP) {}
}
