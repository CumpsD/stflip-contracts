interface ICurveDeployer {
    function deploy_plain_pool(string memory name1, string memory name2, address[4] memory tokens, uint256 A, uint256 b) external returns (address);
    function deploy_plain_pool(string memory name1, string memory name2, address[4] memory tokens, uint256 A, uint256 b, uint256 c, uint256 d) external returns (address);
    function admin() external returns (address);
}