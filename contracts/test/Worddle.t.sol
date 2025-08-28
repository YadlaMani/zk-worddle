//SPDX-License-Identifier: MIT
import {Test,console} from "forge-std/Test.sol";
import {Worddle} from "../src/Worddle.sol";
import {HonkVerifier} from "../src/Verifier.sol";
contract WorddleTest is Test {
    HonkVerifier verifier;
    Worddle worddle;
    uint256 constant FIELD_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    bytes32 constant ANSWER = bytes32(uint256(keccak256(abi.encodePacked(bytes32(uint256(keccak256("answer")) % FIELD_MODULUS)))) % FIELD_MODULUS);
    bytes32 constant CORRECT_GUESS = bytes32(uint256(keccak256("answer")) % FIELD_MODULUS);
    bytes proof;
    bytes32[] publicInputs;
    address user=makeAddr("user");
    function setUp()public{
        verifier=new HonkVerifier();
        worddle=new Worddle(verifier);
        worddle.newRound(ANSWER);
        proof=_getProof(CORRECT_GUESS,ANSWER,user);
    }
    function _getProof(bytes32 guess,bytes32 correctAnswer,address _user) internal returns(bytes memory _proof){
           uint256 NUM_ARGS = 6;
        string[] memory inputs = new string[](NUM_ARGS);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/generateProof.ts";
        inputs[3] = vm.toString(guess);
        inputs[4] = vm.toString(correctAnswer);
        inputs[5] = vm.toString(bytes32(uint256(uint160(_user))));

        bytes memory result = vm.ffi(inputs);
        (_proof, /*_publicInputs*/) =
            abi.decode(result, (bytes, bytes32[]));
            return _proof;
    }
    function testCorrectFirstGuess() public{
        vm.prank(user);
        worddle.makeGuess(proof);
        vm.assertEq(worddle.s_winnerWins(user),1);
        vm.assertEq(worddle.balanceOf(user,0),1);
        vm.assertEq(worddle.balanceOf(user,1),0);
        vm.prank(user);
        vm.expectRevert();
        worddle.makeGuess(proof);
    }
    function testStartNewRound() public{
        //started a round in the setup
        vm.prank(user);
        worddle.makeGuess(proof);
        //make a winner and pass the time
        vm.warp(worddle.MIN_DURATION()+1);
        worddle.newRound(bytes32(uint256(keccak256(abi.encodePacked(bytes32(uint256(keccak256("abcdefghi")) % FIELD_MODULUS)))) % FIELD_MODULUS));
        // validate the state has reset
        vm.assertEq(worddle.getCurrentRoundWorddle(), bytes32(uint256(keccak256(abi.encodePacked(bytes32(uint256(keccak256("abcdefghi")) % FIELD_MODULUS)))) % FIELD_MODULUS));
        vm.assertEq(worddle.getCurrentRoundStatus(), address(0));
        vm.assertEq(worddle.s_currentRound(), 2);

        
    }
    function testIncorrectGuessFails() public{
        bytes32 INCORRECT_ANSWER = bytes32(uint256(keccak256(abi.encodePacked(bytes32(uint256(keccak256("outnumber")) % FIELD_MODULUS)))) % FIELD_MODULUS);
        bytes32 INCORRECT_GUESS = bytes32(uint256(keccak256("outnumber")) % FIELD_MODULUS);
        bytes memory incorrectProof = _getProof(INCORRECT_GUESS, INCORRECT_ANSWER, user);
        vm.prank(user);
        vm.expectRevert();
        worddle.makeGuess(incorrectProof);

    }
    
}