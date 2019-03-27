pragma solidity ^0.4.21;

import "./DeloCanBeReplaced.sol";

contract Grossbuch is DeloCanBeReplaced {

    // MEMBERS
    uint256 public totalSupply;

    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) public allowed;

    // CONSTRUCTOR
    function Grossbuch(address _custodian) DeloCanBeReplaced(_custodian) public {
        totalSupply = 0;
    }


    // PUBLIC FUNCTIONS

    function setTotalSupply(
        uint256 _newTotalSupply
    )
        public
        onlyDelo
    {
        totalSupply = _newTotalSupply;
    }


    function setAllowance(
        address _owner,
        address _spender,
        uint256 _value
    )
        public
        onlyDelo
    {
        allowed[_owner][_spender] = _value;
    }


    function setBalance(
        address _owner,
        uint256 _newBalance
    )
        public
        onlyDelo
    {
        balances[_owner] = _newBalance;
    }


    function addBalance(
        address _owner,
        uint256 _balanceIncrease
    )
        public
        onlyDelo
    {
        balances[_owner] = balances[_owner] + _balanceIncrease;
    }
}
