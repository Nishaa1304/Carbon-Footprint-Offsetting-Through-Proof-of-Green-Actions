// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Carbon Footprint Offsetting Through Proof-of-Green-Actions
 * @dev A smart contract system for verifying and rewarding eco-friendly actions
 * @author Carbon Footprint Offsetting Project
 */
contract Project {
    
    // Struct to define different types of green actions
    struct GreenAction {
        string actionType;
        uint256 carbonCredits;
        uint256 requiredStake;
        bool isActive;
    }
    
    // Struct to track user's green action submissions
    struct ActionSubmission {
        address user;
        uint256 actionId;
        string proofHash; // IPFS hash or other proof identifier
        uint256 timestamp;
        uint256 stakeAmount;
        bool isVerified;
        bool isRewarded;
        uint256 verificationCount;
    }
    
    // Struct to track user reputation and stats
    struct UserProfile {
        uint256 totalCarbonCredits;
        uint256 reputationScore;
        uint256 successfulActions;
        uint256 totalStaked;
        bool isVerifier;
    }
    
    // State variables
    mapping(uint256 => GreenAction) public greenActions;
    mapping(uint256 => ActionSubmission) public submissions;
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => mapping(address => bool)) public hasVerified;
    
    uint256 public nextActionId;
    uint256 public nextSubmissionId;
    uint256 public constant VERIFICATION_THRESHOLD = 3;
    uint256 public constant VERIFIER_REWARD = 10;
    uint256 public constant MIN_REPUTATION_TO_VERIFY = 100;
    
    address public owner;
    
    // Events
    event GreenActionAdded(uint256 indexed actionId, string actionType, uint256 carbonCredits);
    event ActionSubmitted(uint256 indexed submissionId, address indexed user, uint256 indexed actionId);
    event ActionVerified(uint256 indexed submissionId, address indexed verifier);
    event CarbonCreditsRewarded(address indexed user, uint256 credits);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyVerifier() {
        require(userProfiles[msg.sender].isVerifier || 
                userProfiles[msg.sender].reputationScore >= MIN_REPUTATION_TO_VERIFY, 
                "Not authorized to verify");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        
        // Initialize some default green actions
        _addGreenAction("Solar Panel Installation", 500, 0.1 ether);
        _addGreenAction("Tree Planting", 50, 0.01 ether);
        _addGreenAction("Electric Vehicle Purchase", 1000, 0.2 ether);
        _addGreenAction("Composting Setup", 100, 0.02 ether);
        _addGreenAction("Energy Efficient Appliances", 200, 0.05 ether);
    }
    
    /**
     * @dev Core Function 1: Submit proof of green action
     * @param _actionId The ID of the green action being claimed
     * @param _proofHash IPFS hash or identifier for proof documentation
     */
    function submitGreenAction(uint256 _actionId, string memory _proofHash) external payable {
        require(_actionId < nextActionId, "Invalid action ID");
        require(greenActions[_actionId].isActive, "Action is not active");
        require(msg.value >= greenActions[_actionId].requiredStake, "Insufficient stake amount");
        require(bytes(_proofHash).length > 0, "Proof hash cannot be empty");
        
        // Store the submission
        submissions[nextSubmissionId] = ActionSubmission({
            user: msg.sender,
            actionId: _actionId,
            proofHash: _proofHash,
            timestamp: block.timestamp,
            stakeAmount: msg.value,
            isVerified: false,
            isRewarded: false,
            verificationCount: 0
        });
        
        // Update user's total staked amount
        userProfiles[msg.sender].totalStaked += msg.value;
        
        emit ActionSubmitted(nextSubmissionId, msg.sender, _actionId);
        nextSubmissionId++;
    }
    
    /**
     * @dev Core Function 2: Verify submitted green actions
     * @param _submissionId The ID of the submission to verify
     * @param _isValid Whether the submission is valid or not
     */
    function verifyAction(uint256 _submissionId, bool _isValid) external onlyVerifier {
        require(_submissionId < nextSubmissionId, "Invalid submission ID");
        require(!hasVerified[_submissionId][msg.sender], "Already verified this submission");
        require(!submissions[_submissionId].isVerified, "Submission already verified");
        
        ActionSubmission storage submission = submissions[_submissionId];
        hasVerified[_submissionId][msg.sender] = true;
        
        if (_isValid) {
            submission.verificationCount++;
            
            // If threshold reached, mark as verified and reward
            if (submission.verificationCount >= VERIFICATION_THRESHOLD) {
                submission.isVerified = true;
                _rewardUser(submission.user, submission.actionId, submission.stakeAmount);
                submission.isRewarded = true;
            }
        }
        
        // Reward verifier with reputation points
        userProfiles[msg.sender].reputationScore += VERIFIER_REWARD;
        
        emit ActionVerified(_submissionId, msg.sender);
        emit ReputationUpdated(msg.sender, userProfiles[msg.sender].reputationScore);
    }
    
    /**
     * @dev Core Function 3: Offset carbon footprint using accumulated credits
     * @param _creditsToOffset Amount of carbon credits to use for offsetting
     */
    function offsetCarbonFootprint(uint256 _creditsToOffset) external {
        require(_creditsToOffset > 0, "Credits must be greater than 0");
        require(userProfiles[msg.sender].totalCarbonCredits >= _creditsToOffset, 
                "Insufficient carbon credits");
        
        // Deduct credits from user's balance
        userProfiles[msg.sender].totalCarbonCredits -= _creditsToOffset;
        
        // In a real implementation, this would interact with certified carbon offset providers
        // For now, we'll emit an event to track the offsetting
        emit CarbonCreditsRewarded(msg.sender, _creditsToOffset);
    }
    
    // Internal function to reward users for verified green actions
    function _rewardUser(address _user, uint256 _actionId, uint256 _stakeAmount) internal {
        uint256 carbonCredits = greenActions[_actionId].carbonCredits;
        
        // Update user profile
        UserProfile storage profile = userProfiles[_user];
        profile.totalCarbonCredits += carbonCredits;
        profile.successfulActions++;
        profile.reputationScore += carbonCredits / 10; // Reputation bonus
        
        // Return stake to user
        payable(_user).transfer(_stakeAmount);
        
        emit CarbonCreditsRewarded(_user, carbonCredits);
        emit ReputationUpdated(_user, profile.reputationScore);
    }
    
    // Internal function to add new green actions (used in constructor)
    function _addGreenAction(string memory _actionType, uint256 _carbonCredits, uint256 _requiredStake) internal {
        greenActions[nextActionId] = GreenAction({
            actionType: _actionType,
            carbonCredits: _carbonCredits,
            requiredStake: _requiredStake,
            isActive: true
        });
        
        emit GreenActionAdded(nextActionId, _actionType, _carbonCredits);
        nextActionId++;
    }
    
    // Owner function to add new green actions
    function addGreenAction(string memory _actionType, uint256 _carbonCredits, uint256 _requiredStake) 
        external onlyOwner {
        _addGreenAction(_actionType, _carbonCredits, _requiredStake);
    }
    
    // Function to authorize verifiers
    function authorizeVerifier(address _verifier) external onlyOwner {
        userProfiles[_verifier].isVerifier = true;
    }
    
    // View functions
    function getUserProfile(address _user) external view returns (UserProfile memory) {
        return userProfiles[_user];
    }
    
    function getSubmission(uint256 _submissionId) external view returns (ActionSubmission memory) {
        return submissions[_submissionId];
    }
    
    function getGreenAction(uint256 _actionId) external view returns (GreenAction memory) {
        return greenActions[_actionId];
    }
    
    // Emergency function to withdraw contract balance (owner only)
    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
