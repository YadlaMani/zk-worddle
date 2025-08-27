// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {Test,console} from "forge-std/Test.sol";
import {Worddle} from "../src/Worddle.sol";
import {HonkVerifier} from "../src/Verifier.sol";

contract WorddleTest is Test{
    HonkVerifier public verifier;
    Worddle public worddle;
    uint256 constant FIELD_MODULUS=21888242871839275222246405745257275088548364400416034343698204186575808495617;
    bytes32 ANSWER=bytes32(uint256(keccak256("test"))%FIELD_MODULUS);

    //start the round
    //make a guess
    function setUp() public{
         //deploy the verifier
        verifier = new HonkVerifier();
        //deploy the worddle contract
        worddle = new Worddle(verifier);
        //create the answer
        worddle.newRound(ANSWER);
        }
    //1.Test someone recieves NFT 0 if they guess correctly first
    function testCorrectFirstGuess() public{

    }
    //2.Test someone recieves NFT 1 if they guess correctly second
    //3.Test we can start a new round
}