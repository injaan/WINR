pragma solidity ^0.4.8;

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}


contract WINR is SafeMath {
    string public name;
    string public symbol;
    int8 public decimals = 18;
    uint256 public totalSupply;
    address public ownerCandidate;
	address public owner;
	uint256 public winrPrice; //token price by ETH
	bool public buyable;
	uint public minimumBuyAmount;
	
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => string) public contacts;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Disapproval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Buy(address indexed buyer, uint tokenAmount);
    event Withdraw(address indexed owner, uint amount);

    constructor() public {
        owner = msg.sender;
        totalSupply = (300000000*(10**uint(decimals)));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(this), owner, totalSupply);
        name = "WINR Token";
        symbol = "WINR";
        winrPrice = 1000000000000;
        buyable = true;
        minimumBuyAmount = 2000;
    }
    
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _candidate) public ownerOnly returns (bool success) {
        require(owner != _candidate);
        ownerCandidate = _candidate;
        return true;
    }
    
    function acceptOwnership() public returns (bool success) {
        require (msg.sender != 0x0);
        require(ownerCandidate == msg.sender);
        owner = ownerCandidate;
        ownerCandidate = address(0);
        return true;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value); //
        require(balanceOf[_to] + _value > balanceOf[_to]); //preventing owerflow
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        if (_to == address(this)){
            balanceOf[owner] = SafeMath.safeAdd(balanceOf[owner], _value);  //herev contractiin hayagruu ilgeesen bol owner-n balance deer nemne
            emit Transfer(msg.sender, owner, _value);
        } else {
            balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
            emit Transfer(msg.sender, _to, _value);
        }
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != 0x0);
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function disApprove(address _spender, uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(allowance[msg.sender][_spender] >= _value);
        allowance[msg.sender][_spender] = SafeMath.safeSub(allowance[msg.sender][_spender], _value);
        emit Disapproval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function updateContact(string _contact) public returns (bool success) {
        require(balanceOf[msg.sender] > 0);
        require(bytes(_contact).length > 0);
        contacts[msg.sender] = _contact;
        return true;
    }
    
    function updateWinrPrice(uint256 _price) public ownerOnly returns (bool success) {
        require(_price > 0);
        winrPrice = _price;
        return true;
    }
    
    function updateMinimumBuyAmount(uint256 _amount) public ownerOnly returns (bool success) {
        require(_amount > 0);
        minimumBuyAmount = _amount;
        return true;
    }
    
    function setBuyable(bool option) public ownerOnly returns (bool success){
        buyable = option;
        return true;
    }
    
    function buy(uint256 _buyAmount) public payable returns (bool success) {
        require(buyable);
        require(_buyAmount > 0);
        require(_buyAmount >= minimumBuyAmount);
        require(msg.value >= (SafeMath.safeMul(winrPrice,_buyAmount)));
        uint256 winrAmount = (SafeMath.safeDiv(msg.value,winrPrice)*(10**18));
        require((_buyAmount*(10**18)) == winrAmount);
        require(balanceOf[owner] >= winrAmount);
        balanceOf[owner] = SafeMath.safeSub(balanceOf[owner], winrAmount);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender],winrAmount);
        emit Transfer(owner, msg.sender, winrAmount);
        emit Buy(msg.sender, winrAmount);
        return true;
    }
    
    
    function withdrawEth(uint256 _value) public ownerOnly returns (bool success){
        require(_value > 0);
        require(address(this).balance >= _value);
        owner.transfer(_value);
        emit Withdraw(owner, _value);
        return true;
    }
    
}