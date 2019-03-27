pragma solidity ^0.4.21;

contract Zamok {

    // MEMBERS
    uint256 public zamokCount;

    // CONSTRUCTOR
    function Zamok() public {
        zamokCount = 0;
    }

    // FUNCTIONS
    function generateZamokId() internal returns (bytes32 zamokId) {
        return keccak256(block.blockhash(block.number - 1), address(this), ++zamokCount);
    }
}
