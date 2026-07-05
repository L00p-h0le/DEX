// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IDexPair} from "./interfaces/IDexPair.sol";
import {IDexFactory} from "./interfaces/IDexFactory.sol";
import {Math} from "../Periphery/libraries/Math.sol";
import {UQ112x112} from "../Periphery/libraries/UQ112x112.sol";
import {ERC20} from "../../lib/solady/src/tokens/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDexCallee} from "./interfaces/IDexCallee.sol";

contract DexPair is IDexPair , ERC20 , ReentrancyGuard {

    using UQ112x112 for uint224;
    using SafeERC20 for IERC20;

    address public token0;
    address public token1;
    address public immutable factory;

    uint112 private reserve0;
    uint112 private reserve1;

    uint32 private blockTimeStampLast;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast;

    uint public constant MINIMUM_LIQUIDITY = 10**3;

    error AlreadyInitialized();
    error Forbidden();
    error Overflow();
    error Insufficient_LiquidityMinted();
    error Insufficient_LiquidityBurned();
    error Insufficient_OutputAmount();
    error Insufficient_InputAmount();
    error Insufficient_Liquidity();
    error InvalidAddress();
    error InvariantError();

    function getReserve() public view returns(uint112 _reserve0 , uint112 _reserve1 , uint32 _blockTimeStampLast){
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimeStampLast = blockTimeStampLast;
    }

    constructor() {
        factory = msg.sender;
    }

    function initialise(address _token0, address _token1) external {

        if(msg.sender != factory) revert Forbidden();
        if(token0 != address(0)) revert AlreadyInitialized();

        token0 = _token0;
        token1 = _token1;
    }

    function mintFee(uint112 _reserve0 , uint112 _reserve1) private returns(bool feeOn){

        address feeTo = IDexFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast;
    
        if(feeOn) {
            if(_kLast != 0){
                uint rootK = Math.sqrt(uint256(_reserve0) * uint256(_reserve1));
                uint rookKLast = Math.sqrt(_kLast);

                uint _totalSupply = totalSupply();
                if(rootK > rookKLast){
                    uint numerator = _totalSupply * (rootK - rookKLast);
                    uint denominator = rootK * 5 + rookKLast;
                    uint liquidity = numerator / denominator;

                    if(liquidity > 0) _mint(feeTo , liquidity);
                }
            }                
        } else if (_kLast != 0){    
            kLast = 0;
        }
    }

    function update(uint balance0 , uint balance1 , uint112 _reserve0 , uint112 _reserve1) private{
        if(balance0 > type(uint112).max || balance1 > type(uint112).max) revert Overflow();
        uint32 blockTimeStamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimeStamp - blockTimeStampLast;
        if(timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0){
            unchecked {
                price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed; 
                price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
            }
        }

        // forge-lint: disable-next-line(unsafe-typecast)
        reserve0 = uint112(balance0);
        // forge-lint: disable-next-line(unsafe-typecast)
        reserve1 = uint112(balance1);
        blockTimeStampLast = blockTimeStamp;
        emit Sync(reserve0 , reserve1);
    } 

    function mint(address to) external nonReentrant returns(uint liquidity){
        (uint112 _reserve0 , uint112 _reserve1,) = getReserve();
        
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        bool feeOn = mintFee(_reserve0 , _reserve1);

        uint _totalSupply = totalSupply();
        if(_totalSupply == 0){
            liquidity = Math.sqrt(amount0 * amount1);
            if(liquidity < MINIMUM_LIQUIDITY) revert Insufficient_LiquidityMinted();
            liquidity -= MINIMUM_LIQUIDITY;
            _mint(address(0) , MINIMUM_LIQUIDITY);
        }
        else{
            liquidity = Math.min(amount0 * (_totalSupply) / reserve0 , amount1 * (_totalSupply) / reserve1);  
        }

        if(liquidity == 0) revert Insufficient_LiquidityMinted();

        _mint(to , liquidity);
        update(balance0 , balance1 , _reserve0 , _reserve1); 

        if(feeOn) kLast = uint(reserve0) * (reserve1);

        emit Mint(msg.sender , amount0 , amount1);
    }  

    function burn(address to)external nonReentrant returns(uint amount0 , uint amount1){
        (uint112 _reserve0 , uint112 _reserve1,) = getReserve();

        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint liquidity = balanceOf(address(this));

        bool feeOn = mintFee(_reserve0 , _reserve1);

        uint _totalSupply = totalSupply();

        if(liquidity == 0) revert Insufficient_LiquidityBurned();

        amount0 = liquidity * (balance0) / _totalSupply;
        amount1 = liquidity * (balance1) / _totalSupply;
        
        if(amount0 == 0 || amount1 == 0) revert Insufficient_LiquidityBurned();
        _burn(address(this) , liquidity);
        IERC20(token0).safeTransfer(to , amount0);
        IERC20(token1).safeTransfer(to , amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        update(balance0 , balance1 , _reserve0 , _reserve1);

        if(feeOn) kLast = uint(reserve0) * (reserve1);
        emit Burn(msg.sender , amount0 , amount1 , to);

    }

    function swap(uint amount0Out , uint amount1Out , address to , bytes calldata data) external nonReentrant {
        if(amount0Out == 0 && amount1Out == 0) revert Insufficient_OutputAmount();
        (uint112 _reserve0 , uint112 _reserve1,) = getReserve();

        if(amount0Out > _reserve0 || amount1Out > _reserve1) revert Insufficient_Liquidity();

        uint balance0;
        uint balance1;

        {
            address _token0 = token0;
            address _token1 = token1;

            if(to == _token0 || to == _token1) revert InvalidAddress();

            if(amount0Out > 0) IERC20(_token0).safeTransfer(to , amount0Out);
            if(amount1Out > 0) IERC20(_token1).safeTransfer(to , amount1Out);
            if(data.length > 0) IDexCallee(to).dexV2Call(msg.sender , amount0Out , amount1Out , data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        if(amount0In == 0 && amount1In == 0) revert Insufficient_InputAmount();

        {
            uint balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
            uint balance1Adjusted = (balance1 * 1000) - (amount1In * 3);

            if(balance0Adjusted * balance1Adjusted < uint256(_reserve0) * uint256(_reserve1) * (1000**2)) revert InvariantError();
        }

        update(balance0 , balance1 , _reserve0 , _reserve1);
        emit Swap(msg.sender , amount0In , amount1In , amount0Out , amount1Out , to);
    }

    function name() public pure override returns (string memory) {
        return "DexPair LP Token";
    }

    function symbol() public pure override returns (string memory) {
        return "DEX-LP";
    }
}
