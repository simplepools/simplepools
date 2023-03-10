// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract USDTest {
    string public name     = "USDTest";
    string public symbol   = "USDTest";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    uint private _total = 0;

    fallback() external payable {
        this.deposit();
    }

    receive() external payable {
        this.deposit();
    }

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        _total += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function mint(address to, uint value) external {
      balanceOf[to] += value;
      _total += value;
      emit Deposit(to, value);
      emit Transfer(address(0), to, value);
    }

    function mintToMe(uint value) external {
        this.mint(msg.sender, value);
    }

    function withdraw(uint wad) public payable {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        _total -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function myBalance() external view returns (uint) {
        return balanceOf[msg.sender];
    }

    function totalSupply() public view returns (uint) {
        return _total;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function approveAll(address guy) public returns (bool) {
        return approve(guy, 2**256 - 1);
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
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