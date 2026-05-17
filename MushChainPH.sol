// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * ============================================================
 *  MushChain PH — Farm-to-Market Traceability Smart Contract
 *  Dr. Yanga's Colleges, Inc. (DYCI)
 *  Prepared by: Patricia Mae Polintan & Franc Alvenn Dela Cruz
 * ============================================================
 *
 *  HOW TO USE IN REMIX IDE:
 *  ─────────────────────────────────────────────────────────
 *  1. Paste this file into Remix (remix.ethereum.org)
 *  2. Compile with Solidity ^0.8.20
 *  3. Deploy using "JavaScript VM (London)" — no wallet needed
 *  4. Remix gives you multiple test accounts. Assign them:
 *       Account[0] → Admin       (deploy from this account)
 *       Account[1] → Farmer
 *       Account[2] → Trader
 *       Account[3] → Transporter
 *       Account[4] → Vendor
 *  5. Follow the STEP-BY-STEP SIMULATION GUIDE at the bottom.
 * ============================================================
 */

contract MushChainPH {

    // ─────────────────────────────────────────────
    //  ENUMS
    // ─────────────────────────────────────────────

    enum Role        { None, Admin, Farmer, Trader, Transporter, Vendor }
    enum BatchStatus { Registered, TransferredToTrader, InTransit, Delivered }
    enum Variety     { Oyster, Shiitake, Button, Reishi, LionsMane }
    enum Condition   { Fresh, Good, Fair, Damaged }

    // ─────────────────────────────────────────────
    //  STRUCTS
    // ─────────────────────────────────────────────

    struct Participant {
        address     wallet;
        string      fullName;
        Role        role;
        string      organization;
        string      barangay;
        string      municipality;
        bool        isActive;
        uint256     registeredAt;
    }

    struct Batch {
        uint256     batchId;
        string      batchCode;          // e.g. FTPH-2026-00001
        Variety     variety;
        uint256     quantityKg;         // in grams to avoid decimals (1 kg = 1000)
        uint256     harvestTimestamp;
        address     farmer;
        string      farmName;
        string      barangay;
        string      municipality;
        string      growingNotes;
        BatchStatus status;
        address     currentOwner;
        uint256     mintedAt;
    }

    struct OwnershipTransfer {
        uint256     transferId;
        uint256     batchId;
        address     fromParticipant;
        address     toParticipant;
        uint256     agreedPricePerKg;   // in wei or symbolic units
        uint256     quantityKg;
        uint256     transferredAt;
        string      notes;
    }

    struct ShipmentRecord {
        uint256     shipmentId;
        uint256     batchId;
        address     transporter;
        string      vehiclePlate;
        string      departurePoint;
        string      destination;
        uint256     departureTime;
        uint256     estimatedArrival;
        string      conditionNotes;
        bool        isDelivered;
        uint256     recordedAt;
    }

    struct DeliveryConfirmation {
        uint256     confirmationId;
        uint256     batchId;
        address     vendor;
        uint256     quantityReceived;
        Condition   conditionAtDelivery;
        string      discrepancyNotes;
        uint256     confirmedAt;
    }

    struct AuditEntry {
        uint256     entryId;
        uint256     batchId;
        string      action;             // "REGISTERED", "TRANSFERRED", "SHIPPED", "DELIVERED"
        address     actor;
        string      actorRole;
        string      details;
        uint256     timestamp;
    }

    // ─────────────────────────────────────────────
    //  STATE VARIABLES
    // ─────────────────────────────────────────────

    address public admin;

    uint256 private _batchCounter;
    uint256 private _transferCounter;
    uint256 private _shipmentCounter;
    uint256 private _confirmationCounter;
    uint256 private _auditCounter;

    mapping(address => Participant)         public participants;
    mapping(uint256 => Batch)               public batches;
    mapping(uint256 => OwnershipTransfer)   public transfers;
    mapping(uint256 => ShipmentRecord)      public shipments;
    mapping(uint256 => DeliveryConfirmation) public deliveries;
    mapping(uint256 => AuditEntry)          public auditLog;

    // batch ID → list of audit entry IDs
    mapping(uint256 => uint256[])           public batchAuditTrail;

    // batch ID → transfer ID
    mapping(uint256 => uint256)             public batchTransfer;

    // batch ID → shipment ID
    mapping(uint256 => uint256)             public batchShipment;

    // batch ID → delivery ID
    mapping(uint256 => uint256)             public batchDelivery;

    // all batch IDs ever created
    uint256[] public allBatchIds;

    // ─────────────────────────────────────────────
    //  EVENTS  (the blockchain's permanent log)
    // ─────────────────────────────────────────────

    event ParticipantRegistered(address indexed wallet, string fullName, Role role, uint256 timestamp);
    event BatchMinted          (uint256 indexed batchId, string batchCode, address indexed farmer, Variety variety, uint256 quantityKg, uint256 timestamp);
    event OwnershipTransferred (uint256 indexed batchId, address indexed from, address indexed to, uint256 pricePerKg, uint256 quantity, uint256 timestamp);
    event ShipmentLogged       (uint256 indexed batchId, address indexed transporter, string vehiclePlate, string destination, uint256 timestamp);
    event DeliveryConfirmed    (uint256 indexed batchId, address indexed vendor, Condition condition, uint256 quantityReceived, uint256 timestamp);
    event AuditEntryAdded      (uint256 indexed batchId, string action, address indexed actor, uint256 timestamp);

    // ─────────────────────────────────────────────
    //  MODIFIERS
    // ─────────────────────────────────────────────

    modifier onlyAdmin() {
        require(msg.sender == admin, "MushChain: caller is not the Admin");
        _;
    }

    modifier onlyRole(Role _role) {
        require(participants[msg.sender].role == _role, "MushChain: incorrect role for this action");
        require(participants[msg.sender].isActive,      "MushChain: participant account is inactive");
        _;
    }

    modifier batchExists(uint256 _batchId) {
        require(_batchId > 0 && _batchId <= _batchCounter, "MushChain: batch does not exist");
        _;
    }

    modifier onlyCurrentOwner(uint256 _batchId) {
        require(batches[_batchId].currentOwner == msg.sender, "MushChain: caller does not own this batch");
        _;
    }

    // ─────────────────────────────────────────────
    //  CONSTRUCTOR
    // ─────────────────────────────────────────────

    constructor() {
        admin = msg.sender;
        // Auto-register the deployer as Admin
        participants[msg.sender] = Participant({
            wallet:       msg.sender,
            fullName:     "System Administrator",
            role:         Role.Admin,
            organization: "MushChain PH / PAMSG",
            barangay:     "Bocaue",
            municipality: "Bocaue, Bulacan",
            isActive:     true,
            registeredAt: block.timestamp
        });
        emit ParticipantRegistered(msg.sender, "System Administrator", Role.Admin, block.timestamp);
    }

    // ─────────────────────────────────────────────
    //  ADMIN: PARTICIPANT REGISTRATION
    // ─────────────────────────────────────────────

    /**
     * @notice Admin registers a supply chain participant and assigns their role.
     * @dev    In Remix, call this from Account[0] (admin) for each of
     *         Account[1..4], choosing the appropriate role number:
     *           2 = Farmer | 3 = Trader | 4 = Transporter | 5 = Vendor
     */
    function registerParticipant(
        address _wallet,
        string  memory _fullName,
        uint8   _role,               // 2=Farmer, 3=Trader, 4=Transporter, 5=Vendor
        string  memory _organization,
        string  memory _barangay,
        string  memory _municipality
    ) external onlyAdmin {
        require(_wallet != address(0),                    "MushChain: invalid wallet address");
        require(_role >= 2 && _role <= 5,                 "MushChain: role must be 2-5");
        require(!participants[_wallet].isActive,          "MushChain: participant already registered");

        participants[_wallet] = Participant({
            wallet:       _wallet,
            fullName:     _fullName,
            role:         Role(_role),
            organization: _organization,
            barangay:     _barangay,
            municipality: _municipality,
            isActive:     true,
            registeredAt: block.timestamp
        });

        emit ParticipantRegistered(_wallet, _fullName, Role(_role), block.timestamp);
    }

    // ─────────────────────────────────────────────
    //  STEP 1 — FARMER: REGISTER BATCH (MINT TOKEN)
    // ─────────────────────────────────────────────

    /**
     * @notice Farmer registers a harvested mushroom batch.
     *         This mints a "product token" on the blockchain.
     * @param _variety       0=Oyster, 1=Shiitake, 2=Button, 3=Reishi, 4=LionsMane
     * @param _quantityKg    Harvest weight in kilograms
     * @param _farmName      Name of the farm
     * @param _barangay      Barangay of the farm
     * @param _municipality  Municipality/province
     * @param _growingNotes  Optional substrate or condition notes
     */
    function registerBatch(
        uint8   _variety,
        uint256 _quantityKg,
        string  memory _farmName,
        string  memory _barangay,
        string  memory _municipality,
        string  memory _growingNotes
    ) external onlyRole(Role.Farmer) returns (uint256 batchId) {
        require(_variety <= 4,      "MushChain: unknown mushroom variety");
        require(_quantityKg > 0,    "MushChain: quantity must be > 0");
        require(bytes(_farmName).length > 0, "MushChain: farm name required");

        _batchCounter++;
        batchId = _batchCounter;

        string memory code = _generateBatchCode(batchId);

        batches[batchId] = Batch({
            batchId:          batchId,
            batchCode:        code,
            variety:          Variety(_variety),
            quantityKg:       _quantityKg,
            harvestTimestamp: block.timestamp,
            farmer:           msg.sender,
            farmName:         _farmName,
            barangay:         _barangay,
            municipality:     _municipality,
            growingNotes:     _growingNotes,
            status:           BatchStatus.Registered,
            currentOwner:     msg.sender,
            mintedAt:         block.timestamp
        });

        allBatchIds.push(batchId);

        string memory details = string(abi.encodePacked(
            "Farm: ", _farmName,
            " | Variety: ", _varietyName(Variety(_variety)),
            " | Qty: ", _uint2str(_quantityKg), " kg",
            " | Barangay: ", _barangay, ", ", _municipality
        ));

        _addAudit(batchId, "BATCH_REGISTERED", msg.sender, "Farmer", details);

        emit BatchMinted(batchId, code, msg.sender, Variety(_variety), _quantityKg, block.timestamp);
    }

    // ─────────────────────────────────────────────
    //  STEP 2 — FARMER→TRADER: OWNERSHIP TRANSFER
    // ─────────────────────────────────────────────

    /**
     * @notice Farmer sells and transfers a batch to a registered Trader.
     *         Caller must be the current owner (Farmer at this stage).
     * @param _batchId       The batch to transfer
     * @param _trader        Address of the registered Trader
     * @param _pricePerKg    Agreed price per kg (symbolic — no actual payment)
     * @param _notes         Optional purchase notes
     */
    function transferToTrader(
        uint256 _batchId,
        address _trader,
        uint256 _pricePerKg,
        string  memory _notes
    )
        external
        batchExists(_batchId)
        onlyCurrentOwner(_batchId)
        onlyRole(Role.Farmer)
    {
        require(batches[_batchId].status == BatchStatus.Registered,
            "MushChain: batch must be in Registered status");
        require(participants[_trader].role == Role.Trader,
            "MushChain: target address is not a registered Trader");
        require(participants[_trader].isActive,
            "MushChain: trader account is inactive");

        _transferCounter++;
        uint256 qty = batches[_batchId].quantityKg;

        transfers[_transferCounter] = OwnershipTransfer({
            transferId:       _transferCounter,
            batchId:          _batchId,
            fromParticipant:  msg.sender,
            toParticipant:    _trader,
            agreedPricePerKg: _pricePerKg,
            quantityKg:       qty,
            transferredAt:    block.timestamp,
            notes:            _notes
        });

        batchTransfer[_batchId]         = _transferCounter;
        batches[_batchId].currentOwner  = _trader;
        batches[_batchId].status        = BatchStatus.TransferredToTrader;

        string memory details = string(abi.encodePacked(
            "From Farmer: ", _addrShort(msg.sender),
            " -> Trader: ", _addrShort(_trader),
            " | Price/kg: ", _uint2str(_pricePerKg),
            " | Qty: ", _uint2str(qty), " kg",
            " | Notes: ", _notes
        ));

        _addAudit(_batchId, "OWNERSHIP_TRANSFERRED", msg.sender, "Farmer", details);

        emit OwnershipTransferred(_batchId, msg.sender, _trader, _pricePerKg, qty, block.timestamp);
    }

    // ─────────────────────────────────────────────
    //  STEP 3 — TRANSPORTER: LOG SHIPMENT
    // ─────────────────────────────────────────────

    /**
     * @notice Transporter logs pickup and shipment of a batch.
     *         The Trader (current owner) must have handed off to the Transporter.
     *         In this prototype, the Transporter calls this function directly
     *         once they have physically received the batch from the Trader.
     * @param _batchId           The batch being shipped
     * @param _vehiclePlate      Vehicle plate number
     * @param _departurePoint    Pickup barangay/location
     * @param _destination       Delivery destination (market, hub, etc.)
     * @param _estimatedHours    Estimated travel time in hours
     * @param _conditionNotes    Temperature or physical condition at pickup
     */
    function logShipment(
        uint256 _batchId,
        string  memory _vehiclePlate,
        string  memory _departurePoint,
        string  memory _destination,
        uint256 _estimatedHours,
        string  memory _conditionNotes
    )
        external
        batchExists(_batchId)
        onlyRole(Role.Transporter)
    {
        require(batches[_batchId].status == BatchStatus.TransferredToTrader,
            "MushChain: batch must be TransferredToTrader before shipping");
        require(bytes(_vehiclePlate).length > 0, "MushChain: vehicle plate required");
        require(bytes(_destination).length > 0,  "MushChain: destination required");

        _shipmentCounter++;

        shipments[_shipmentCounter] = ShipmentRecord({
            shipmentId:       _shipmentCounter,
            batchId:          _batchId,
            transporter:      msg.sender,
            vehiclePlate:     _vehiclePlate,
            departurePoint:   _departurePoint,
            destination:      _destination,
            departureTime:    block.timestamp,
            estimatedArrival: block.timestamp + (_estimatedHours * 1 hours),
            conditionNotes:   _conditionNotes,
            isDelivered:      false,
            recordedAt:       block.timestamp
        });

        batchShipment[_batchId]     = _shipmentCounter;
        batches[_batchId].status    = BatchStatus.InTransit;

        string memory details = string(abi.encodePacked(
            "Vehicle: ", _vehiclePlate,
            " | From: ", _departurePoint,
            " | To: ", _destination,
            " | ETA: ", _uint2str(_estimatedHours), " hr(s)",
            " | Condition: ", _conditionNotes
        ));

        _addAudit(_batchId, "SHIPMENT_LOGGED", msg.sender, "Transporter", details);

        emit ShipmentLogged(_batchId, msg.sender, _vehiclePlate, _destination, block.timestamp);
    }

    // ─────────────────────────────────────────────
    //  STEP 4 — VENDOR: DELIVERY CONFIRMATION
    // ─────────────────────────────────────────────

    /**
     * @notice Vendor confirms receipt of the batch, closing the chain of custody.
     *         This is the final, immutable event for this batch on the blockchain.
     * @param _batchId           The batch being confirmed
     * @param _quantityReceived  Actual kg received (may differ from shipped qty)
     * @param _condition         0=Fresh, 1=Good, 2=Fair, 3=Damaged
     * @param _discrepancyNotes  Notes on any shortage or damage found
     */
    function confirmDelivery(
        uint256 _batchId,
        uint256 _quantityReceived,
        uint8   _condition,
        string  memory _discrepancyNotes
    )
        external
        batchExists(_batchId)
        onlyRole(Role.Vendor)
    {
        require(batches[_batchId].status == BatchStatus.InTransit,
            "MushChain: batch must be InTransit before delivery can be confirmed");
        require(_condition <= 3,       "MushChain: invalid condition value");
        require(_quantityReceived > 0, "MushChain: quantity received must be > 0");

        // Mark shipment as delivered
        uint256 shipId = batchShipment[_batchId];
        if (shipId > 0) {
            shipments[shipId].isDelivered = true;
        }

        _confirmationCounter++;

        deliveries[_confirmationCounter] = DeliveryConfirmation({
            confirmationId:   _confirmationCounter,
            batchId:          _batchId,
            vendor:           msg.sender,
            quantityReceived: _quantityReceived,
            conditionAtDelivery: Condition(_condition),
            discrepancyNotes: _discrepancyNotes,
            confirmedAt:      block.timestamp
        });

        batchDelivery[_batchId]         = _confirmationCounter;
        batches[_batchId].status        = BatchStatus.Delivered;
        batches[_batchId].currentOwner  = msg.sender;

        string memory details = string(abi.encodePacked(
            "Vendor: ", _addrShort(msg.sender),
            " | Qty Received: ", _uint2str(_quantityReceived), " kg",
            " | Condition: ", _conditionName(Condition(_condition)),
            " | Notes: ", _discrepancyNotes
        ));

        _addAudit(_batchId, "DELIVERY_CONFIRMED", msg.sender, "Vendor", details);

        emit DeliveryConfirmed(_batchId, msg.sender, Condition(_condition), _quantityReceived, block.timestamp);
    }

    // ─────────────────────────────────────────────
    //  READ FUNCTIONS — TRACEABILITY & AUDIT
    // ─────────────────────────────────────────────

    /**
     * @notice Returns the full provenance summary of a batch.
     *         Simulates what a consumer would see after scanning the QR code.
     */
    function getProvenance(uint256 _batchId)
        external
        view
        batchExists(_batchId)
        returns (
            string  memory batchCode,
            string  memory variety,
            uint256        quantityKg,
            string  memory farmName,
            string  memory location,
            string  memory statusLabel,
            address        farmer,
            address        currentOwner,
            uint256        harvestTimestamp,
            uint256        mintedAt
        )
    {
        Batch storage b = batches[_batchId];
        return (
            b.batchCode,
            _varietyName(b.variety),
            b.quantityKg,
            b.farmName,
            string(abi.encodePacked(b.barangay, ", ", b.municipality)),
            _statusName(b.status),
            b.farmer,
            b.currentOwner,
            b.harvestTimestamp,
            b.mintedAt
        );
    }

    /**
     * @notice Returns the ownership transfer record for a batch.
     */
    function getTransferRecord(uint256 _batchId)
        external
        view
        batchExists(_batchId)
        returns (
            address fromParticipant,
            address toParticipant,
            uint256 agreedPricePerKg,
            uint256 quantityKg,
            uint256 transferredAt,
            string  memory notes
        )
    {
        uint256 tid = batchTransfer[_batchId];
        require(tid > 0, "MushChain: no transfer recorded for this batch");
        OwnershipTransfer storage t = transfers[tid];
        return (t.fromParticipant, t.toParticipant, t.agreedPricePerKg, t.quantityKg, t.transferredAt, t.notes);
    }

    /**
     * @notice Returns the shipment record for a batch.
     */
    function getShipmentRecord(uint256 _batchId)
        external
        view
        batchExists(_batchId)
        returns (
            address transporter,
            string  memory vehiclePlate,
            string  memory departurePoint,
            string  memory destination,
            uint256        departureTime,
            uint256        estimatedArrival,
            string  memory conditionNotes,
            bool           isDelivered
        )
    {
        uint256 sid = batchShipment[_batchId];
        require(sid > 0, "MushChain: no shipment recorded for this batch");
        ShipmentRecord storage s = shipments[sid];
        return (s.transporter, s.vehiclePlate, s.departurePoint, s.destination,
                s.departureTime, s.estimatedArrival, s.conditionNotes, s.isDelivered);
    }

    /**
     * @notice Returns the delivery confirmation for a batch.
     */
    function getDeliveryRecord(uint256 _batchId)
        external
        view
        batchExists(_batchId)
        returns (
            address vendor,
            uint256 quantityReceived,
            string  memory condition,
            string  memory discrepancyNotes,
            uint256 confirmedAt
        )
    {
        uint256 did = batchDelivery[_batchId];
        require(did > 0, "MushChain: no delivery recorded for this batch");
        DeliveryConfirmation storage d = deliveries[did];
        return (d.vendor, d.quantityReceived, _conditionName(d.conditionAtDelivery), d.discrepancyNotes, d.confirmedAt);
    }

    /**
     * @notice Returns all audit entry IDs for a given batch.
     *         Call getAuditEntry(id) for each to read the full trail.
     */
    function getBatchAuditTrail(uint256 _batchId)
        external
        view
        batchExists(_batchId)
        returns (uint256[] memory)
    {
        return batchAuditTrail[_batchId];
    }

    /**
     * @notice Returns a single audit log entry.
     */
    function getAuditEntry(uint256 _entryId)
        external
        view
        returns (
            uint256 batchId,
            string  memory action,
            address actor,
            string  memory actorRole,
            string  memory details,
            uint256 timestamp
        )
    {
        AuditEntry storage e = auditLog[_entryId];
        return (e.batchId, e.action, e.actor, e.actorRole, e.details, e.timestamp);
    }

    /**
     * @notice Returns all batch IDs ever registered on this contract.
     */
    function getAllBatches() external view returns (uint256[] memory) {
        return allBatchIds;
    }

    /**
     * @notice Returns the current status of a batch as a human-readable label.
     */
    function getBatchStatus(uint256 _batchId)
        external
        view
        batchExists(_batchId)
        returns (string memory)
    {
        return _statusName(batches[_batchId].status);
    }

    /**
     * @notice Returns a participant's profile.
     */
    function getParticipant(address _wallet)
        external
        view
        returns (
            string memory fullName,
            string memory role,
            string memory organization,
            string memory barangay,
            string memory municipality,
            bool   isActive,
            uint256 registeredAt
        )
    {
        Participant storage p = participants[_wallet];
        return (p.fullName, _roleName(p.role), p.organization, p.barangay, p.municipality, p.isActive, p.registeredAt);
    }

    // ─────────────────────────────────────────────
    //  ADMIN UTILITIES
    // ─────────────────────────────────────────────

    /**
     * @notice Admin can deactivate a participant (e.g., revoke accreditation).
     */
    function deactivateParticipant(address _wallet) external onlyAdmin {
        require(participants[_wallet].isActive, "MushChain: already inactive");
        participants[_wallet].isActive = false;
    }

    /**
     * @notice Admin can reactivate a participant.
     */
    function reactivateParticipant(address _wallet) external onlyAdmin {
        require(!participants[_wallet].isActive, "MushChain: already active");
        participants[_wallet].isActive = true;
    }

    // ─────────────────────────────────────────────
    //  INTERNAL HELPERS
    // ─────────────────────────────────────────────

    function _addAudit(
        uint256 _batchId,
        string  memory _action,
        address _actor,
        string  memory _actorRole,
        string  memory _details
    ) internal {
        _auditCounter++;
        auditLog[_auditCounter] = AuditEntry({
            entryId:   _auditCounter,
            batchId:   _batchId,
            action:    _action,
            actor:     _actor,
            actorRole: _actorRole,
            details:   _details,
            timestamp: block.timestamp
        });
        batchAuditTrail[_batchId].push(_auditCounter);
        emit AuditEntryAdded(_batchId, _action, _actor, block.timestamp);
    }

    function _generateBatchCode(uint256 _id) internal view returns (string memory) {
        // Produces: FTPH-2026-00001 style codes
        uint256 year = 2026; // fixed for prototype; use block.timestamp year in production
        (year); // suppress unused warning — year would be computed dynamically in prod
        return string(abi.encodePacked("FTPH-2026-", _padded(_id)));
    }

    function _padded(uint256 _n) internal pure returns (string memory) {
        string memory s = _uint2str(_n);
        uint256 len = bytes(s).length;
        string memory pad = "";
        if      (len == 1) pad = "0000";
        else if (len == 2) pad = "000";
        else if (len == 3) pad = "00";
        else if (len == 4) pad = "0";
        return string(abi.encodePacked(pad, s));
    }

    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) { len++; j /= 10; }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) { k--; bstr[k] = bytes1(uint8(48 + _i % 10)); _i /= 10; }
        return string(bstr);
    }

    function _addrShort(address _a) internal pure returns (string memory) {
        bytes memory b = abi.encodePacked(_a);
        bytes memory result = new bytes(10);
        bytes memory hex_chars = "0123456789abcdef";
        result[0] = '0'; result[1] = 'x';
        result[2] = hex_chars[uint8(b[0]) >> 4];
        result[3] = hex_chars[uint8(b[0]) & 0x0f];
        result[4] = hex_chars[uint8(b[1]) >> 4];
        result[5] = hex_chars[uint8(b[1]) & 0x0f];
        result[6] = '.'; result[7] = '.';
        result[8] = hex_chars[uint8(b[19]) >> 4];
        result[9] = hex_chars[uint8(b[19]) & 0x0f];
        return string(result);
    }

    function _varietyName(Variety _v) internal pure returns (string memory) {
        if (_v == Variety.Oyster)   return "Oyster (Pleurotus ostreatus)";
        if (_v == Variety.Shiitake) return "Shiitake (Lentinula edodes)";
        if (_v == Variety.Button)   return "Button (Agaricus bisporus)";
        if (_v == Variety.Reishi)   return "Reishi";
        return "Lion's Mane";
    }

    function _statusName(BatchStatus _s) internal pure returns (string memory) {
        if (_s == BatchStatus.Registered)          return "Registered (At Farm)";
        if (_s == BatchStatus.TransferredToTrader) return "Transferred to Trader";
        if (_s == BatchStatus.InTransit)           return "In Transit";
        return "Delivered Chain of Custody Closed";
    }

    function _conditionName(Condition _c) internal pure returns (string memory) {
        if (_c == Condition.Fresh)   return "Fresh";
        if (_c == Condition.Good)    return "Good";
        if (_c == Condition.Fair)    return "Fair";
        return "Damaged";
    }

    function _roleName(Role _r) internal pure returns (string memory) {
        if (_r == Role.Admin)       return "Admin";
        if (_r == Role.Farmer)      return "Farmer";
        if (_r == Role.Trader)      return "Trader";
        if (_r == Role.Transporter) return "Transporter";
        if (_r == Role.Vendor)      return "Vendor";
        return "None";
    }
}



