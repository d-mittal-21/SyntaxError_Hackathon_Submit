// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        uint256 refundRequestCount;
    }

    event FundTransfer(address _from, string _name, uint256 _value);

    mapping(address => string) contributorNames; //I think it should be inside the struct but its giving an error while returning in the function getCampaigns
    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];
        require(campaign.deadline < block.timestamp, "Sorry but The deadline has already passed");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.deadline = _deadline;
        campaign.refundRequestCount = 0;

        numberOfCampaigns++;
        return numberOfCampaigns - 1;

    }

    function contributeToCampaign(uint256 _id, string memory _name) public payable {
        Campaign storage campaign = campaigns[_id];
        require(msg.value > 0, "Please contribute a positive amount");
        require(campaign.amountCollected <= campaign.target, "The Campaign has already reached its Funding Goal");
        uint256 amount = msg.value;
        campaign.donators.push(msg.sender);
        contributorNames[msg.sender] = _name;
        campaign.donations.push(amount);
        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
        emit FundTransfer(msg.sender, _name, msg.value);
    }
    function getContributors(uint256 _id) view public returns(address[] memory,uint256[] memory, string[] memory) {
        uint n = campaigns[_id].donations.length;
        string[] memory ContributorNames;
        for(uint i = 0; i< n; i++) {
            ContributorNames[i] = contributorNames[campaigns[_id].donators[i]];
        }
        return(campaigns[_id].donators, campaigns[_id].donations, ContributorNames);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns); //preDefining an empty array for all campaigns
        for (uint i = 0; i< numberOfCampaigns; i++){
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }
        return allCampaigns;
    }

    function refund(uint256 _id) public {
        if(msg.sender != campaigns[_id].owner) {
            campaigns[_id].refundRequestCount ++ ;
        }
        require(msg.sender == campaigns[_id].owner, "only Owner of the Campaign can do this");
        require(address(this).balance >= campaigns[_id].amountCollected);
        payable(msg.sender).transfer(campaigns[_id].amountCollected);
    }





}