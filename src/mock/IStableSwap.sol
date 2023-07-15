pragma solidity ^0.8.7;

interface IStableSwap {
    function get_virtual_price() external view returns (uint256);
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;
    function remove_liquidity(uint256 amount, uint256[4] calldata min_amounts) external;
    function exchange(int128 from, int128 to, uint256 amount, uint256 min_amount) payable external returns (uint256);
    function exchange(int128 from, int128 to, uint256 amount, uint256 min_amount, address receiver ) payable external returns (uint256);
    function calc_token_amount(uint256[4] calldata amounts, bool deposit) external view returns (uint256);
    function get_dy(int128 i, int128 j, uint256 _dx) external view returns (uint256);
    function balances(uint256 i) external view returns (uint256);
}