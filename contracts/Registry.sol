// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IRegistry.sol";

contract Registry is ERC165, IRegistry {

    struct DoctusModel{
        bytes32 did;
        bytes metadataURI;
        address owner;

        // memberKeys[n-1] = Address
        // members[Address] = n
        // n == 0 => given address is not a member
        address[] memberKeys;
        mapping(address => uint) members;

        bytes32[] serviceKeys;
        mapping(bytes32 => ServiceModel) services;

        uint index;
    }

    struct ServiceModel{
        bytes32 sid;
        bytes metadataURI;

        uint index;
    }

    bytes32[] doctusKeys;
    mapping(bytes32 => DoctusModel) doctuses;

    // constructor() {
    //     // Registering the interface
    //     _registerInterface(type(IRegistry).interfaceId);
    // }

    /**
     * @dev Override function from ERC-165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IRegistry).interfaceId || super.supportsInterface(interfaceId);
    }


    /**
     * @dev Function to check the authorization before performing operation
     *
     * @param did ID of the Doctus
     * @param membersAllowed if false, only the owner is allowed, if true members also allowed
     */
    function requireAuthorization(bytes32 did, bool membersAllowed) internal view {
        require(msg.sender == doctuses[did].owner || (membersAllowed && doctuses[did].members[msg.sender] > 0),
                "Unauthorized operation!");
    }


    /**
     * @dev Function to check whether Doctus exists or not
     *
     * @param did ID of the Doctus
     * @param exists if true Doctus should exist, if false Doctus should not exist
     */
    function requireDoctusExistOrNot(bytes32 did, bool exists) internal view {
        if (exists){
            require(doctuses[did].did != bytes32(0x0), "Doctus does not exist!");
        }else{
            require(doctuses[did].did == bytes32(0x0), "Doctus already exists!");
        }
    }


    /**
     * @dev Function to check the Service exists or not
     *
     * @param did ID of the Doctus
     * @param sid ID of the Service
     * @param exists if true the Service should exist, if false the Service should not exist
     */
    function requireServiceExistOrNot(bytes32 did, bytes32 sid, bool exists) internal view{
        if (exists){
            require(doctuses[did].services[sid].sid != bytes32(0x0), "Service does not exist!");
        }else{
            require(doctuses[did].services[sid].sid == bytes32(0x0), "Service already exists!");
        }
    }

    function createDoctus(bytes32 did, bytes calldata metadataURI, address[] calldata members) external {
        requireDoctusExistOrNot(did, false);

        // DoctusModel memory doctus;
        // doctuses[did] = doctus;
        doctuses[did].did = did;
        doctuses[did].metadataURI = metadataURI;
        doctuses[did].owner = msg.sender;
        doctuses[did].index = doctusKeys.length;
        doctusKeys.push(did);
        addDoctusMembersInternal(did, members);

        emit DoctusCreated(did);
    }

    function changeDoctusOwner(bytes32 did, address newOwner) external{
        requireDoctusExistOrNot(did, true);
        requireAuthorization(did, false);

        doctuses[did].owner = newOwner;
        emit DoctusModified(did);
    }

    function changeDoctusMetadataURI(bytes32 did, bytes calldata metadataURI) external{
        requireDoctusExistOrNot(did, true);
        requireAuthorization(did, false);

        doctuses[did].metadataURI = metadataURI;
        emit DoctusModified(did);
    }

    function addDoctusMembersInternal(bytes32 did, address[] memory newMembers) internal {
        for (uint i = 0; i < newMembers.length; i++) {
            if (doctuses[did].members[newMembers[i]] == 0) {
                doctuses[did].memberKeys.push(newMembers[i]);
                doctuses[did].members[newMembers[i]] = doctuses[did].memberKeys.length;
            }
        }
    }

    function addDoctusMembers(bytes32 did, address[] calldata newMembers) external{
        requireDoctusExistOrNot(did, true);
        requireAuthorization(did, true);

        addDoctusMembersInternal(did, newMembers);
        emit DoctusModified(did);
    }

    /**
     * @dev Internal function to perform members removal
     *
     * @param did ID of the Doctus
     * @param membersToRemove Array of member addresses to remove
     */
    function removeDoctusMembersInternal(bytes32 did, address[] memory membersToRemove) internal{
        for (uint i = 0; i < membersToRemove.length; i++){
            if (doctuses[did].members[membersToRemove[i]] != 0){

                // Explanation of deletion:
                // Goal: Pop the memberKeys array (stack), so the last item will be lost
                //       Then delete the member from members mapping
                //
                // How to: 
                //         1. Define the index of member
                uint indexToRemove = doctuses[did].members[membersToRemove[i]];
                //         2. Define the last item from the stack
                address lastMember = doctuses[did].memberKeys[doctuses[did].memberKeys.length - 1];

                // Steps 3 and 4 are not needed if the member to remove is already at the last in the list
                if (doctuses[did].memberKeys[indexToRemove -1] != lastMember){
                    //     3. Change the position of last item to the position of member to be deleted
                    //        At this step, lastMember is available at [indexToRemove -1] and also last position
                    //        Duplicate does not matter, since the last item will be popped
                    doctuses[did].memberKeys[indexToRemove -1] = lastMember;
                    //     4. Update the index of lastMember to the new position
                    doctuses[did].members[lastMember] = indexToRemove;
                }

                //         5. Pop the stack (last item will be deleted)
                doctuses[did].memberKeys.pop();
                //         6. Delete the member from mapping
                delete doctuses[did].members[membersToRemove[i]];
            }
        }
    }

    function removeDoctusMembers(bytes32 did, address[] calldata members) external{
        requireDoctusExistOrNot(did, true);
        requireAuthorization(did, true);

        removeDoctusMembersInternal(did, members);

        emit DoctusModified(did);
    }

    function deleteDoctus(bytes32 did) external{
        requireDoctusExistOrNot(did, true);
        requireAuthorization(did, false);

        for (uint i = doctuses[did].serviceKeys.length; i > 0; i--){
            deleteServiceInternal(did, doctuses[did].serviceKeys[i-1]);
        }

        removeDoctusMembersInternal(did, doctuses[did].memberKeys);

        uint indexToDelete = doctuses[did].index;
        bytes32 lastDoctus = doctusKeys[doctusKeys.length - 1];

        if (doctusKeys[indexToDelete] != lastDoctus){
            doctusKeys[indexToDelete] = lastDoctus;
            doctuses[lastDoctus].index = indexToDelete;
        }

        doctusKeys.pop();
        delete doctuses[did];

        emit DoctusDeleted(did);
    }

    function createService(bytes32 did, bytes32 sid, bytes calldata metadataURI) external{
        requireDoctusExistOrNot(did, true);
        requireAuthorization(did, true);
        requireServiceExistOrNot(did, sid, false);

        ServiceModel memory service;
        service.sid = sid;
        service.metadataURI = metadataURI;
        service.index = doctuses[did].serviceKeys.length;

        doctuses[did].services[sid] = service;
        doctuses[did].serviceKeys.push(sid);

        emit ServiceCreated(did, sid, metadataURI);
    }

    function updateService(bytes32 did, bytes32 sid, bytes calldata metadataURI) external{
        requireDoctusExistOrNot(did, true);
        requireAuthorization(did, true);
        requireServiceExistOrNot(did, sid, true);

        doctuses[did].services[sid].metadataURI = metadataURI;

        emit ServiveMetadataModified(did, sid, metadataURI);
    }

    function deleteServiceInternal(bytes32 did, bytes32 sid) internal {
        uint indexToDelete = doctuses[did].services[sid].index;
        bytes32 lastService = doctuses[did].serviceKeys[doctuses[did].serviceKeys.length - 1];

        if (doctuses[did].serviceKeys[indexToDelete] != lastService){
            doctuses[did].serviceKeys[indexToDelete] = lastService;
            doctuses[did].services[lastService].index = indexToDelete;
        }

        doctuses[did].serviceKeys.pop();
        delete doctuses[did].services[sid];
    }

    function deleteService(bytes32 did, bytes32 sid) external{
        requireDoctusExistOrNot(did, true);
        requireAuthorization(did, true);
        requireServiceExistOrNot(did, sid, true);

        deleteServiceInternal(did, sid);

        emit ServiceDeleted(did, sid);
    }

    function listDoctuses() external view returns (bytes32[] memory dids){
        return doctusKeys;
    }

    function getDoctusById(bytes32 did) external view 
      returns (bool found, bytes32 id, bytes memory metadataURI, address owner, address[] memory members, bytes32[] memory services){
        if(doctuses[did].did == bytes32(0x0)){
            found = false;
        } else{
            found = true;
            id = doctuses[did].did;
            metadataURI = doctuses[did].metadataURI;
            owner = doctuses[did].owner;
            members = doctuses[did].memberKeys;
            services = doctuses[did].serviceKeys;
        }
    }

    function getServicesForDoctus(bytes32 did) external view returns (bool found, bytes32[] memory services){
        if(doctuses[did].did == bytes32(0x0)){
            found = false;
        } else{
            found = true;
            services = doctuses[did].serviceKeys;
        }
    }

    function getServiceById(bytes32 did, bytes32 sid) external view returns (bool found, bytes32 id, bytes memory metadataURI){
        if(doctuses[did].did == bytes32(0x0)){
            found = false;
        } else if (doctuses[did].services[sid].sid == bytes32(0x0)){
            found = false;
        }else{
            found = true;
            id = doctuses[did].services[sid].sid;
            metadataURI = doctuses[did].services[sid].metadataURI;
        }
    }

}