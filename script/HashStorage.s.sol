// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";
import { HashStorage } from "../src/HashStorage.sol";

contract HashStorageScript is Script {
    HashStorage public hashStorage;

    address private OWNER_ADDRESS = vm.envOr("OWNER_ADDRESS", address(0x0));

    function setUp() 
        public
        view 
    {
        vm.assertNotEq(OWNER_ADDRESS, address(0x0), "OWNER_ADDRESS is to null 0x0. Change this in the env variables then re-execute.");
    }

    function run() 
        public 
    {
        vm.startBroadcast(vm.envUint("DEPLOYER_PKEY"));

        hashStorage = new HashStorage(OWNER_ADDRESS);
        console.log(string.concat(unicode"🎉", "Contract has been deployed to address %s"), address(hashStorage));

        vm.stopBroadcast();
    }
}
