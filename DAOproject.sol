// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract demo{
    struct Proposal{
        uint id;
        string description;
        uint amount;
        address payable recipient;
        uint votes;
        uint end;
        bool isExecuted;
    }

    mapping (address => bool) private isInvestor;
    mapping (address => uint) public numofshares;
    // mapping (address => mapping(address =>bool)) public isVoted;
    mapping(uint => mapping(address => bool)) public isVoted;
    // mapping (address => mapping(uint=> bool)) public withdrawlStatus;
    address[] public investorsList;
    mapping(uint => Proposal) public proposals;

    uint public totalShares;
    uint public availableFunds;
    uint public contributionTimeEnd;
    uint public voteTime;
    uint public nextProposalId;
    uint public quorum;
    address public manager;

    constructor (uint _contributionTimeEnd , uint _voteTime, uint _quorum){
        require(_quorum > 0 && _quorum < 100, "Not Valid Values");
        contributionTimeEnd = block.timestamp + _contributionTimeEnd;
        voteTime = _voteTime;
        quorum = _quorum;
        manager = msg.sender;
    }
  
    modifier onlyInvestor(){
        require (isInvestor[msg.sender] == true, "You are not an Investor");
        _;
    }

    modifier onlyManager(){
        require (manager == msg.sender, "You are not a Manager");
        _;
    }

    function contribution() public payable{
        require (contributionTimeEnd >= block.timestamp,"Contribution Time Ended");
        require(msg.value > 0, "Send more than zero ether");
        isInvestor[msg.sender] = true;
        numofshares[msg.sender]=numofshares [msg.sender] +msg.value;
        totalShares += msg.value ;
        availableFunds += msg.value;
        investorsList.push(msg.sender);
    }

    function redeemShare(uint amount)public onlyInvestor(){
        require(numofshares[msg.sender] >= amount, "You dont have enough shares");
        require(availableFunds >= amount, "Not enough funds");
        numofshares[msg.sender] -= amount;
        if(numofshares[msg.sender] == 0){
            isInvestor[msg.sender] = false;
        }
        availableFunds -= amount;
        payable (msg.sender).transfer(amount);
    }

    function transferShare(uint amount,address to) public onlyInvestor(){
        require(numofshares[msg.sender] >= amount,"you dont have enough shares");
        require(availableFunds >= amount, "Not enough funds");
        numofshares[msg.sender] -= amount; 
        if(numofshares[msg.sender] == 0){
            isInvestor[msg.sender] = false;
        }
        numofshares[to] += amount;
        isInvestor[to] = true;
        investorsList.push(to);
    }

    function createProposal(string calldata description, uint amount, address payable recipient) public onlyManager {
        require(availableFunds >= amount, "Not enough funds");
        proposals[nextProposalId] = Proposal(nextProposalId, description, amount, recipient, 0, block.timestamp + voteTime, false);
        nextProposalId++;
    }

    function voteProposal(uint proposalId) public onlyInvestor(){
        Proposal storage proposal = proposals[proposalId];
        require(!isVoted[proposalId][msg.sender], "You have already voted for this proposal");
        require(proposal.end >= block.timestamp, "Voting Time Ended");
        require(!proposal.isExecuted, "Proposal has already been executed");
        isVoted[proposalId][msg.sender] = true;
        proposal.votes += numofshares[msg.sender];
}

    function executeProposal(uint proposalId) public onlyManager(){
        Proposal storage proposal = proposals[proposalId];
        require (((proposal.votes*100)/totalShares) >= quorum, "Majority does not support");
        proposal.isExecuted = true;
        availableFunds -= proposal.amount;
        _transfer(proposal.amount, proposal.recipient);
    }

    function _transfer(uint amount, address payable recipient) public {
        recipient.transfer(amount);  
    }

    function ProposalList() public view returns (Proposal[] memory){
        Proposal[] memory arr = new Proposal[](nextProposalId - 1);
        for(uint i=1; i <nextProposalId; i++)
        {
            arr[i+1] = proposals[i];
        }
        return arr;
    }
}