/*
 ════════════════════════════════════════════════════════════════════════════
  STEP-BY-STEP SIMULATION GUIDE FOR REMIX IDE
  (Copy/paste parameter values directly into the Remix function fields)
 ════════════════════════════════════════════════════════════════════════════

  SETUP
  ──────────────────────────────────────────────────────────────────────────
  After deploying, note your 5 account addresses from the Remix dropdown:
    ADMIN       = Account[0]  (auto-registered on deploy)
    FARMER      = Account[1]
    TRADER      = Account[2]
    TRANSPORTER = Account[3]
    VENDOR      = Account[4]

  ──────────────────────────────────────────────────────────────────────────
  [A] REGISTER PARTICIPANTS  — call from Account[0] (Admin)
  ──────────────────────────────────────────────────────────────────────────

  registerParticipant(
      "<Account[1] address>",   ← paste Farmer wallet
      "Juan dela Cruz",
      2,                         ← Role.Farmer
      "PMGA Bulacan Chapter",
      "Lolomboy",
      "Bocaue Bulacan"
  )

  registerParticipant(
      "<Account[2] address>",   ← paste Trader wallet
      "Maria Santos",
      3,                         ← Role.Trader
      "Santos Fresh Trading",
      "Bagumbayan",
      "Caloocan City"
  )

  registerParticipant(
      "<Account[3] address>",   ← paste Transporter wallet
      "Pedro Reyes",
      4,                         ← Role.Transporter
      "Reyes Hauling Services",
      "Malanday",
      "Valenzuela City"
  )

  registerParticipant(
      "<Account[4] address>",   ← paste Vendor wallet
      "Ana Lim",
      5,                         ← Role.Vendor
      "Lim Fresh Market Stall",
      "Divisoria",
      "Manila"
  )

  ──────────────────────────────────────────────────────────────────────────
  [1] FARMER REGISTERS BATCH — switch to Account[1] (Farmer)
  ──────────────────────────────────────────────────────────────────────────

  registerBatch(
      0,                        ← Variety: Oyster
      50,                       ← 50 kg
      "Dela Cruz Mushroom Farm",
      "Lolomboy",
      "Bocaue, Bulacan",
      "Grown on rice straw substrate. No pesticides used."
  )

  → Expected event: BatchMinted(batchId=1, batchCode="FTPH-2026-00001", ...)
  → Call getBatchStatus(1) → "Registered (At Farm)"
  → Call getProvenance(1)  → full farm details

  ──────────────────────────────────────────────────────────────────────────
  [2] FARMER TRANSFERS TO TRADER — stay on Account[1] (Farmer)
  ──────────────────────────────────────────────────────────────────────────

  transferToTrader(
      1,                        ← batchId
      "<Account[2] address>",   ← Trader's wallet
      85,                       ← ₱85 agreed price per kg (symbolic)
      "Agreed price locked at harvest-day market rate."
  )

  → Expected event: OwnershipTransferred(batchId=1, from=Farmer, to=Trader, ...)
  → Call getBatchStatus(1) → "Transferred to Trader"
  → Call getTransferRecord(1) → price, quantity, timestamp

  ──────────────────────────────────────────────────────────────────────────
  [3] TRANSPORTER LOGS SHIPMENT — switch to Account[3] (Transporter)
  ──────────────────────────────────────────────────────────────────────────

  logShipment(
      1,                        ← batchId
      "ABC-1234",               ← vehicle plate
      "Lolomboy, Bocaue",       ← departure point
      "Divisoria Market, Manila", ← destination
      4,                        ← estimated 4 hours
      "Mushrooms packed in ventilated crates. Ambient temp ~24°C."
  )

  → Expected event: ShipmentLogged(batchId=1, transporter=Account[3], ...)
  → Call getBatchStatus(1)   → "In Transit"
  → Call getShipmentRecord(1) → vehicle, route, ETA, condition

  ──────────────────────────────────────────────────────────────────────────
  [4] VENDOR CONFIRMS DELIVERY — switch to Account[4] (Vendor)
  ──────────────────────────────────────────────────────────────────────────

  confirmDelivery(
      1,                        ← batchId
      49,                       ← 49 kg received (1 kg variance noted)
      1,                        ← Condition: Good
      "1 kg short from declared 50 kg. Product quality acceptable."
  )

  → Expected event: DeliveryConfirmed(batchId=1, vendor=Account[4], ...)
  → Call getBatchStatus(1)   → "Delivered Chain of Custody Closed"
  → Call getDeliveryRecord(1) → vendor, qty, condition, notes

  ──────────────────────────────────────────────────────────────────────────
  [5] READ THE FULL AUDIT TRAIL — any account
  ──────────────────────────────────────────────────────────────────────────

  getBatchAuditTrail(1)
  → Returns array: [1, 2, 3, 4]  (4 audit entries for batch 1)

  getAuditEntry(1)  → BATCH_REGISTERED
  getAuditEntry(2)  → OWNERSHIP_TRANSFERRED
  getAuditEntry(3)  → SHIPMENT_LOGGED
  getAuditEntry(4)  → DELIVERY_CONFIRMED

  Each entry shows: batchId, action label, actor address, role, details string, timestamp

  ──────────────────────────────────────────────────────────────────────────
  [6] SIMULATE A SECOND BATCH (e.g., Shiitake)
  ──────────────────────────────────────────────────────────────────────────

  Switch to Account[1] (Farmer), call registerBatch again:
  registerBatch(1, 30, "Dela Cruz Mushroom Farm", "Lolomboy", "Bocaue, Bulacan", "Shiitake on oak sawdust.")
  → batchId = 2, batchCode = "FTPH-2026-00002"

  Then repeat Steps 2–5 for batchId=2.

  ──────────────────────────────────────────────────────────────────────────
  VERIFY ROLE ENFORCEMENT (EXPECTED FAILURES)
  ──────────────────────────────────────────────────────────────────────────

  • Try calling registerBatch from Account[2] (Trader)
    → Reverts: "MushChain: incorrect role for this action"

  • Try calling confirmDelivery on batchId=1 before logShipment
    → Reverts: "MushChain: batch must be InTransit before delivery can be confirmed"

  • Try calling transferToTrader from Account[2] (Trader) for a batch they don't own
    → Reverts: "MushChain: caller does not own this batch"

  These reverts confirm the workflow is tamper-proof and role-enforced.
 ════════════════════════════════════════════════════════════════════════════
*/
