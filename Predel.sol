pragma solidity ^0.4.21;

import "./Delo.sol";
import "./Zamok.sol";
contract Predel is Zamok {

    // TYPES
    struct PendingCeilingRaise {
        uint256 raiseBy;
    }

    // MEMBERS
    Delo public delo;

    address public custodian;

    address public predel;

    uint256 public totalSupplyCeiling;

    mapping (bytes32 => PendingCeilingRaise) public pendingRaiseMap;

    // CONSTRUCTOR
    function Predel(
        address _delo,
        address _custodian,
        address _predel,
        uint256 _initialCeiling
    )
        public
    {
        delo = Delo(_delo);
        custodian = _custodian;
        predel = _predel;
        totalSupplyCeiling = _initialCeiling;
    }

    // MODIFIERS
    modifier onlyCustodian {
        require(msg.sender == custodian);
        _;
    }
    modifier onlyPredel {
        require(msg.sender == predel);
        _;
    }

    function limitedPrint(address _receiver, uint256 _value) public onlyPredel {
        uint256 totalSupply = delo.totalSupply();
        uint256 newTotalSupply = totalSupply + _value;

        require(newTotalSupply >= totalSupply);
        require(newTotalSupply <= totalSupplyCeiling);
        delo.confirmPrint(delo.requestPrint(_receiver, _value));
    }

    function requestCeilingRaise(uint256 _raiseBy) public returns (bytes32 zamokId) {
        require(_raiseBy != 0);

        zamokId = generateZamokId();

        pendingRaiseMap[zamokId] = PendingCeilingRaise({
            raiseBy: _raiseBy
        });

        emit CeilingRaiseLocked(zamokId, _raiseBy);
    }

    function confirmCeilingRaise(bytes32 _zamokId) public onlyCustodian {
        PendingCeilingRaise storage pendingRaise = pendingRaiseMap[_zamokId];

        // copy locals of references to struct members
        uint256 raiseBy = pendingRaise.raiseBy;
        // accounts for a gibberish _zamokId
        require(raiseBy != 0);

        delete pendingRaiseMap[_zamokId];

        uint256 newCeiling = totalSupplyCeiling + raiseBy;
        // overflow check
        if (newCeiling >= totalSupplyCeiling) {
            totalSupplyCeiling = newCeiling;

            emit CeilingRaiseConfirmed(_zamokId, raiseBy, newCeiling);
        }
    }

    function lowerCeiling(uint256 _lowerBy) public onlyPredel {
        uint256 newCeiling = totalSupplyCeiling - _lowerBy;
        // overflow check
        require(newCeiling <= totalSupplyCeiling);
        totalSupplyCeiling = newCeiling;

        emit CeilingLowered(_lowerBy, newCeiling);
    }

    function confirmPrintProxy(bytes32 _zamokId) public onlyCustodian {
        delo.confirmPrint(_zamokId);
    }


    function confirmCustodianChangeProxy(bytes32 _zamokId) public onlyCustodian {
        delo.confirmCustodianChange(_zamokId);
    }

    // EVENTS
    event CeilingRaiseLocked(bytes32 _zamokId, uint256 _raiseBy);

    event CeilingRaiseConfirmed(bytes32 _zamokId, uint256 _raiseBy, uint256 _newCeiling);

    event CeilingLowered(uint256 _lowerBy, uint256 _newCeiling);
}