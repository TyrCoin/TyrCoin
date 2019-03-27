pragma solidity ^0.4.21;

import "./Zamok.sol";

contract CustodianCanBeReplaced is Zamok {

    // TYPES
    struct CustodianChangeRequest {
        address proposedNew;
    }

    // MEMBERS
    address public custodian;

    mapping (bytes32 => CustodianChangeRequest) public custodianChangeRequests;

    // CONSTRUCTOR
    function CustodianCanBeReplaced(
        address _custodian
    )
    
	Zamok() public
    {
        custodian = _custodian;
    }

    // MODIFIERS
    modifier onlyCustodian {
        require(msg.sender == custodian);
        _;
    }

    // PUBLIC FUNCTIONS
    // (UPGRADE)

    function requestCustodianChange(address _proposedCustodian) public returns (bytes32 zamokId) {
        require(_proposedCustodian != address(0));

        zamokId = generateZamokId();

        custodianChangeRequests[zamokId] = CustodianChangeRequest({
            proposedNew: _proposedCustodian
        });

        emit CustodianChangeRequested(zamokId, msg.sender, _proposedCustodian);
    }

    function confirmCustodianChange(bytes32 _zamokId) public onlyCustodian {
        custodian = getCustodianChangeRequest(_zamokId);

        delete custodianChangeRequests[_zamokId];

        emit CustodianChangeConfirmed(_zamokId, custodian);
    }

    // PRIVATE FUNCTIONS
    function getCustodianChangeRequest(bytes32 _zamokId) private view returns (address _proposedNew) {
        CustodianChangeRequest storage changeRequest = custodianChangeRequests[_zamokId];

        // reject ‘null’ results from the map lookup
        // this can only be the case if an unknown `_zamokId` is received
        require(changeRequest.proposedNew != 0);

        return changeRequest.proposedNew;
    }

    event CustodianChangeRequested(
        bytes32 _zamokId,
        address _msgSender,
        address _proposedCustodian
    );

    event CustodianChangeConfirmed(bytes32 _zamokId, address _newCustodian);
}