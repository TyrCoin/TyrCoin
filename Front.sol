pragma solidity ^0.4.21;

import "./ERC20Interface.sol";
import "./DeloCanBeReplaced.sol";

contract Front is ERC20Interface, DeloCanBeReplaced {

    // MEMBERS
    string public name;

    string public symbol;

    uint8 public decimals;

    // CONSTRUCTOR
    function Front(
        string _name,
        string _symbol,
        uint8 _decimals,
        address _custodian
    )
        DeloCanBeReplaced(_custodian)
        public
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    // PUBLIC FUNCTIONS
    // (ERC20Interface)
    function totalSupply() public view returns (uint256) {
        return delo.totalSupply();
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return delo.balanceOf(_owner);
    }

    function emitTransfer(address _from, address _to, uint256 _value) public onlyDelo {
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        return delo.transferWithSender(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        return delo.transferFromWithSender(msg.sender, _from, _to, _value);
    }

    function emitApproval(address _owner, address _spender, uint256 _value) public onlyDelo {
        emit Approval(_owner, _spender, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        return delo.approveWithSender(msg.sender, _spender, _value);
    }

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool success) {
        return delo.increaseApprovalWithSender(msg.sender, _spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool success) {
        return delo.decreaseApprovalWithSender(msg.sender, _spender, _subtractedValue);
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return delo.allowance(_owner, _spender);
    }
}