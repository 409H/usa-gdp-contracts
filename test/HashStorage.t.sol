// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {HashStorage} from "../src/HashStorage.sol";

contract HashStorageTest is Test {
    HashStorage public hashStorage;

    address deployer = vm.addr(1);
    address owner = vm.addr(2);
    address unknownActor = vm.addr(3);

    mapping(string => HashStorage.periodDetails) public testData;

    function setUp() public {
        hashStorage = new HashStorage(owner);


        vm.label(deployer, "DEPLOYER");
        vm.label(owner, "OWNER");
        vm.label(unknownActor, "UNKNOWN_ACTOR");
        vm.label(address(hashStorage), "CONTRACT: HashStorage");
    }

    /**
     * Tests to ensure the "owner" property of the HashStorage contract
     * is set correctly in the constructor.
     * 
     * forge test --match-contract HashStorageTest --match-test test_ownerIsSetCorrectly -vvvv
     */
    function test_ownerIsSetCorrectlyOnDeployment()
        public
        view
    {
        address _owner = hashStorage.owner();
        assertEq(_owner, owner, "Owner of HashStorage is not set correctly");
    }

    /**
     * Tests to ensure the "owner" can change the contract ownership. Also
     * testing to ensure the event "OwnershipTransferred()" is emitted on
     * the transferOwnership() call.
     * 
     * forge test --match-contract HashStorageTest --match-test test_ownerCanChangeOwner -vvvv
     */
    function test_ownerCanChangeOwner()
        public
    {
        address currentOwner = hashStorage.owner();
        address newOwner = vm.addr(22);

        vm.expectEmit(address(hashStorage));
        emit HashStorage.OwnershipTransferred(currentOwner, newOwner);

        vm.prank(owner);
        hashStorage.transferOwnership(newOwner);

        assertEq(hashStorage.owner(), newOwner, "Owner did not change via transferOwnership()");
    }

    /**
     * Tests to ensure an unknown actor (ie: not "owner") cannot change the contract 
     * ownership, by ensuring the call transferOwnership() reverts with the correct
     * error message "NoAuthorisation".
     * 
     * forge test --match-contract HashStorageTest --match-test test_ownerCannotBeChangedByUnknownActor -vvvv
     */
    function test_ownerCannotBeChangedByUnknownActor()
        public
    {
        address newOwner = vm.addr(22);
        
        vm.expectRevert(HashStorage.NoAuthorisation.selector);

        vm.prank(unknownActor);
        hashStorage.transferOwnership(newOwner);
    }

    /**
     * Tests to ensure an unknown actor (ie: not "owner") cannot commit data, and
     * if they try it reverts with message "NoAuthorization".
     * 
     * forge test --match-contract HashStorageTest --match-test test_commitAsUnknownActor -vvvv
     */
    function test_commitAsUnknownActor()
        public
    {
        testData["2025Q2"] = HashStorage.periodDetails(
            keccak256("test data q2"),
            "https://www.bea.gov/sites/default/files/2025-08/gdp2q25-2nd.pdf",
            33
        );

        vm.expectRevert(HashStorage.NoAuthorisation.selector);

        vm.prank(unknownActor);
        hashStorage.commit("2025Q2", testData["2025Q2"].pdfHash, testData["2025Q2"].pdfLocation, testData["2025Q2"].gdp);
    }

    /**
     * Tests to ensure you cannot commit with an unknown time period. Time periods
     * should be formatted as "YYYYQD" (year-year-year-Q-[1-4], ie: 2025Q2). If
     * an incorrect time period is given, then revert with error message "InvalidTimePeriod".
     * 
     * forge test --match-contract HashStorageTest --match-test test_commitWithIncorrectTimePeriod -vvvv
     */
    function test_commitWithIncorrectTimePeriod()
        public
    {
        string[5] memory testTimePeriods = [
            "25Q1",     // Incorrect year format, should be YYYY
            "2025Q5",   // Incorrect quarter, only 4 quarters in the year
            "2025M2",   // Incorrect quarter delimeter, should be "Q"
            "test",     // Incorrect time period
            "0000Q0"    // Incorrect time period and quarter
        ];

        bytes32 dummyHash = keccak256("testdata");
        string memory dummyLocation = "https://www.bea.gov/sites/default/files/2025-08/gdp2q25-2nd.pdf";
        uint256 dummyGdp = 33;

        vm.startPrank(owner);
        for(uint256 i=0; i<testTimePeriods.length; i++) {
            vm.expectRevert(HashStorage.InvalidTimePeriod.selector);
            hashStorage.commit(
                testTimePeriods[i],
                dummyHash,
                dummyLocation,
                dummyGdp
            );
        }
        vm.stopPrank();
    }

    /**
     * Tests to ensure that the owner can commit data using commit() and the
     * data returned for each new entry is correct.
     * 
     * forge test --match-contract HashStorageTest --match-test test_commitDataAndTestRead -vvvv
     */
    function test_commitDataAndTestRead()
        public
    {
        testData["2025Q2"] = HashStorage.periodDetails(
            keccak256("test data q2"),
            "https://www.bea.gov/sites/default/files/2025-08/gdp2q25-2nd.pdf",
            33
        );
        testData["2025Q3"] = HashStorage.periodDetails(
            keccak256("test data q3"),
            "https://www.bea.gov/sites/default/files/2025-08/gdp3q25-2nd.pdf",
            20
        );

        // Commit multiple quarter details
        vm.startPrank(owner);
        hashStorage.commit("2025Q2", testData["2025Q2"].pdfHash, testData["2025Q2"].pdfLocation, testData["2025Q2"].gdp);
        hashStorage.commit("2025Q3", testData["2025Q3"].pdfHash, testData["2025Q3"].pdfLocation, testData["2025Q3"].gdp);
        vm.stopPrank();

        string[2] memory testTimePeriods = [
            "2025Q2",
            "2025Q3"
        ];

        // Now read the data for the committed time periods and validate data return
       for(uint256 i=0; i<testTimePeriods.length; i++) {
            HashStorage.periodDetails memory data = hashStorage.read(testTimePeriods[i]);
            assertEq(data.pdfHash, testData[testTimePeriods[i]].pdfHash, "File Hash is incorrect");
            assertEq(data.pdfLocation, testData[testTimePeriods[i]].pdfLocation, "File location is incorrect");
            assertEq(data.gdp, testData[testTimePeriods[i]].gdp, "Gdp is incorrect");
        }
    }

    /**
     * Tests to ensure that reading data for a time period that has not been committed
     * yet reverts with error message "NoData".
     * 
     * forge test --match-contract HashStorageTest --match-test test_readDataNotCommitted -vvvv
     */
    function test_readDataNotCommitted()
        public
    {
        vm.expectRevert(HashStorage.NoData.selector);

        hashStorage.read("2099Q4");
    }
}
