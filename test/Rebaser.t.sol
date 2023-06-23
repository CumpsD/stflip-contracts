// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MainMigration.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract RebaserTest is MainMigration {
   
    function setUp() public {
        MainMigration migration = new MainMigration();
    }

    function _minRewardsToFail(uint256 elapsedTime) internal returns (uint256) {
        return wrappedRebaserProxy.aprThresholdBps() * stflip.totalSupply() / 10000 * (elapsedTime * 10**18 / 365 days) / 10**18; 
    }

    function _minSlashToFail() internal returns (uint256) {
        return stflip.totalSupply() * wrappedRebaserProxy.slashThresholdBps() / 10000;
    }

    function _relativelyEq(uint256 num1, uint256 num2) internal returns (bool) {
        return (num1 > num2) ? (num1 - num2 <= 10**10) : (num2 - num1 <= 10**10);
    }

    function test_RebaseInterval() public {
        vm.warp(block.timestamp + wrappedRebaserProxy.rebaseInterval() - 1);
        vm.prank(manager);
        vm.expectRevert("Rebaser: rebase too soon");
        wrappedRebaserProxy.rebase(1, 1, true);
    }
    
    function testFuzz_ExcessivePositiveRebase(uint256 elapsedTime_, uint256 rewards_, uint256 startSupply_, bool takeFee) public {
        uint256 startSupply = bound(startSupply_, 10**18, 30_000_000*10**18);
    
        vm.startPrank(owner);
            flip.mint(owner, startSupply);
            wrappedMinterProxy.mint(owner,startSupply);
        vm.stopPrank();

        uint256 elapsedTime = bound(elapsedTime_, wrappedRebaserProxy.rebaseInterval() , 365 * 60 * 24 * 24);
        uint256 minRewardsToFail = _minRewardsToFail(elapsedTime);
        uint256 rewards = bound(rewards_, minRewardsToFail + 100, 2**100 - 1 );
        
        vm.warp(block.timestamp + elapsedTime);

        vm.startPrank(owner);
            flip.mint(address(output), rewards);
            vm.expectRevert("Rebaser: apr too high");
            wrappedRebaserProxy.rebase(1, 0, takeFee);
        vm.stopPrank();
    }

    function testFuzz_ExcessiveNegativeRebase(uint256 slashAmount_, uint256 startSupply_) public {

        uint256 startSupply = bound(startSupply_, 10**18, 30_000_000*10**18);
        vm.startPrank(owner);
        flip.mint(owner, startSupply);
        wrappedMinterProxy.mint(owner,startSupply);
        vm.stopPrank(); 

        uint256 minSlashToFail = wrappedRebaserProxy.slashThresholdBps() * stflip.totalSupply() / 10000;
        uint256 slashAmount = bound(slashAmount_, minSlashToFail, stflip.totalSupply() * 9 / 10);
        
        vm.prank(address(wrappedOutputProxy));
            flip.transfer(owner, slashAmount);

        vm.warp(block.timestamp + wrappedRebaserProxy.rebaseInterval());

        vm.prank(owner);
            vm.expectRevert("Rebaser: supply decrease too high");
            wrappedRebaserProxy.rebase(1,0,true);
    }

    function testFuzz_PendingFee(uint256 startSupply_, uint256 rewards_, uint256 elapsedTime_,  bool takeFee) public {
        uint256 startSupply = bound(startSupply_, 10**18, 30_000_000*10**18);
        uint256 elapsedTime = bound(elapsedTime_, wrappedRebaserProxy.rebaseInterval(), 365 days);
        uint256 rewards = bound(rewards_, 0, _minRewardsToFail(elapsedTime) * 6 / 10 );

        vm.prank(owner);
        flip.mint(address(output), rewards);

        uint256 initialPendingFee = wrappedRebaserProxy.pendingFee();

        vm.warp(block.timestamp + elapsedTime);
        console.log("rewards", rewards);
    
        vm.prank(owner);
        wrappedRebaserProxy.rebase(1,0,true);

        uint256 difference = wrappedRebaserProxy.pendingFee() - initialPendingFee;
        uint256 expected = rewards * wrappedRebaserProxy.feeBps() / 10000; 

        require (difference == expected || difference + 1 == expected, "testFuzz_PendingFee: expected fee increase != actual");
    }

    function testFuzz_SuccessfulPositiveRebase(uint256 initialMint_, uint256 rewards_, uint256 elapsedTime_) public {
        uint256 initialMint = bound(initialMint_, 10**18, 30_000_000*10**18);
        uint256 initialSupply = stflip.totalSupply();
        uint256 elapsedTime = bound(elapsedTime_, wrappedRebaserProxy.rebaseInterval(), 365 days);
        uint256 rewards = bound(rewards_, 0, _minRewardsToFail(elapsedTime) * 999 / 1000);
        
        vm.warp(block.timestamp + elapsedTime);

        vm.startPrank(owner);
            flip.mint(owner, initialMint);
            wrappedMinterProxy.mint(owner,initialMint);

            flip.mint(address(output), rewards);
            wrappedRebaserProxy.rebase(1,0,false);
        vm.stopPrank();

        uint256 expectedSupply = initialMint + rewards + initialSupply;
        uint256 actualSupply = stflip.totalSupply();

        require( (expectedSupply > actualSupply) ? (expectedSupply - actualSupply <= 10**10) : (actualSupply - expectedSupply <= 10**10), "testFuzz_SuccessfulPositiveRebase: supply increase != expected");
    }

    function testFuzz_SuccessfulNegativeRebase(uint256 startSupply_, uint256 slash_) public {
        uint256 startSupply = bound(startSupply_, 10**18, 30_000_000*10**18);
        uint256 initialSupply = stflip.totalSupply();
        uint256 slash = bound(slash_, 0, _minSlashToFail());
        
        vm.warp(block.timestamp + wrappedRebaserProxy.rebaseInterval());

        vm.startPrank(owner);
            flip.mint(owner, startSupply);
            wrappedMinterProxy.mint(owner,startSupply);
        vm.stopPrank();

        vm.prank(address(wrappedOutputProxy));
            flip.transfer(owner, slash);

        vm.prank(owner);
            wrappedRebaserProxy.rebase(1,0,false);

        uint256 expectedSupply = startSupply - slash + initialSupply;
        uint256 actualSupply = stflip.totalSupply();

        require( (expectedSupply > actualSupply) ? (expectedSupply - actualSupply <= 10**10) : (actualSupply - expectedSupply <= 10**10), "testFuzz_SuccessfulNegativeRebase: supply increase != expected");
    }

    using stdStorage for StdStorage;


    function _initializeClaimFee(uint256 initialMint, uint256 initialPendingFee) internal {
        vm.startPrank(owner);
            flip.mint(owner, initialMint);
            wrappedMinterProxy.mint(owner,initialMint);
            flip.mint(address(output), initialPendingFee);
        vm.stopPrank();

        stdstore
            .target(address(rebaser))
            .sig("pendingFee()")
            .depth(0)
            .checked_write(initialPendingFee);
    }
    function testFuzz_SuccessfulClaimFee(uint256 initialMint_, uint256 initialPendingFee_, uint256 amountToClaim_, bool max, bool receiveFlip) public {
        uint256 initialPendingFee = bound(initialPendingFee_, 0, 1_000_000*10**18);
        uint256 amountToClaim = bound(amountToClaim_, 0, initialPendingFee);
        uint256 initialMint = bound(initialMint_, 0, 30_000_000*10**18);

        IERC20 token = receiveFlip ? IERC20(address(flip)) : IERC20(address(stflip));

        uint256 initialTokenBalance = token.balanceOf(address(feeRecipient));

        _initializeClaimFee(initialMint, initialPendingFee);
        uint256 initialStflipSupply = stflip.totalSupply();
        

        vm.prank(manager);
            wrappedRebaserProxy.claimFee(amountToClaim, max, receiveFlip);

        uint256 expectedClaim = max ? initialPendingFee : amountToClaim;
        uint256 actualClaim = token.balanceOf(address(feeRecipient)) - initialTokenBalance;
        
        console.log("exp v. act", expectedClaim, actualClaim);
        require(_relativelyEq(expectedClaim, actualClaim) , "testFuzz_SuccessfulClaimFee: amount claimed != expected");


        uint256 expectedStflipSupply = receiveFlip ? initialStflipSupply : initialStflipSupply + expectedClaim;
        require(_relativelyEq(expectedStflipSupply, stflip.totalSupply()), "testFuzz_SuccessfulClaimFee: incorrect stflip supply change");
    }

    // function testFuzz_ExcessiveClaimFee() {}


}
