// SPDX-License-Identifier: MIT
// Colaboration is welcone, repository can be found at
// https://github.com/hellowodl/asset-locker

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

contract AssetLocker is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    event AssetLocked (
        address user,
        address asset,
        uint256 amount,
        uint256 lockDays,
        uint256 lockTime
    );

    event AssetWithdrawn (
        address user,
        address asset,
        uint256 amount
    );

    struct LockedAsset {
        uint256 amount;
        uint256 unlockTime;
        bool withdrawn;
    }

    mapping (bytes32 => LockedAsset) public lockedAssets;

    function lockAsset (IERC20 asset, uint256 lockDays) external nonReentrant onlyOwner {
        bytes32 identifier = getIdentifier(asset);
        uint256 amount = asset.balanceOf(msg.sender);

        require(lockedAssets[identifier].amount == 0, "Asset already deposited");

        asset.safeTransferFrom(msg.sender, address(this), amount);

        lockedAssets[identifier] = LockedAsset({
            amount: amount,
            unlockTime: lockDays * 1 days + block.timestamp,
            withdrawn: false
        });

        emit AssetLocked(msg.sender, address(asset), amount, lockDays, block.timestamp);
    }

    function withdrawAsset (IERC20 asset) external nonReentrant onlyOwner {
        bytes32 identifier = getIdentifier(asset);

        LockedAsset storage lockedAsset = lockedAssets[identifier];

        require(lockedAsset.amount > 0, "Asset never deposited");
        require(!lockedAsset.withdrawn, "Asset already withdrawn");
        require(lockedAsset.unlockTime <= block.timestamp, "Locktime has not expired");

        asset.safeTransfer(msg.sender, lockedAsset.amount);

        lockedAsset.withdrawn = true;

        emit AssetWithdrawn(msg.sender, address(asset), lockedAsset.amount);
    }

    function getIdentifier (IERC20 asset) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(address(asset), msg.sender)
        );
    }
}