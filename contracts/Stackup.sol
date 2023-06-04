//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Stackup {

    /*
      values that represent the player's quest status.
      Added 3 more values(REWARDED, APPROVED, REJECTED) to indicate the review result
      PS: although a new enum with these values could have been created, 
      adding them here made sense too as they too represent the player's quest status
    */
    enum playerQuestStatus {
        NOT_JOINED,
        JOINED,
        SUBMITTED,
        REWARDED,
        APPROVED,
        REJECTED
    }

    /*
      A struct to represent quest info,
      added 2 new values, startTime and endTime
    */
    struct Quest {
        uint256 questId;
        uint256 numberOfPlayers;
        string title;
        uint8 reward;
        uint256 numberOfRewards;
        uint256 startTime;
        uint256 endTime;
    }

    /*
      A struct to represent a campaign,
      Has a title, reward pool amount, no of Quests and
      an array quests of Quest type to hold the info of quests in the campaign,
      P.S: Functionality to Create a campaign and adding quests to it isn't implemented in the contract for now.
    */
    struct Campaign {
        string title;
        uint256 rewardPool;
        uint256 noOfQuests;
        Quest[] quests;
    }

    address public admin;
    uint256 public nextQuestId;
    mapping(uint256 => Quest) public quests;
    mapping(address => mapping(uint256 => playerQuestStatus)) public playerQuestStatuses;

    constructor() {
    admin = msg.sender;
  }

  /*
    Function to create a quest,takes in parameters for title, reward, no of rewards and 2 new parameters startsIn and endsIn.
    startsIn represents the number of days from now the quest will start in.
    endsIn represents the number of days from now the quest will end in.
    Also checks that the reward can't be zero, this is needed because,
    assume a scenario that admin mistakenly creates a quest with 0 reward_,
    realizes the mistake and tries to edit the quest using the editQuest function
    implemented below, the editQuest function would check if the quest exists(can't edit a non-existent quest) using
    the questExists modifier which would revert if the reward is 0 thus making the edit function unusable. 
  */

  function createQuest(
    string calldata title_,
    uint8 reward_,
    uint256 numberOfRewards_,
    uint256 startsIn,
    uint256 endsIn
  ) external onlyAdmin {
    //revert with an error if reward_ is 0
    if (reward_ == 0) revert RewardCannotBeZero();
    //Check that endsIn > 0, otherwise the quest will end as soon as it begins.
    require(endsIn > 0, "endsIn can't be 0");
    quests[nextQuestId].questId = nextQuestId;
    quests[nextQuestId].title = title_;
    quests[nextQuestId].reward = reward_;
    quests[nextQuestId].numberOfRewards = numberOfRewards_;
    // Assign the startTime of the quest as the (currentTime + noOfDays) it starts in
    quests[nextQuestId].startTime = block.timestamp + (startsIn * 1 minutes); 
    // Assign the endTime of the quest as the (currentTime + noOfDays) it ends in.
    quests[nextQuestId].endTime = block.timestamp + (endsIn * 1 minutes);
    nextQuestId++;
  }

  /*
    A function to edit an existing quest,
    quite the same as createQuest function with a difference that the quest must exist for it to be editted,
    raises a few imp question such as,
       which fields should be allowed to be editted and when? 
         - All fields could be allowed to be editted if done before the start of the quest.
         - only certain fields can be changed if its done before quest ends but after quest has started.
            - Here changing the title and startTime doesn't make sense.
            - It only makes sense to increment the existing values of reward, noOfRewards and endTime with the values given in parameters.
            - Because, generally that's how its been done in stackup quests, 
            - whenever done, the rewards, noOfRewards and quest endtime have only been increased.
  */
  function editQuest(
    uint256 questId, 
    string calldata title_,
    uint8 reward_,
    uint256 numberOfRewards_,
    uint256 startsIn,
    uint256 endsIn) 
    external onlyAdmin questExists(questId) {
        //revert with an error if reward_ is zero
        if (reward_ == 0) revert RewardCannotBeZero();
        //if quest hasn't started yet
        if(quests[questId].startTime > block.timestamp) {
            quests[questId].title = title_;
            quests[questId].reward = reward_;
            quests[questId].numberOfRewards = numberOfRewards_;
            quests[questId].startTime = block.timestamp + (startsIn * 1 minutes);
            quests[questId].endTime = block.timestamp + (endsIn * 1 minutes);
        }
        //quest has started but hasn't ended yet
        else if(quests[questId].endTime > block.timestamp) {
            //increment existing reward with reward_
            quests[questId].reward += reward_;
            //increment the noOfRewards with numberOfRewards_;
            quests[questId].numberOfRewards += numberOfRewards_;
            //increment the endTime wi
            quests[questId].endTime += (endsIn * 1 minutes); 
        }
        //Revert with an error if called after quest ends.
        else{
            revert CannotEditNow();
        }
    }

  // delete a quest from the quests mapping
  // And also when shud a quest be allowed to delete? 
  //   - can be deleted only before it begins or after it ends.
  
  function deleteQuest(uint256 questId) external onlyAdmin questExists(questId) {
      require(block.timestamp < quests[questId].startTime || block.timestamp > quests[questId].endTime, "Cannot delete while quest is in Progress");
      delete quests[questId];
  }

  //Join quest function
  //lets a player join an existing quest if its in progress i.e (started and not ended) and if not already joined. 
  function joinQuest(uint256 questId) external questExists(questId) questInProgress(questId) {
    require(
      playerQuestStatuses[msg.sender][questId] ==
        playerQuestStatus.NOT_JOINED,
      "Player has already joined/submitted this quest"
    );
    playerQuestStatuses[msg.sender][questId] = playerQuestStatus.JOINED;

    Quest storage thisQuest = quests[questId];
    thisQuest.numberOfPlayers++;
  }

  // Submit quest allows to submit a quest if the player has joined a quest and if the quest is in progress.
  function submitQuest(uint256 questId) external questExists(questId) questInProgress(questId) {
    require(
      playerQuestStatuses[msg.sender][questId] ==
        playerQuestStatus.JOINED,
      "Player must first join the quest"
    );
    playerQuestStatuses[msg.sender][questId] = playerQuestStatus.SUBMITTED;
  }

  // Allows the admin to review a submission of a stackie, if the stackie has submitted the quest.
  // Takes the address of the stackie, questId and a "result" of type enum playerQuestStatus
  // And updates the stackie's(player's) questStatus in playerQuestStatuses Mapping to the given result.

  function reviewSubmissions(
      address stackie, 
      uint256 questId, 
      playerQuestStatus result) 
      external onlyAdmin questExists(questId) {
        require(playerQuestStatuses[stackie][questId] == playerQuestStatus.SUBMITTED, "Quest not submitted by stackie");
        require(uint8(result) >= 3 && uint8(result) <= 5, "Invalid review status");
        if(result == playerQuestStatus.REWARDED){
          playerQuestStatuses[stackie][questId] = playerQuestStatus.REWARDED;
        }
        else if(result == playerQuestStatus.APPROVED) {
            playerQuestStatuses[stackie][questId] = playerQuestStatus.APPROVED;
        }
        else if(result == playerQuestStatus.REJECTED) {
            playerQuestStatuses[stackie][questId] = playerQuestStatus.REJECTED;
        }
  }

  modifier questExists(uint256 questId) {
    require(quests[questId].reward != 0, "Quest does not exist");
    _;
  }

  modifier onlyAdmin(){
    require(msg.sender == admin, "Only the admin can create quests");
    _;
  }
  
  modifier questInProgress(uint questId) {
      require(block.timestamp >= quests[questId].startTime, "Quest has not started");
      require(block.timestamp < quests[questId].endTime, "Quest Has Ended");
      _;
  }

  error RewardCannotBeZero();
  error CannotEditNow();

}
