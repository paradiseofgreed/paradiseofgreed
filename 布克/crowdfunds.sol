pragma solidity ^0.4.7;
library SafeMath {
	function add(uint a, uint b) internal pure returns (uint) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
	function sub(uint a, uint b) internal pure returns (uint) {
		assert(b <= a);
		return a - b;
	}
	function mul(uint a, uint b) internal pure returns (uint) {
		if (a == 0) {
			return 0;
		}
		uint c = a * b;
		assert(c / a == b);
		return c;
	}
	function div(uint a, uint b) internal pure returns (uint) {
		uint c = a / b;
		return c;
	}
}
interface token {
	function transfer(address receiver, uint amount) external;
	function decimals() external returns(uint);
}
contract CrowdFunds {
    using SafeMath for uint;
    address public beneficiary;
    uint public targetFunds;
    uint public deadline;
    uint public price;
    token public tokenReward;
    bool public reachedGoal = false;
    bool public isCrowdClosed = false;
    uint public fundsRaisedTotal = 0;
    mapping(address => uint) public balanceOf;
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address investor, uint amount, bool isContribution);
    event InvestorWithdraw(address investor, uint amount, bool success); 
    event BeneficiaryWithdraw(address beneficiary, uint amount, bool success); 
    modifier afterDeadline {
        require(now > deadline);
        _;
    }
    modifier beforeDeadline {
        require(now <= deadline);
        _;
    }
    constructor(
        address _beneficiary,
        uint _targetFunds,
        uint _duration,
        uint _price,
        address _tokenAddress
    ) public {
        beneficiary = _beneficiary;
        targetFunds = _targetFunds * 1 ether;
        deadline = now + _duration * 1 minutes;
        price = _price * 1 finney;
        tokenReward = token(_tokenAddress);
    }
    function () payable beforeDeadline public {
        require(!isCrowdClosed); 
        require(!reachedGoal);
        uint amount = msg.value; 
        uint tokenDecimal = tokenReward.decimals();
        uint tokenNum = (amount / price) * 10 ** tokenDecimal;
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        fundsRaisedTotal = fundsRaisedTotal.add(amount);
        if (fundsRaisedTotal >= targetFunds) {
            reachedGoal = true;
            isCrowdClosed = true;
            emit GoalReached(beneficiary, fundsRaisedTotal);
        }
        tokenReward.transfer(msg.sender, tokenNum);
        emit FundTransfer(msg.sender, amount, true);
    }
    function withdraw() afterDeadline public {
            if (msg.sender == beneficiary && beneficiary.send(fundsRaisedTotal)) {
                emit BeneficiaryWithdraw(beneficiary, fundsRaisedTotal, true);
            } else {
                emit BeneficiaryWithdraw(msg.sender, fundsRaisedTotal, false);
            }
        }
}
