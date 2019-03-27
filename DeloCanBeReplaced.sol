pragma solidity ^0.4.21;

import "./CustodianCanBeReplaced.sol";
import "./Delo.sol";

contract DeloCanBeReplaced is CustodianCanBeReplaced  {

    // TYPES
    struct DeloChangeRequest {
        address proposedNew;
    }

    // MEMBERS
    // @dev  The reference to the active token implementation.
    Delo public delo;

    mapping (bytes32 => DeloChangeRequest) public deloChangeRequests;

    // CONSTRUCTOR
    function DeloCanBeReplaced(address _custodian) CustodianCanBeReplaced(_custodian) public {
        delo = Delo(0x0);
    }

    // MODIFIERS
    modifier onlyDelo {
        require(msg.sender == address(delo));
        _;
    }

    // PUBLIC FUNCTIONS
    // (UPGRADE)
    function requestDeloChange(address _proposedDelo) public returns (bytes32 zamokId) {
        require(_proposedDelo != address(0));

        zamokId = generateZamokId();

        deloChangeRequests[zamokId] = DeloChangeRequest({
            proposedNew: _proposedDelo
        });

        emit DeloChangeRequested(zamokId, msg.sender, _proposedDelo);
    }

    function confirmDeloChange(bytes32 _zamokId) public onlyCustodian {
        delo = getDeloChangeRequest(_zamokId);

        delete deloChangeRequests[_zamokId];

        emit DeloChangeConfirmed(_zamokId, address(delo));
    }

    // PRIVATE FUNCTIONS
    function getDeloChangeRequest(bytes32 _zamokId) private view returns (Delo _proposedNew) {
        DeloChangeRequest storage changeRequest = deloChangeRequests[_zamokId];

        // reject ‘null’ results from the map lookup
        // this can only be the case if an unknown `_zamokId` is received
        require(changeRequest.proposedNew != address(0));

        return Delo(changeRequest.proposedNew);
    }

    event DeloChangeRequested(
        bytes32 _zamokId,
        address _msgSender,
        address _proposedDelo
    );

    event DeloChangeConfirmed(bytes32 _zamokId, address _newImpl);
}