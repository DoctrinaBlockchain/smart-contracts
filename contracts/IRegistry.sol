// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 *  @title Interface for the AI services mnager on Doctrina
  * @author DoctrinaAI (Tillo Bekov) 
 */

 interface IRegistry {

    // Doctus Management
    // Doctus stands for an organization, team or company that provide AI services
    event DoctusCreated(bytes32 indexed did);
    event DoctusModified(bytes32 indexed did);
    event DoctusDeleted(bytes32 indexed did);

    /**
      * @dev Adds a new Doctus. Reverts if the given Doctus id (did) has already been registered.
      *
      * @param did    id of the Doctus to create, must be unique.
      * @param metadataURI  MetadataURI of Doctus to create, must be unique.
      * @param members  Array of member addresses to seed the Doctus with.
      */
    function createDoctus(bytes32 did, bytes calldata metadataURI, address[] calldata members) external;

    /**
     * @dev Updates the owner of Doctus. 
     *      Only the owner can call this function. Reverts if the id is not found.
     *
     * @param did   ID of the Doctus
     * @param newOwner  Address of the new owner
     */
    function changeDoctusOwner(bytes32 did, address newOwner) external;

    /**
     * @dev Updates the metadata for the Doctus
     *      Only the owner can update the metadata
     * 
     * @param did   ID of the Doctus
     * @param metadataURI New metadata URI
     */
    function changeDoctusMetadataURI(bytes32 did, bytes calldata metadataURI) external;

    /**
     * @dev Adds new members to the Doctus
     *      Only the owner can add new members
     *
     * @param did   ID of the Doctus
     * @param members   Array of members to add
     */
    function addDoctusMembers(bytes32 did, address[] calldata members) external;

    /**
     * @dev Removes members from the Doctus
     *      Only the owner can remove the members
     *
     * @param did   ID of the Doctus
     * @param members   Array of members to be deleted
     */
    function removeDoctusMembers(bytes32 did, address[] calldata members) external;

    /**
     * @dev Deleted the Doctus 
     *      Only the owner can delete the Doctus
     *
     * @param did ID of the Doctus
     */
    function deleteDoctus(bytes32 did) external;


    // Service Management


    event ServiceCreated (bytes32 indexed did, bytes32 indexed sid, bytes metadataURI);
    event ServiveMetadataModified (bytes32 indexed did, bytes32 indexed sid, bytes metadataURI);
    event ServiceTagsModified (bytes32 indexed did, bytes32 indexed sid);
    event ServiceDeleted (bytes32 indexed did, bytes32 indexed sid);

    /**
     * @dev Create a new Service under the Doctus
     *      Only the Doctus owner can create a new Service
     *
     * @param did   ID of the doctus
     * @param sid   Unique ID for the new Service
     * @param metadataURI URL for the Service Metadata
     */
    function createService(bytes32 did, bytes32 sid, bytes calldata metadataURI) external;

    /**
     * @dev Updates the Service
     *      Only the Doctus owner can update the Service
     *
     * @param did   ID of the doctus
     * @param sid   Unique ID for the new Service
     * @param metadataURI New metadata URL
     */
    function updateService(bytes32 did, bytes32 sid, bytes calldata metadataURI) external;

    /**
     * @dev Deletes the Service
     *      Only the Doctus owner can delete the Service
     *
     * @param did   ID of the Doctus
     * @param sid ID of the Service
     */
    function deleteService(bytes32 did, bytes32 sid) external;


    // Getter functions

    /**
     * @dev Gets the list of all Doctus in the registry
     * 
     * @return dids Array of Doctus IDs
     */
    function listDoctuses() external view returns (bytes32[] memory dids);

    /**
     * @dev Get the Doctus information by ID
     *
     * @param did ID of the Doctus
     * @return found true if found, false if the ID is not found
     * @return id ID of the Doctus
     * @return metadataURI Metadata URI of teh Doctus
     * @return owner Address of the owner
     * @return members Array of IDs of the members
     * @return services  Array of Service ID under the Doctus
     */
    function getDoctusById(bytes32 did) external view 
      returns (bool found, bytes32 id, bytes memory metadataURI, address owner, address[] memory members, bytes32[] memory services);

    /**
     * @dev Gets all services for the Doctus
     *
     * @param did ID of th Doctus
     * @return found return true if found, false if not found
     * @return services Array of Services for th Doctus
     */
    function getServicesForDoctus(bytes32 did) external view returns (bool found, bytes32[] memory services);

    /**
     * @dev Gets the service information by ID
     *
     * @param did ID of the Doctus
     * @param sid  ID of the Service
     * @return found true if found false if not found
     * @return id   ID of the Service if found
     * @return metadataURI URl for the metadata location
     */
    function getServiceById(bytes32 did, bytes32 sid) external view returns (bool found, bytes32 id, bytes memory metadataURI); 

 }