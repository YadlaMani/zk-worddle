// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVerifier} from "./Verifier.sol";
contract Worddle is ERC1155, Ownable{
    IVerifier public s_verifier;
    bytes32 public s_answer;
    uint256 public constant MIN_DURATION=10800; //3 hours
    uint256 public s_roundStartTime;
    address public s_currentRoundWinner;
    uint256 public s_currentRound;
    mapping(address=>uint256) public s_lastCorrectGuessRound;
    //Events
    event Worddle_VerifierUpdated(IVerifier  verifier);
    event Worddle_NewRound(bytes32 answer);
    event Worddle_Winner(address indexed winner, uint256 indexed round);
    event Worddle_Runnerup(address indexed runnerup, uint256 indexed round);
    //Error
    error Worddle_MinTimeNotPassed(uint256 minDuration, uint256 timeLeft);
    error Worddle_NoRoundWinner();
    error Worddle_RoundNotStarted();
    error Worddle_AlreadyGuessedCorrectly();
    error Worddle_InvalidProof();

    constructor(IVerifier _verifier) ERC1155("https://ipfs.io/ipfs/QmZcH4YvBVVRJtdn4RdbaqgspFU8gH6P9vomDpBVpAL3u4/{id}.json"){ 
        s_verifier = _verifier;
    }
    //create  new round
    function newRound(bytes32 _answer) external onlyOwner{
        if(s_roundStartTime==0){
            s_roundStartTime=block.timestamp;
            s_answer=_answer;
        }else{
            if(block.timestamp<s_roundStartTime+MIN_DURATION){
               revert Worddle_MinTimeNotPassed(MIN_DURATION, s_roundStartTime+MIN_DURATION-block.timestamp);
            }
            if(s_currentRoundWinner==address(0)){
                revert Worddle_NoRoundWinner();
            }
            //Reset the round
            s_roundStartTime=block.timestamp;
            s_answer=_answer;
            s_currentRoundWinner=address(0);

        }
        s_currentRound++;
       

        emit Worddle_NewRound(_answer);
    }


    //allow users to submit a guess
    function makeGuess(bytes memory proof) external returns(bool){
        //check whether the first round has been started
        if(s_currentRound==0){
            revert Worddle_RoundNotStarted();
        }
        //check if the user has already guessed correctly
        if(s_lastCorrectGuessRound[msg.sender]==s_currentRound){
            revert Worddle_AlreadyGuessedCorrectly();
        }
        //check the proof and verify it with the verifier contract
        bytes32[] memory publicInputs=new bytes32[](1);
        publicInputs[0]=s_answer;
        bool proofResult=s_verifier.verify(proof,publicInputs);
        //revert if incorrect
        if(!proofResult){
            revert Worddle_InvalidProof();
        }
        s_lastCorrectGuessRound[msg.sender]=s_currentRound;

        //if correct,check if they are first ,if they are then mint nft id 0
        if (s_currentRoundWinner==address(0)){
            s_currentRoundWinner=msg.sender;
            _mint(msg.sender,0,1,"");
            emit Worddle_Winner(msg.sender,s_currentRound);
        }
        //if correct not first, then mint id with 1
        else{
            _mint(msg.sender,1,1,"");
            emit Worddle_Runnerup(msg.sender,s_currentRound);
        }
        return true;

    }

    //set a new verifier
    function setVerifier(IVerifier _verifier) external onlyOwner {
        s_verifier = _verifier;
        emit Worddle_VerifierUpdated(_verifier);
    }

}