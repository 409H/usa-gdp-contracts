# USA-GDP-Contracts (HashStorage)

On [Ethereum Mainnet Block 23239778](https://etherscan.io/tx/0xb25596f09691e4222ef80acd40e70a9f6ca6ba5a3b2dad31c086c835ced3da5f), the [U.S. Commerce Dept. submitted the GDP to the blockchain](https://x.com/BanklessHQ/status/1961076696364290402). 

However, they did this ineffectively for the following reasons:

* The contract holds no write methods, so next quarter they will need to create and deploy another contract to submit data
* There's no way (other than viewing the verified contract code) to find the relevant PDF that they committed the hash for

This smart contract (located in `./src/HashStorage.sol`) provides the following updates to their current setup:

* A single contract to hold ALL future quarter updates
* The U.S. Commerce Dept. can now submit the location of the PDF so we can independently verify the committed hash
* We can grab the GDP details (`fileHash`, `fileLoc`, `gdp`) for a specific time period (ie: `2025Q2`) with a dedicated read method
* The contract has events, so we can subscribe and listen for updates
* The contract has a small ownership model, so they can restrict writing to a specific address
* The contract owner can change by calling `transferOwnership()`

But that's not all... the contract is tested (located in `./test/HashStorage.t.sol`)!

Ensure you have [`Foundry`](https://getfoundry.sh/) installed.

## Testing

The tests are located in `./test/HashStorage.t.sol`, and each test case has its own documentation, as well as the command to run the test individually.

```bash
$ forge test
```

## Deployment

```bash
$ cp .env.example .env
```

Fill in the details `OWNER_ADDRESS` and `DEPLOYER_PKEY`.

Then run `forge script HashStorageScript` to run it.

```bash
$ forge script HashStorageScript --rpc-url https://holesky.gateway.tenderly.co --broadcast  # Ethereum Holesky (Testnet)

$ forge script HashStorageScript --rpc-url https://eth.llamarpc.com --broadcast  # Ethereum Mainnet
```

---

*These contracts are not audited. Use at your own risk.*