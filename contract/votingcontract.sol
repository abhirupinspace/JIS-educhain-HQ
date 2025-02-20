// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interface for the ERC20 governance token used to vote.
interface IERC20 {
    // Returns the token balance of a given account.
    function balanceOf(address account) external view returns (uint256);
}

contract VotingDApp {
    // Structure representing a proposal.
    struct Proposal {
        string description;  // A description of the proposal.
        uint256 voteCount;   // Total vote count (weighted by token balance).
        uint256 deadline;    // Timestamp when voting ends.
        bool executed;       // Flag to check if the proposal has been executed.
    }

    // ERC20 governance token that gives voting power.
    IERC20 public governanceToken;
    
    // The owner of the contract, typically the creator.
    address public owner;
    
    // Array to store all proposals.
    Proposal[] public proposals;
    
    // Mapping to track if an address has voted on a proposal (proposalId => voter address => voted status).
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Events to log proposal creation, votes, and execution.
    event ProposalCreated(uint256 proposalId, string description, uint256 deadline);
    event Voted(uint256 proposalId, address voter, uint256 weight);
    event ProposalExecuted(uint256 proposalId);

    // Modifier to restrict functions to only the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // Modifier to ensure the proposal exists.
    modifier proposalExists(uint256 proposalId) {
        require(proposalId < proposals.length, "Proposal does not exist");
        _;
    }

    // Constructor sets the governance token and assigns contract deployer as the owner.
    constructor(address _governanceToken) {
        governanceToken = IERC20(_governanceToken);
        owner = msg.sender;
    }

    /**
     * @notice Creates a new proposal.
     * @param _description A string describing the proposal.
     * @param _duration Duration (in seconds) for which voting will be open.
     * Only the contract owner can create proposals.
     */
    function createProposal(string memory _description, uint256 _duration) external onlyOwner {
        // Set the deadline by adding the duration to the current block timestamp.
        uint256 deadline = block.timestamp + _duration;
        // Add the new proposal to the proposals array.
        proposals.push(Proposal({
            description: _description,
            voteCount: 0,
            deadline: deadline,
            executed: false
        }));
        // Emit an event to log the proposal creation.
        emit ProposalCreated(proposals.length - 1, _description, deadline);
    }

    /**
     * @notice Allows token holders to vote on a proposal.
     * @param proposalId The ID of the proposal to vote on.
     * The function checks that the voting period is still open and that the voter hasn't already voted.
     */
    function vote(uint256 proposalId) external proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        // Ensure the proposal's voting period is still active.
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        // Check that the caller hasn't voted on this proposal already.
        require(!hasVoted[proposalId][msg.sender], "You have already voted");

        // Get the voter's token balance to determine their voting weight.
        uint256 weight = governanceToken.balanceOf(msg.sender);
        require(weight > 0, "Must hold tokens to vote");

        // Increment the proposal's vote count by the voter's token balance.
        proposal.voteCount += weight;
        // Mark that the voter has cast their vote on this proposal.
        hasVoted[proposalId][msg.sender] = true;

        // Emit an event to log the vote.
        emit Voted(proposalId, msg.sender, weight);
    }

    /**
     * @notice Executes a proposal after its voting period has ended.
     * @param proposalId The ID of the proposal to execute.
     * Marks the proposal as executed and emits an event.
     */
    function executeProposal(uint256 proposalId) external proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        // Ensure the voting period has ended.
        require(block.timestamp >= proposal.deadline, "Voting period not ended");
        // Ensure the proposal has not already been executed.
        require(!proposal.executed, "Proposal already executed");

        // Mark the proposal as executed.
        proposal.executed = true;
        // Emit an event to log the execution.
        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Retrieves details of a proposal.
     * @param proposalId The ID of the proposal.
     * @return description The description of the proposal.
     * @return voteCount The current weighted vote count.
     * @return deadline The timestamp when voting ends.
     * @return executed Whether the proposal has been executed.
     */
    function getProposal(uint256 proposalId) external view proposalExists(proposalId) returns (
        string memory description,
        uint256 voteCount,
        uint256 deadline,
        bool executed
    ) {
        Proposal memory proposal = proposals[proposalId];
        return (proposal.description, proposal.voteCount, proposal.deadline, proposal.executed);
    }

    /**
     * @notice Returns the total number of proposals.
     * @return The number of proposals in the contract.
     */
    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }
}
