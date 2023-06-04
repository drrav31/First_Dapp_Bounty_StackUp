# StackUp First Dapp Bounty

This is my attempt for the <a href = "https://app.stackup.dev/bounty/build-your-first-dapp"><b>Dapp Bounty</b></a> by StackUp.
The bounty was about implementing atleast 2 or more(if u wish) features given below in a smart contract that we had developed during one of the quests sometime ago.
   - Quest review functionality - allow the admin to reject, approve or reward submissions
   - Edit and delete quests - add functions to allow the admin to edit and delete quests
   - Campaigns - introduce Campaigns, a new data structure and edit the smart contract to accommodate for this change
   - Quest start and end time - add the quest start and end times for each quest struct as well as its corresponding effects e.g. users cannot join a quest that has ended

## My Submission
   
   The smart contract I have implemented for this bounty can be found in the contracts directory as `Stackup.sol`.
   I have tried to implement all of the four features in my smart contract. Here are some key points about the features and the way I have implemented them.
   
   - Initially I chose to implement two features that are 
   #### i) adding quest start and end time to the quest struct
   - The reason I chose these two at first is because, quest start and end time are key information with regards to a quest so adding them was important as they help determine if a stackie can join/submit a quest or not.
   - To implement these, two new fields startTime and endTime were added to the quest struct and the createQuest function was modified to initialize their values.
   - The modified createQuest function takes 2 extra parameters `uint256 startsIn` and `uint256 endsIn`. `startsIn` represents the number of **days** from now till the quest starts.
     `endsIn` represents the number of **days** from now till the quest ends.
   - The startTime is calculated as `currentTimestamp + startIn * 1 days` and endTime is calculated as `currentTimestamp + endsIn * 1 days`. Checkout the function in the smart contract and read the comments to understand more.
   - For testing purpose, you may change the time unit from days to some smaller unit like `minutes` in the formula(see lines 84, 86, 117, 118, 127) in the contract.
   #### ii) Functionalities for editting and deleting quests.
   - The ability to Edit and delete quests is also important as it allows the admin to 
       - edit key info about the quest, say for ex if a quest was created with incorrect information by mistake, the edit function allows the admin to correct the information.
       - The edit function I have implemented in `Stackup.sol`(see function editQuest), takes in new values for a quest along with its id and assigns them to the fields of that quest struct.
       - Before the assignment, there are checks performed to determine which values can be editted and in what way. 
       - What this means is, the function allows modifying values based on when it is called i.e if its called before a quest has started, after a quest has started but has not ended and the          function reverts without making any changes if the edit function is called after a quest has ended as it really doesn't make sense to edit an expired quest.
       - Please read the comments in the code above editQuest function for more info on how exactly the values are modified.
       - The delete functionality allows the admin to delete a quest, it takes quest id as a parameter and checks if the quest exists and if the quest is not in progress i.e has not started yet or has already ended, this check is because deleting an ongoing quest is not desirable. It has to be deleted either before it starts or after it ends.
    
   - Then I also implemented the other two functionalities i.e introducing a new data structure called campaign, that represents a stackup campaign.
   #### Campaign struct
     - This is currently a simple struct that contains the fields
         - title - The campaign's title/name
         - rewardPool - The campaign's total reward pool amount.
         - noOfQuests - Total no.of quests in the campaign.
         - An array of Quest structs - to store info about the quests in the campaign.
  #### Review Submissions
     -  The final functionality also represents the final stage of a quest's journey in Stackup. 
     -  The reviewing stage is where the admin carefully reviews the submissions made by a stackie and assigns one of the 3 possible results[REWARDED, APPROVED, REJECTED] to the submission.
     - In the smart contract, these 3 values are added and stored in an enum `playerQuestStatus`(Read comments above this enum).
     - The reviewSubmission function in the contract takes 3 parameters as input i.e an address of the stackie for whom the admin wants to assign a result, the questId for which the result is being assigned and a result value of type playerQuestStatus representing one of the 3 possible values.
     - The function also checks first if the quest exists and if the player has submitted the quest or not. If yes, then it assigns the given result value to the stackie's address for that questId in the `playerQuestStatuses` mapping.
  
  `Try to Implement all of the functionalities was a great learning experience and quite fun too #UPUPSTACKUP` 
         
 
        
     
