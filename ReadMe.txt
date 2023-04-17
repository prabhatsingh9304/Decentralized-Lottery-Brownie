brownie networks add development mainnet-fork cmd=ganache-cli host=https://127.0.0.1 fork=https://eth-mainnet.g.alchemy.com/v2/TMUX82aiAZUgHtqi3q8i2KhOllUGlp9F accounts=10 mnemonic=brownie port=8545


Getting Truely Random number in a deterministic system is
actually impossible
In blockchain having a exploitable randomness function is very dangerous


Decentralized-Lottery:
- Created a decentralized Lottery system in which player with minimumUsdEntryFee can participate 
  and all the funds will be transfered to the winner that will be decided randomly
- Efficiently used chainlink pricefeedaggregator for ETH/USD converstion
- Efficiently used chainlink Vrfcoordinator for random number generation and 
  then taken the mod of that random number with lenght arraylist of player participated to
  get random index for winner in arraylist
- Deployed it using brownie framework in sapolia testnet and tested locallay by using Mock
  of contracts (chainlink pricefeedaggregator,chainlink Vrfcoordinator,chanlink linktoken)
- Performed unit test to verfify each and every function and Performed integration test also


