//SPDX-License-Identifier:MIT
pragma solidity >=0.8.21;

//imports
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IVerifier} from "./Verifier.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
contract Worddle is ERC1155,Ownable{
    IVerifier public s_verifier;
    uint256 public s_currentRound;
    //current round winner so we only mint one nft for the first winner
    address public s_currentRoundWinner;
    //Mapping to track number of wins for each address
    mapping(address=>uint256) public s_winnerWins;
    //Last correct guess by a user
    mapping(address=>uint256)public s_lastCorrectGuessRound;
    bytes32 public s_answer;//hash
    uint256 public MIN_DURATION=10800;//Minium duration before starting new round
    uint256 public s_roundStartTime;
    constructor(IVerifier _verifier)ERC1155("https://ipfs.io/ipfs/QmZcH4YvBVVRJtdn4RdbaqgspFU8gH6P9vomDpBVpAL3u4/{id}.json"){
        s_verifier=_verifier;
    }
    //events
    event Worddle_RoundStarted();
    event Worddle_VerifierUpdated(IVerifier newVerifier);
    event Worddle_ProofSucceded(bool success);
    event Worddle_NFTMinted(address indexed player, uint256 indexed tokenId);
    //errors

    error Worddle_MINTimeNotPassed(uint256 minTime,uint256 actualTime);
    error Worddle_CurrentRoundHasNoWinner();
    error Worddle_RoundNotStarted();
    error Worddle_AlreadyAnsweredCorrectly();
    error Worddle_IncorrectGuess();
    //onlyOwner start the new round
    function newRound(bytes32 _correctAnswer) external onlyOwner{
        if(s_roundStartTime==0){
            s_roundStartTime=block.timestamp;
            s_answer=_correctAnswer;
        }else{
            if(block.timestamp<s_roundStartTime+MIN_DURATION){
                revert Worddle_MINTimeNotPassed(MIN_DURATION,block.timestamp-s_roundStartTime);

            }
            if(s_currentRoundWinner==address(0)){
                revert Worddle_CurrentRoundHasNoWinner();
            }
            s_answer=_correctAnswer;
            s_currentRoundWinner=address(0);
        }
        s_currentRound++;
        emit Worddle_RoundStarted();
    }
    //mint nft for the first correct guess
    function makeGuess(bytes calldata proof) external returns (bool){
        if(s_currentRound==0){
            revert Worddle_RoundNotStarted();
        }
        bytes32[] memory inputs=new bytes32[](2);
        inputs[0]=s_answer;
        inputs[1]=bytes32(uint256(uint160(msg.sender)));
        if(s_lastCorrectGuessRound[msg.sender]==s_currentRound){
            revert Worddle_AlreadyAnsweredCorrectly();
        }
        bool proofRes=s_verifier.verify(proof,inputs);
        emit Worddle_ProofSucceded(proofRes);
        if(!proofRes){
            revert Worddle_IncorrectGuess();
        }
        s_lastCorrectGuessRound[msg.sender]=s_currentRound;
        if(s_currentRoundWinner==address(0)){
            s_currentRoundWinner=msg.sender;
            s_winnerWins[msg.sender]++;
            _mint(msg.sender,0,1,"");
            emit Worddle_NFTMinted(msg.sender,0);
        }
        else{
            _mint(msg.sender,1,1,"");
            emit Worddle_NFTMinted(msg.sender,1);
        }
        return proofRes;
    }

    

    function setVerifier(IVerifier _verifier) external onlyOwner{
        s_verifier=_verifier;
        emit Worddle_VerifierUpdated(_verifier);
    }
    function getCurrentRoundStatus() external view returns(address){
        return s_currentRoundWinner;
    }
    function getCurrentRoundWorddle() external view onlyOwner returns(bytes32){
        return s_answer;
    }
    
}
