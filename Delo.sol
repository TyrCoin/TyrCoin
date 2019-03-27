pragma solidity ^0.4.21;

import "./CustodianCanBeReplaced.sol";
import "./Front.sol";
import "./Grossbuch.sol";

contract Delo is CustodianCanBeReplaced {

    // TYPES
    struct PendingPrint {
        address receiver;
        uint256 value;
    }

    // MEMBERS
    Front public front;

    Grossbuch public grossbuch;

    address public sweeper;

    bytes32 public sweepMsg;

    mapping (address => bool) public sweptSet;

    mapping (bytes32 => PendingPrint) public pendingPrintMap;

    // CONSTRUCTOR
    function Delo(
          address _front,
          address _grossbuch,
          address _custodian,
          address _sweeper
    )
        CustodianCanBeReplaced(_custodian)
        public
    {
        require(_sweeper != 0);
        front = Front(_front);
        grossbuch = Grossbuch(_grossbuch);

        sweeper = _sweeper;
        sweepMsg = keccak256(address(this), "sweep");
    }

    // MODIFIERS
    modifier onlyFront {
        require(msg.sender == address(front));
        _;
    }
    modifier onlySweeper {
        require(msg.sender == sweeper);
        _;
    }


    function approveWithSender(
        address _sender,
        address _spender,
        uint256 _value
    )
        public
        onlyFront
        returns (bool success)
    {
        require(_spender != address(0)); // disallow unspendable approvals
        grossbuch.setAllowance(_sender, _spender, _value);
        front.emitApproval(_sender, _spender, _value);
        return true;
    }

    function increaseApprovalWithSender(
        address _sender,
        address _spender,
        uint256 _addedValue
    )
        public
        onlyFront
        returns (bool success)
    {
        require(_spender != address(0)); // disallow unspendable approvals
        uint256 currentAllowance = grossbuch.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance + _addedValue;

        require(newAllowance >= currentAllowance);

        grossbuch.setAllowance(_sender, _spender, newAllowance);
        front.emitApproval(_sender, _spender, newAllowance);
        return true;
    }

    function decreaseApprovalWithSender(
        address _sender,
        address _spender,
        uint256 _subtractedValue
    )
        public
        onlyFront
        returns (bool success)
    {
        require(_spender != address(0)); // disallow unspendable approvals
        uint256 currentAllowance = grossbuch.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance - _subtractedValue;

        require(newAllowance <= currentAllowance);

        grossbuch.setAllowance(_sender, _spender, newAllowance);
        front.emitApproval(_sender, _spender, newAllowance);
        return true;
    }


    function requestPrint(address _receiver, uint256 _value) public returns (bytes32 zamokId) {
        require(_receiver != address(0));

        zamokId = generateZamokId();

        pendingPrintMap[zamokId] = PendingPrint({
            receiver: _receiver,
            value: _value
        });

        emit PrintingLocked(zamokId, _receiver, _value);
    }


    function confirmPrint(bytes32 _zamokId) public onlyCustodian {
        PendingPrint storage print = pendingPrintMap[_zamokId];

        // reject ‘null’ results from the map lookup
        // this can only be the case if an unknown `_zamokId` is received
        address receiver = print.receiver;
        require (receiver != address(0));
        uint256 value = print.value;

        delete pendingPrintMap[_zamokId];

        uint256 supply = grossbuch.totalSupply();
        uint256 newSupply = supply + value;
        if (newSupply >= supply) {
          grossbuch.setTotalSupply(newSupply);
          grossbuch.addBalance(receiver, value);

          emit PrintingConfirmed(_zamokId, receiver, value);
          front.emitTransfer(address(0), receiver, value);
        }
    }


    function burn(uint256 _value) public returns (bool success) {
        uint256 balanceOfSender = grossbuch.balances(msg.sender);
        require(_value <= balanceOfSender);

        grossbuch.setBalance(msg.sender, balanceOfSender - _value);
        grossbuch.setTotalSupply(grossbuch.totalSupply() - _value);

        front.emitTransfer(msg.sender, address(0), _value);

        return true;
    }


    function batchTransfer(address[] _tos, uint256[] _values) public returns (bool success) {
        require(_tos.length == _values.length);

        uint256 numTransfers = _tos.length;
        uint256 senderBalance = grossbuch.balances(msg.sender);

        for (uint256 i = 0; i < numTransfers; i++) {
          address to = _tos[i];
          require(to != address(0));
          uint256 v = _values[i];
          require(senderBalance >= v);

          if (msg.sender != to) {
            senderBalance -= v;
            grossbuch.addBalance(to, v);
          }
          front.emitTransfer(msg.sender, to, v);
        }

        grossbuch.setBalance(msg.sender, senderBalance);

        return true;
    }

    function enableSweep(uint8[] _vs, bytes32[] _rs, bytes32[] _ss, address _to) public onlySweeper {
        require(_to != address(0));
        require((_vs.length == _rs.length) && (_vs.length == _ss.length));

        uint256 numSignatures = _vs.length;
        uint256 sweptBalance = 0;

        for (uint256 i=0; i<numSignatures; ++i) {
          address from = ecrecover(sweepMsg, _vs[i], _rs[i], _ss[i]);

          // ecrecover returns 0 on malformed input
          if (from != address(0)) {
            sweptSet[from] = true;

            uint256 fromBalance = grossbuch.balances(from);

            if (fromBalance > 0) {
              sweptBalance += fromBalance;

              grossbuch.setBalance(from, 0);

              front.emitTransfer(from, _to, fromBalance);
            }
          }
        }

        if (sweptBalance > 0) {
          grossbuch.addBalance(_to, sweptBalance);
        }
    }

    function replaySweep(address[] _froms, address _to) public onlySweeper {
        require(_to != address(0));
        uint256 lenFroms = _froms.length;
        uint256 sweptBalance = 0;

        for (uint256 i=0; i<lenFroms; ++i) {
            address from = _froms[i];

            if (sweptSet[from]) {
                uint256 fromBalance = grossbuch.balances(from);

                if (fromBalance > 0) {
                    sweptBalance += fromBalance;

                    grossbuch.setBalance(from, 0);

                    front.emitTransfer(from, _to, fromBalance);
                }
            }
        }

        if (sweptBalance > 0) {
            grossbuch.addBalance(_to, sweptBalance);
        }
    }

    function transferFromWithSender(
        address _sender,
        address _from,
        address _to,
        uint256 _value
    )
        public
        onlyFront
        returns (bool success)
    {
        require(_to != address(0)); // ensure burn is the cannonical transfer to 0x0

        uint256 balanceOfFrom = grossbuch.balances(_from);
        require(_value <= balanceOfFrom);

        uint256 senderAllowance = grossbuch.allowed(_from, _sender);
        require(_value <= senderAllowance);

        grossbuch.setBalance(_from, balanceOfFrom - _value);
        grossbuch.addBalance(_to, _value);

        grossbuch.setAllowance(_from, _sender, senderAllowance - _value);

        front.emitTransfer(_from, _to, _value);

        return true;
    }

    function transferWithSender(
        address _sender,
        address _to,
        uint256 _value
    )
        public
        onlyFront
        returns (bool success)
    {
        require(_to != address(0)); // ensure burn is the cannonical transfer to 0x0

        uint256 balanceOfSender = grossbuch.balances(_sender);
        require(_value <= balanceOfSender);

        grossbuch.setBalance(_sender, balanceOfSender - _value);
        grossbuch.addBalance(_to, _value);

        front.emitTransfer(_sender, _to, _value);

        return true;
    }

    // METHODS (ERC20 sub interface impl.)
    function totalSupply() public view returns (uint256) {
        return grossbuch.totalSupply();
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return grossbuch.balances(_owner);
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return grossbuch.allowed(_owner, _spender);
    }

    // EVENTS
    event PrintingLocked(bytes32 _zamokId, address _receiver, uint256 _value);

    event PrintingConfirmed(bytes32 _zamokId, address _receiver, uint256 _value);
}