// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

error NotEnough();

contract DepositToFund {
    using PriceConverter for uint256;

    uint256 public minimumUsd = 1000e18;

    address[] public depositors;

    struct DepositInfo {
        address depositor;
        uint256 timestamp;
        uint256 amount;
    }

    struct WithdrawalInfo {
        address withdrawer;
        uint256 timestamp;
        uint256 amount;
    }

    mapping(uint256 => DepositInfo) public deposits;
    uint256 public depositCount;

    mapping(uint256 => WithdrawalInfo) public withdrawals;
    uint256 public withdrawalCount;

    mapping(address => uint256) public addressToBalance;

    mapping(address => uint256) public addressToAllowance;

    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    function deposit() public payable {
        // require(msg.value.getConversionRate() >= minimumUsd, "Didn't send enought ETH");
        depositors.push(msg.sender);
        addressToBalance[msg.sender] += msg.value;
        deposits[depositCount] = DepositInfo(msg.sender, block.timestamp, msg.value);
        depositCount++;
    }

    function silentDeposit() public payable {
        // Function to deposit to the contract without being recorded as contributor
    }

    function withdrawManager(uint256 _withdrawalAmount) public onlyOwner {
        require(address(this).balance >= _withdrawalAmount, "Not enough ETH in contract");
        withdrawToMsgSender(_withdrawalAmount);
    }

    function withdrawUser(uint256 _withdrawalAmount) public onlyIfEnoughInContract(_withdrawalAmount) {
        require(addressToAllowance[msg.sender] >= _withdrawalAmount, "Not enough allowance");
        addressToBalance[msg.sender] -= _withdrawalAmount;
        withdrawals[withdrawalCount] = WithdrawalInfo(msg.sender, block.timestamp, _withdrawalAmount);
        withdrawalCount++;
        withdrawToMsgSender(_withdrawalAmount);
    }

    function modifyAllowance(uint256 allowance, address user) public onlyOwner {
        addressToAllowance[user] = allowance;
    }

    function withdrawToMsgSender(uint _withdrawalAmount) private {
        (bool callSuccess, ) = payable(msg.sender).call{value: _withdrawalAmount}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        if(msg.sender != i_owner) { revert NotOwner(); }
        _;
    }

    modifier onlyIfEnoughInContract(uint256 _amount) {
        if(_amount <= address(this).balance) { revert NotEnough(); }
        _;
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }

}
