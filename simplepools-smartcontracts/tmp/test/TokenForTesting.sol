pragma solidity ^0.8.17;
// SPDX-License-Identifier: MIT

contract TokenForTesting {
    string public name     = "TokenForTesting";
    string public symbol   = "TokenForTesting";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    uint256 _totalSupply = 0;

    fallback() external payable {
        this.deposit();
    }

    receive() external payable {
        this.deposit();
    }

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function myBalance() external view returns (uint) {
        return balanceOf[msg.sender];
    }

    function mint(address to, uint value) external {
      balanceOf[to] += value;
      _totalSupply += value;
      emit Deposit(to, value);
      emit Transfer(address(0), to, value);
    }

    function mintToMe(uint value) external {
        this.mint(msg.sender, value);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function approveAll(address guy) public returns (bool) {
        return approve(guy, 2**256 - 1);
    }

    function transfer(address dst, uint wad) 
            public returns (bool) 
    {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) 
            public returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}
