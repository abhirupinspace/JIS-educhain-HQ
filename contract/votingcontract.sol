// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleTopicVote {
    // The topic for which votes are being cast.
    string public topic = "Should we adopt blockchain voting?";
    
    // Struct to store vote counts for the topic.
    struct VoteCount {
        uint256 yes;
        uint256 no;
    }
    
    // Instance to store yes and no vote counts.
    VoteCount public votes;
    
    // Mapping to track if an address has already voted.
    mapping(address => bool) public hasVoted;

    // Event emitted when a vote is cast.
    event Voted(address voter, bool vote);

    /**
     * @notice Cast your vote on the topic.
     * @param _vote A boolean representing the vote:
     *              true for "yes", false for "no".
     * Requirements:
     * - An address can only vote once.
     */
    function vote(bool _vote) external {
        // Ensure that the sender has not already voted.
        require(!hasVoted[msg.sender], "You have already voted");

        // Mark that the sender has now voted.
        hasVoted[msg.sender] = true;
        
        // Count the vote based on the value of _vote.
        if (_vote) {
            votes.yes++;
        } else {
            votes.no++;
        }
        
        // Emit an event to log the vote.
        emit Voted(msg.sender, _vote);
    }

    /**
     * @notice Retrieve the current vote counts.
     * @return yesVotes The number of "yes" votes.
     * @return noVotes The number of "no" votes.
     */
    function getVotes() external view returns (uint256 yesVotes, uint256 noVotes) {
        return (votes.yes, votes.no);
    }
}
