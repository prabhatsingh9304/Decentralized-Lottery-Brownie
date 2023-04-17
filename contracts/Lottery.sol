// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

//For Price Feed
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

//For Only Admin to start lottery
import "@openzeppelin/contracts/access/Ownable.sol";

/*Verifiably randomized function:-
It has an onchain contract that check the response of a
chain-link node to make sure the number is truely random using
crytography it's able to check a numbrer of the parameters
that the chainlink vrf started and ended with to make sure
it's truely random*/

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;

    //For Entry fee in USD
    AggregatorV3Interface internal ethUsdPriceFeed;


    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);



    constructor(
        //Can be taken from chainlink pricefeed for ethToUSD
        address _priceFeedAddress, 
        /*contract address that's been deployed on chain that's going to verify 
        that the return of chainlink node is truely randmom*/
        address _vrfCoordinator,
        //link token as a payment for the services   
        address _link, 
        //fee? how much link we are going to pay to the node
        uint256 _fee,
        //keyhash identifiy the chainlink node we going to use
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 10 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        // $50 minimum
        //if lottery_state == LOTTERY_STATE.OPEN not true return error
        require(lottery_state == LOTTERY_STATE.OPEN);

        //if msg.value >= getEntranceFee() not true return error message "Not enough ETH!"
        require(msg.value >= getEntranceFee(), "Not enough ETH!");

        //store player address in players array
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        // USD Entry Fee = $10, 1 ETH = $2,000
        // 1$ = (50/2,000) ETH
        // ETH Entry Fee= 50 * 10e18 / 2000 because solidity don't deal with decimals
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        //https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number/
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;

        //requestedRandomness function inherited from Vrfconsumerbase
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    //Chainlink node is calling Vrfcoordinator and Vrf coordinator is calling fulfillRandomness function
    //internal function so that only Vrfcoordinator can call this function
    //override the original declaration of fullfillRandomness function in Vrfcoordinatorbase.sol 
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        // Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
