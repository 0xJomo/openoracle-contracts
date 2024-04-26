// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import {OpenOracleBridgeBLSApkRegistryStorage} from "./OpenOracleBridgeBLSApkRegistryStorage.sol";

import {IRegistryCoordinator} from "@eigenlayer-middleware/src/interfaces/IRegistryCoordinator.sol";

import {BN254} from "@eigenlayer-middleware/src/libraries/BN254.sol";

import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";

contract OpenOracleBLSApkRegistry is
    OpenOracleBridgeBLSApkRegistryStorage,
    OwnableUpgradeable
{
    using BN254 for BN254.G1Point;

    /// @notice Sets the (immutable) `registryCoordinator` address
    constructor(
        IRegistryCoordinator _registryCoordinator
    ) OpenOracleBridgeBLSApkRegistryStorage(_registryCoordinator) {}

    function initialize(address initialOwner) public initializer {
        _transferOwnership(initialOwner);
    }

    /*******************************************************************************
                      EXTERNAL FUNCTIONS - REGISTRY COORDINATOR
    *******************************************************************************/

    /**
     * @notice Registers the `operator`'s pubkey for the specified `quorumNumbers`.
     * @param operator The address of the operator to register.
     * @param quorumNumbers The quorum numbers the operator is registering for, where each byte is an 8 bit integer quorumNumber.
     * @dev access restricted to the RegistryCoordinator
     * @dev Preconditions (these are assumed, not validated in this contract):
     *         1) `quorumNumbers` has no duplicates
     *         2) `quorumNumbers.length` != 0
     *         3) `quorumNumbers` is ordered in ascending order
     *         4) the operator is not already registered
     */
    function registerOperator(
        address operator,
        bytes memory quorumNumbers
    ) public virtual {}

    /**
     * @notice Deregisters the `operator`'s pubkey for the specified `quorumNumbers`.
     * @param operator The address of the operator to deregister.
     * @param quorumNumbers The quorum numbers the operator is deregistering from, where each byte is an 8 bit integer quorumNumber.
     * @dev access restricted to the RegistryCoordinator
     * @dev Preconditions (these are assumed, not validated in this contract):
     *         1) `quorumNumbers` has no duplicates
     *         2) `quorumNumbers.length` != 0
     *         3) `quorumNumbers` is ordered in ascending order
     *         4) the operator is not already deregistered
     *         5) `quorumNumbers` is a subset of the quorumNumbers that the operator is registered for
     */
    function deregisterOperator(
        address operator,
        bytes memory quorumNumbers
    ) public virtual {}

    /**
     * @notice Initializes a new quorum by pushing its first apk update
     * @param quorumNumber The number of the new quorum
     */
    function initializeQuorum(uint8 quorumNumber) public virtual {}

    /**
     * @notice Called by the RegistryCoordinator register an operator as the owner of a BLS public key.
     * @param operator is the operator for whom the key is being registered
     * @param params contains the G1 & G2 public keys of the operator, and a signature proving their ownership
     * @param pubkeyRegistrationMessageHash is a hash that the operator must sign to prove key ownership
     */
    function registerBLSPublicKey(
        address operator,
        PubkeyRegistrationParams calldata params,
        BN254.G1Point calldata pubkeyRegistrationMessageHash
    ) external returns (bytes32 operatorId) {}

    function updateApkUpdate(
        uint8 quorumNumber,
        ApkUpdate calldata apkUpdate
    ) external onlyOwner {
        apkHistory[quorumNumber].push(apkUpdate);
    }

    /*******************************************************************************
                            INTERNAL FUNCTIONS
    *******************************************************************************/

    function _processQuorumApkUpdate(
        bytes memory quorumNumbers,
        BN254.G1Point memory point
    ) internal {}

    /*******************************************************************************
                            VIEW FUNCTIONS
    *******************************************************************************/
    /**
     * @notice Returns the pubkey and pubkey hash of an operator
     * @dev Reverts if the operator has not registered a valid pubkey
     */
    function getRegisteredPubkey(
        address operator
    ) public view returns (BN254.G1Point memory, bytes32) {}

    /**
     * @notice Returns the indices of the quorumApks index at `blockNumber` for the provided `quorumNumbers`
     * @dev Returns the current indices if `blockNumber >= block.number`
     */
    function getApkIndicesAtBlockNumber(
        bytes calldata quorumNumbers,
        uint256 blockNumber
    ) external view returns (uint32[] memory) {}

    /// @notice Returns the current APK for the provided `quorumNumber `
    function getApk(
        uint8 quorumNumber
    ) external view returns (BN254.G1Point memory) {}

    /// @notice Returns the `ApkUpdate` struct at `index` in the list of APK updates for the `quorumNumber`
    function getApkUpdateAtIndex(
        uint8 quorumNumber,
        uint256 index
    ) external view returns (ApkUpdate memory) {}

    /**
     * @notice get hash of the apk of `quorumNumber` at `blockNumber` using the provided `index`;
     * called by checkSignatures in BLSSignatureChecker.sol.
     * @param quorumNumber is the quorum whose ApkHash is being retrieved
     * @param blockNumber is the number of the block for which the latest ApkHash will be retrieved
     * @param index is the index of the apkUpdate being retrieved from the list of quorum apkUpdates in storage
     */
    function getApkHashAtBlockNumberAndIndex(
        uint8 quorumNumber,
        uint32 blockNumber,
        uint256 index
    ) external view returns (bytes24) {
                ApkUpdate memory quorumApkUpdate = apkHistory[quorumNumber][index];

        /**
         * Validate that the update is valid for the given blockNumber:
         * - blockNumber should be >= the update block number
         * - the next update block number should be either 0 or strictly greater than blockNumber
         */
        require(
            blockNumber >= quorumApkUpdate.updateBlockNumber,
            "BLSApkRegistry._validateApkHashAtBlockNumber: index too recent"
        );
        require(
            quorumApkUpdate.nextUpdateBlockNumber == 0 || blockNumber < quorumApkUpdate.nextUpdateBlockNumber,
            "BLSApkRegistry._validateApkHashAtBlockNumber: not latest apk update"
        );

        return quorumApkUpdate.apkHash;
    }

    /// @notice Returns the length of ApkUpdates for the provided `quorumNumber`
    function getApkHistoryLength(
        uint8 quorumNumber
    ) external view returns (uint32) {}

    /// @notice Returns the operator address for the given `pubkeyHash`
    function getOperatorFromPubkeyHash(
        bytes32 pubkeyHash
    ) public view returns (address) {}

    function getOperatorId(
        address operator
    ) external view override returns (bytes32) {}
}
