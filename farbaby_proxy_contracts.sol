// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

/**
 * @title FarbabyGameV1
 * @dev Main game contract - upgradeable proxy implementation
 */
contract FarbabyGameV1 is 
    Initializable, 
    UUPSUpgradeable, 
    OwnableUpgradeable, 
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721Upgradeable 
{
    // ============= STRUCTS =============
    
    struct Player {
        string nickname;
        string sex; // Optional
        uint256 registrationTime;
        uint256 totalBabies;
        uint256 reputation;
        bool isActive;
        uint256[] ownedBabies;
        uint256[] sharedBabies;
    }
    
    struct Baby {
        uint256 id;
        string name;
        string appearance; // 10 character string for visual traits
        uint256 birthTime;
        uint256 hatchTime; // 3 days after creation
        bool isHatched;
        uint256 lastFed;
        uint256 health;
        uint256 happiness;
        uint256 intelligence;
        uint256 social;
        uint256 energy;
        uint256 hunger;
        uint256 hygiene;
        uint256 stage; // 0=egg, 1=newborn, 2=infant, 3=toddler, 4=preschooler, 5=child
        bool isAlive;
        address[] parents;
        uint256[] genetics;
        mapping(address => uint256) parentTrust;
        mapping(address => bool) carePermissions;
    }
    
    struct FamilyGroup {
        uint256 id;
        address[] members;
        uint256[] sharedBabies;
        string familyName;
        uint256 cooperationScore;
        uint256 totalResources;
        mapping(address => uint256) contributions;
        mapping(address => bool) isMember;
    }
    
    struct Activity {
        string name;
        uint256 cost;
        uint256 duration;
        uint256 healthEffect;
        uint256 happinessEffect;
        uint256 intelligenceEffect;
        uint256 socialEffect;
        uint256 requiredStage;
        bool isEnabled;
    }
    
    // ============= STATE VARIABLES =============
    
    mapping(address => Player) public players;
    mapping(uint256 => Baby) public babies;
    mapping(uint256 => FamilyGroup) public families;
    mapping(string => Activity) public activities;
    
    uint256 public nextBabyId;
    uint256 public nextFamilyId;
    uint256 public hatchingPeriod;
    uint256 public feedingInterval;
    uint256 public baseHatchCost;
    uint256 public freeHatchCost;
    
    // Fee structure
    mapping(string => uint256) public fees;
    
    // Activity costs
    mapping(string => uint256) public activityCosts;
    
    // Game parameters
    uint256 public maxParentsPerBaby;
    uint256 public maxBabiesPerPlayer;
    uint256 public starvationTime;
    
    // ============= EVENTS =============
    
    event PlayerRegistered(address indexed player, string nickname);
    event BabyCreated(uint256 indexed babyId, address[] parents);
    event BabyHatched(uint256 indexed babyId);
    event BabyFed(uint256 indexed babyId, address indexed parent, string foodType);
    event BabyDied(uint256 indexed babyId, string reason);
    event ActivityPerformed(uint256 indexed babyId, string activity, address indexed performer);
    event FamilyCreated(uint256 indexed familyId, address[] members);
    event FamilyJoined(uint256 indexed familyId, address indexed member);
    event FeesUpdated(string feeType, uint256 newAmount);
    
    // ============= INITIALIZER =============
    
    function initialize() public initializer {
        __ERC721_init("Farbaby", "BABY");
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        
        // Set initial parameters
        hatchingPeriod = 3 days;
        feedingInterval = 2 days;
        baseHatchCost = 0.01 ether;
        freeHatchCost = 0;
        maxParentsPerBaby = 4;
        maxBabiesPerPlayer = 10;
        starvationTime = 4 days;
        nextBabyId = 1;
        nextFamilyId = 1;
        
        // Initialize fees
        fees["normalFood"] = 0.001 ether;
        fees["goodFood"] = 0.5 ether;
        fees["premiumFood"] = 1 ether;
        fees["adoption"] = 0.05 ether;
        fees["schooling"] = 0.1 ether;
        fees["playmate"] = 0.02 ether;
        fees["grandmaVisit"] = 0.03 ether;
        fees["medical"] = 0.2 ether;
        
        // Initialize activities
        _initializeActivities();
    }
    
    function _initializeActivities() internal {
        activities["feeding"] = Activity({
            name: "feeding",
            cost: 0.001 ether,
            duration: 0,
            healthEffect: 10,
            happinessEffect: 5,
            intelligenceEffect: 0,
            socialEffect: 0,
            requiredStage: 1,
            isEnabled: true
        });
        
        activities["playing"] = Activity({
            name: "playing",
            cost: 0.005 ether,
            duration: 1 hours,
            healthEffect: 0,
            happinessEffect: 15,
            intelligenceEffect: 5,
            socialEffect: 5,
            requiredStage: 2,
            isEnabled: true
        });
        
        activities["schooling"] = Activity({
            name: "schooling",
            cost: 0.1 ether,
            duration: 8 hours,
            healthEffect: 0,
            happinessEffect: -5,
            intelligenceEffect: 20,
            socialEffect: 10,
            requiredStage: 4,
            isEnabled: true
        });
        
        activities["playmate"] = Activity({
            name: "playmate",
            cost: 0.02 ether,
            duration: 2 hours,
            healthEffect: 5,
            happinessEffect: 20,
            intelligenceEffect: 5,
            socialEffect: 25,
            requiredStage: 2,
            isEnabled: true
        });
        
        activities["grandmaVisit"] = Activity({
            name: "grandmaVisit",
            cost: 0.03 ether,
            duration: 24 hours,
            healthEffect: 15,
            happinessEffect: 25,
            intelligenceEffect: 10,
            socialEffect: 15,
            requiredStage: 1,
            isEnabled: true
        });
    }
    
    // ============= AUTHORIZATION =============
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    // ============= PLAYER REGISTRATION =============
    
    function registerPlayer(string calldata _nickname, string calldata _sex) external {
        require(bytes(_nickname).length > 0, "Nickname required");
        require(!players[msg.sender].isActive, "Player already registered");
        
        players[msg.sender] = Player({
            nickname: _nickname,
            sex: _sex,
            registrationTime: block.timestamp,
            totalBabies: 0,
            reputation: 100,
            isActive: true,
            ownedBabies: new uint256[](0),
            sharedBabies: new uint256[](0)
        });
        
        emit PlayerRegistered(msg.sender, _nickname);
    }
    
    // ============= BABY CREATION & HATCHING =============
    
    function createBaby(
        string calldata _name,
        string calldata _appearance,
        address[] calldata _coParents
    ) external payable nonReentrant {
        require(players[msg.sender].isActive, "Player not registered");
        require(_coParents.length > 0 && _coParents.length < maxParentsPerBaby, "Invalid co-parents count");
        require(players[msg.sender].ownedBabies.length < maxBabiesPerPlayer, "Max babies reached");
        require(bytes(_appearance).length == 10, "Appearance must be exactly 10 characters");
        
        // Calculate cost (free if with co-parents, paid if solo)
        uint256 cost = _coParents.length > 0 ? freeHatchCost : baseHatchCost;
        require(msg.value >= cost, "Insufficient payment");
        
        // Create baby
        uint256 babyId = nextBabyId++;
        Baby storage baby = babies[babyId];
        
        baby.id = babyId;
        baby.name = _name;
        baby.appearance = _appearance;
        baby.birthTime = block.timestamp;
        baby.hatchTime = block.timestamp + hatchingPeriod;
        baby.isHatched = false;
        baby.health = 100;
        baby.happiness = 100;
        baby.intelligence = 50;
        baby.social = 50;
        baby.energy = 100;
        baby.hunger = 50;
        baby.hygiene = 100;
        baby.stage = 0;
        baby.isAlive = true;
        
        // Add parents
        baby.parents.push(msg.sender);
        for (uint256 i = 0; i < _coParents.length; i++) {
            require(players[_coParents[i]].isActive, "Co-parent not registered");
            baby.parents.push(_coParents[i]);
            baby.carePermissions[_coParents[i]] = true;
        }
        baby.carePermissions[msg.sender] = true;
        
        // Update player records
        players[msg.sender].ownedBabies.push(babyId);
        players[msg.sender].totalBabies++;
        
        for (uint256 i = 0; i < _coParents.length; i++) {
            players[_coParents[i]].sharedBabies.push(babyId);
        }
        
        // Mint NFT
        _safeMint(msg.sender, babyId);
        
        emit BabyCreated(babyId, baby.parents);
    }
    
    function hatchBaby(uint256 _babyId) external {
        Baby storage baby = babies[_babyId];
        require(baby.isAlive, "Baby doesn't exist");
        require(!baby.isHatched, "Baby already hatched");
        require(block.timestamp >= baby.hatchTime, "Hatching period not complete");
        require(baby.carePermissions[msg.sender], "Not authorized");
        
        baby.isHatched = true;
        baby.stage = 1; // Newborn
        baby.lastFed = block.timestamp;
        
        emit BabyHatched(_babyId);
    }
    
    // ============= FEEDING SYSTEM =============
    
    function feedBaby(uint256 _babyId, string calldata _foodType) external payable nonReentrant {
        Baby storage baby = babies[_babyId];
        require(baby.isAlive, "Baby is not alive");
        require(baby.isHatched, "Baby not hatched yet");
        require(baby.carePermissions[msg.sender], "Not authorized to care for baby");
        
        uint256 cost = fees[_foodType];
        require(msg.value >= cost, "Insufficient payment for food");
        
        // Check if feeding is needed
        require(block.timestamp >= baby.lastFed + feedingInterval, "Baby not hungry yet");
        
        // Apply feeding effects
        if (keccak256(bytes(_foodType)) == keccak256(bytes("normalFood"))) {
            baby.health += 5;
            baby.happiness += 5;
            baby.hunger = 100;
        } else if (keccak256(bytes(_foodType)) == keccak256(bytes("goodFood"))) {
            baby.health += 15;
            baby.happiness += 10;
            baby.hunger = 100;
            baby.intelligence += 2;
        } else if (keccak256(bytes(_foodType)) == keccak256(bytes("premiumFood"))) {
            baby.health += 25;
            baby.happiness += 20;
            baby.hunger = 100;
            baby.intelligence += 5;
            baby.social += 3;
        }
        
        // Cap stats at 100
        _capStats(baby);
        
        baby.lastFed = block.timestamp;
        
        emit BabyFed(_babyId, msg.sender, _foodType);
    }
    
    // ============= ACTIVITIES =============
    
    function performActivity(uint256 _babyId, string calldata _activityName) external payable nonReentrant {
        Baby storage baby = babies[_babyId];
        require(baby.isAlive, "Baby is not alive");
        require(baby.isHatched, "Baby not hatched yet");
        require(baby.carePermissions[msg.sender], "Not authorized");
        
        Activity storage activity = activities[_activityName];
        require(activity.isEnabled, "Activity not available");
        require(baby.stage >= activity.requiredStage, "Baby too young for activity");
        require(msg.value >= activity.cost, "Insufficient payment");
        
        // Apply activity effects
        baby.health = _addWithCap(baby.health, activity.healthEffect);
        baby.happiness = _addWithCap(baby.happiness, activity.happinessEffect);
        baby.intelligence = _addWithCap(baby.intelligence, activity.intelligenceEffect);
        baby.social = _addWithCap(baby.social, activity.socialEffect);
        
        emit ActivityPerformed(_babyId, _activityName, msg.sender);
    }
    
    // ============= FAMILY SYSTEM =============
    
    function createFamily(
        string calldata _familyName,
        address[] calldata _members
    ) external returns (uint256) {
        require(players[msg.sender].isActive, "Player not registered");
        
        uint256 familyId = nextFamilyId++;
        FamilyGroup storage family = families[familyId];
        
        family.id = familyId;
        family.familyName = _familyName;
        family.cooperationScore = 100;
        family.totalResources = 0;
        
        // Add creator as member
        family.members.push(msg.sender);
        family.isMember[msg.sender] = true;
        
        // Add other members
        for (uint256 i = 0; i < _members.length; i++) {
            require(players[_members[i]].isActive, "Member not registered");
            family.members.push(_members[i]);
            family.isMember[_members[i]] = true;
        }
        
        emit FamilyCreated(familyId, family.members);
        return familyId;
    }
    
    function joinFamily(uint256 _familyId) external {
        require(players[msg.sender].isActive, "Player not registered");
        FamilyGroup storage family = families[_familyId];
        require(!family.isMember[msg.sender], "Already a member");
        
        family.members.push(msg.sender);
        family.isMember[msg.sender] = true;
        
        emit FamilyJoined(_familyId, msg.sender);
    }
    
    function addBabyToFamily(uint256 _familyId, uint256 _babyId) external {
        FamilyGroup storage family = families[_familyId];
        require(family.isMember[msg.sender], "Not a family member");
        require(babies[_babyId].carePermissions[msg.sender], "Not authorized for baby");
        
        family.sharedBabies.push(_babyId);
        
        // Grant care permissions to all family members
        for (uint256 i = 0; i < family.members.length; i++) {
            babies[_babyId].carePermissions[family.members[i]] = true;
        }
    }
    
    // ============= ADOPTION SYSTEM =============
    
    function adoptBaby(uint256 _babyId) external payable nonReentrant {
        require(players[msg.sender].isActive, "Player not registered");
        require(msg.value >= fees["adoption"], "Insufficient adoption fee");
        
        Baby storage baby = babies[_babyId];
        require(baby.isAlive, "Baby is not alive");
        require(baby.parents.length < maxParentsPerBaby, "Max parents reached");
        require(!baby.carePermissions[msg.sender], "Already a parent");
        
        baby.parents.push(msg.sender);
        baby.carePermissions[msg.sender] = true;
        players[msg.sender].sharedBabies.push(_babyId);
    }
    
    // ============= HEALTH & LIFECYCLE =============
    
    function checkBabyHealth(uint256 _babyId) external {
        Baby storage baby = babies[_babyId];
        require(baby.isAlive, "Baby already dead");
        require(baby.isHatched, "Baby not hatched yet");
        
        // Check starvation
        if (block.timestamp > baby.lastFed + starvationTime) {
            baby.isAlive = false;
            emit BabyDied(_babyId, "Starvation");
            return;
        }
        
        // Decay stats over time
        uint256 timeSinceLastFed = block.timestamp - baby.lastFed;
        uint256 hungerDecay = (timeSinceLastFed * 10) / feedingInterval;
        
        if (baby.hunger > hungerDecay) {
            baby.hunger -= hungerDecay;
        } else {
            baby.hunger = 0;
        }
        
        // If hunger reaches 0, start affecting health
        if (baby.hunger == 0) {
            baby.health = baby.health > 5 ? baby.health - 5 : 0;
            baby.happiness = baby.happiness > 10 ? baby.happiness - 10 : 0;
        }
        
        // Death from poor health
        if (baby.health == 0) {
            baby.isAlive = false;
            emit BabyDied(_babyId, "Poor health");
        }
    }
    
    function growBaby(uint256 _babyId) external {
        Baby storage baby = babies[_babyId];
        require(baby.isAlive, "Baby is not alive");
        require(baby.isHatched, "Baby not hatched yet");
        
        uint256 ageInDays = (block.timestamp - baby.hatchTime) / 1 days;
        uint256 expectedStage = 1 + (ageInDays / 7); // 1 week per stage
        
        if (expectedStage > baby.stage && expectedStage <= 5) {
            baby.stage = expectedStage;
            
            // Bonus stats for healthy growth
            if (baby.health > 80) {
                baby.intelligence += 5;
                baby.social += 3;
            }
        }
    }
    
    // ============= UTILITY FUNCTIONS =============
    
    function _capStats(Baby storage baby) internal {
        baby.health = baby.health > 100 ? 100 : baby.health;
        baby.happiness = baby.happiness > 100 ? 100 : baby.happiness;
        baby.intelligence = baby.intelligence > 100 ? 100 : baby.intelligence;
        baby.social = baby.social > 100 ? 100 : baby.social;
        baby.energy = baby.energy > 100 ? 100 : baby.energy;
        baby.hunger = baby.hunger > 100 ? 100 : baby.hunger;
        baby.hygiene = baby.hygiene > 100 ? 100 : baby.hygiene;
    }
    
    function _addWithCap(uint256 current, uint256 addition) internal pure returns (uint256) {
        uint256 result = current + addition;
        return result > 100 ? 100 : result;
    }
    
    // ============= ADMIN FUNCTIONS =============
    
    function updateFees(string calldata _feeType, uint256 _newAmount) external onlyOwner {
        fees[_feeType] = _newAmount;
        emit FeesUpdated(_feeType, _newAmount);
    }
    
    function updateGameParameters(
        uint256 _hatchingPeriod,
        uint256 _feedingInterval,
        uint256 _starvationTime,
        uint256 _maxParents,
        uint256 _maxBabies
    ) external onlyOwner {
        hatchingPeriod = _hatchingPeriod;
        feedingInterval = _feedingInterval;
        starvationTime = _starvationTime;
        maxParentsPerBaby = _maxParents;
        maxBabiesPerPlayer = _maxBabies;
    }
    
    function addActivity(
        string calldata _name,
        uint256 _cost,
        uint256 _duration,
        uint256 _healthEffect,
        uint256 _happinessEffect,
        uint256 _intelligenceEffect,
        uint256 _socialEffect,
        uint256 _requiredStage
    ) external onlyOwner {
        activities[_name] = Activity({
            name: _name,
            cost: _cost,
            duration: _duration,
            healthEffect: _healthEffect,
            happinessEffect: _happinessEffect,
            intelligenceEffect: _intelligenceEffect,
            socialEffect: _socialEffect,
            requiredStage: _requiredStage,
            isEnabled: true
        });
    }
    
    function toggleActivity(string calldata _name) external onlyOwner {
        activities[_name].isEnabled = !activities[_name].isEnabled;
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function withdrawFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    // ============= VIEW FUNCTIONS =============
    
    function getBabyInfo(uint256 _babyId) external view returns (
        string memory name,
        string memory appearance,
        uint256 birthTime,
        uint256 stage,
        uint256 health,
        uint256 happiness,
        uint256 intelligence,
        uint256 social,
        uint256 hunger,
        bool isAlive,
        address[] memory parents
    ) {
        Baby storage baby = babies[_babyId];
        return (
            baby.name,
            baby.appearance,
            baby.birthTime,
            baby.stage,
            baby.health,
            baby.happiness,
            baby.intelligence,
            baby.social,
            baby.hunger,
            baby.isAlive,
            baby.parents
        );
    }
    
    function getPlayerInfo(address _player) external view returns (
        string memory nickname,
        uint256 totalBabies,
        uint256 reputation,
        uint256[] memory ownedBabies,
        uint256[] memory sharedBabies
    ) {
        Player storage player = players[_player];
        return (
            player.nickname,
            player.totalBabies,
            player.reputation,
            player.ownedBabies,
            player.sharedBabies
        );
    }
    
    function getFamilyInfo(uint256 _familyId) external view returns (
        string memory familyName,
        address[] memory members,
        uint256[] memory sharedBabies,
        uint256 cooperationScore
    ) {
        FamilyGroup storage family = families[_familyId];
        return (
            family.familyName,
            family.members,
            family.sharedBabies,
            family.cooperationScore
        );
    }
    
    function getActivityInfo(string calldata _name) external view returns (
        uint256 cost,
        uint256 duration,
        uint256 healthEffect,
        uint256 happinessEffect,
        uint256 intelligenceEffect,
        uint256 socialEffect,
        uint256 requiredStage,
        bool isEnabled
    ) {
        Activity storage activity = activities[_name];
        return (
            activity.cost,
            activity.duration,
            activity.healthEffect,
            activity.happinessEffect,
            activity.intelligenceEffect,
            activity.socialEffect,
            activity.requiredStage,
            activity.isEnabled
        );
    }
    
    function isPlayerRegistered(address _player) external view returns (bool) {
        return players[_player].isActive;
    }
    
    function canFeedBaby(uint256 _babyId) external view returns (bool) {
        Baby storage baby = babies[_babyId];
        return baby.isAlive && 
               baby.isHatched && 
               block.timestamp >= baby.lastFed + feedingInterval;
    }
    
    function timeUntilHatch(uint256 _babyId) external view returns (uint256) {
        Baby storage baby = babies[_babyId];
        if (baby.isHatched) return 0;
        if (block.timestamp >= baby.hatchTime) return 0;
        return baby.hatchTime - block.timestamp;
    }
    
    function timeUntilStarvation(uint256 _babyId) external view returns (uint256) {
        Baby storage baby = babies[_babyId];
        if (!baby.isAlive || !baby.isHatched) return 0;
        uint256 starvationTime = baby.lastFed + starvationTime;
        if (block.timestamp >= starvationTime) return 0;
        return starvationTime - block.timestamp;
    }
}

// ============= PROXY DEPLOYMENT CONTRACT =============

contract FarbabyProxy {
    address public immutable implementation;
    
    constructor(address _implementation) {
        implementation = _implementation;
    }
    
    fallback() external payable {
        address impl = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    receive() external payable {}
}
