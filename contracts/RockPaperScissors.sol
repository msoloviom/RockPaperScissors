pragma solidity ^0.4.24;
contract RockPaperScissors {
    
    mapping (uint => Game) public games;
    mapping (string => mapping(string => int8)) rules;

    struct Game {
        uint depositAmount;
        bool locked;
        uint deadline;
        
        address player1;
        bytes32 hashedMove1;
        string move1;
        address player2;
        bytes32 hashedMove2;
        string move2;
    }
    
    event LogWithdrawal(address recipient, uint reward);
    
    constructor() public {
        rules["rock"]["rock"] = 0;
        rules["rock"]["paper"] = 2;
        rules["rock"]["scissors"] = 1;
        rules["paper"]["rock"] = 1;
        rules["paper"]["paper"] = 0;
        rules["paper"]["scissors"] = 2;
        rules["scissors"]["rock"] = 2;
        rules["scissors"]["paper"] = 1;
        rules["scissors"]["scissors"] = 0;
    }

	function registerToGame(uint gameId, bytes32 hashedMove) public payable returns(bool seccess) {
        Game storage game = games[gameId];
        require(!game.locked, "Requested game is already in process.");
        require(msg.value >= game.depositAmount, "Not enouph funds to start the game");
    
        if(game.player1 == 0) {
            game.player1 = msg.sender;
            game.hashedMove1 = hashedMove;
            game.move1 = "";
        } else {
            game.player2 = msg.sender;
            game.hashedMove2 = hashedMove;
            game.move2 = "";
        }
        
        game.depositAmount += msg.value;
        game.deadline = block.timestamp;
        if (game.player1 != 0 && game.player2 != 0) game.locked = true;
        return true;
    }
    
    function getCurrentGameState(uint gameId) public view returns
    (address player1, bytes32 hashedMove1, string move1,  address player2, bytes32 hashedMove2, string move2, bool lock, uint deadline, uint _now) {
        Game storage game = games[gameId];
        return (
            game.player1, game.hashedMove1, game.move1,  
            game.player2, game.hashedMove2, game.move2,
            game.locked, game.deadline, now
            );
    }
    
    function openMoveDone(uint gameId, string secretPassphrase) public {
        Game storage game = games[gameId];
        require(game.locked, "Requested game is waiting for all player to be joined.");
        //require(game.deadline== block.timestamp, "Wrong timing - open move");
        
        address player1 = game.player1;
        address player2 = game.player2;
        
        if(msg.sender == player1) {
            game.move1 = identifyMove(gameId, game.hashedMove1, secretPassphrase);
        } else if (msg.sender == player2) {
            game.move2 = identifyMove(gameId, game.hashedMove2, secretPassphrase);
        } else {
            revert("To play you need to be registered to current game.");
        }
    }
    
    function finishGame(uint gameId) public {
        Game storage game = games[gameId];
        require(game.locked, "Requested game is not finished.");
        require(game.depositAmount > 0, "Game deposit is empty");
        //require(msg.sender == game.player1 || msg.sender == game.player2, "You must be one of the players");
    
        int8 winnerIndex = rules[game.move1][game.move2];
        if (msg.sender == game.player1) {
            game.player1 = 0;
            game.move1 = "";
            game.hashedMove1 = 0x0;
            if (game.depositAmount > 0) {
                if (winnerIndex == 1) msg.sender.transfer(game.depositAmount);
                if (winnerIndex == 0) msg.sender.transfer(game.depositAmount/2);
            }
            
        } else if (msg.sender == game.player2) {
            game.player2 = 0;
            game.move2 = "";
            game.hashedMove2 = 0x0;
            if (game.depositAmount > 0) {
                if (winnerIndex == 2) msg.sender.transfer(game.depositAmount);
	if (winnerIndex == 0) msg.sender.transfer(game.depositAmount/2);
            }
        } else {
            revert("You must be one of the players to get reward");
        }
        
        if (game.player1 == 0 && game.player2 == 0) game.locked = false;
    }
    
    function identifyMove(uint gameId, bytes32 hashedMove, string secretPassphrase) internal returns (string move) {
        Game storage game = games[gameId];
        require(game.locked, "Requested game does not exist or not finished is waiting for all player to be joined. Please choose another game ID");
        //require(game.deadline == block.timestamp);
        
        if (hashedMove == hash("rock", secretPassphrase)) { return "rock"; }
        else if (hashedMove == hash("paper", secretPassphrase)) { return "paper";}
        else if (hashedMove == hash("scissors", secretPassphrase)) {return "scissors";}
        else revert("Cannot identify the move. Check input data");
    
    }
    
    function hash(string move, string secretPassphrase) internal returns(bytes32 digest) {
        return keccak256(abi.encodePacked(move, msg.sender, secretPassphrase));
    }
}
