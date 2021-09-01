const AssetLocker = artifacts.require("AssetLocker");

module.exports = function (deployer) {
  deployer.deploy(AssetLocker);
};
