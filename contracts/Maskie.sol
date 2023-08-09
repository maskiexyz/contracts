// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Maskie is ERC721Upgradeable, OwnableUpgradeable {
    string public baseURI;
    address public usdcAddress;
    mapping(uint256 => address) public creator;

    address public protocolFeeAddress;
    address public distributionFeeAddress;

    uint256 public protocolFeePercentage;  // default to 5%
    uint256 public distributionFeePercentage; // default to 10%

    event MaskieMinted(uint256 indexed tokenId, address indexed creator, address indexed owner, uint256 price);
    event MaskieBought(address previousOwner, address newOwner, uint256 price);
    event RewardsDistributed(address indexed to, uint256 amount);

    function initialize(address _protocolFeeAddress, address _distributionFeeAddress, string memory _baseURI, address _usdcAddress) public initializer {
        __ERC721_init("Maskie", "MASK");
        __Ownable_init();

        protocolFeeAddress = _protocolFeeAddress;
        distributionFeeAddress = _distributionFeeAddress;
        baseURI = _baseURI;
        usdcAddress = _usdcAddress;

        protocolFeePercentage = 5;
        distributionFeePercentage = 10;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setUsdcAddress(address _usdcAddress) external onlyOwner {
        usdcAddress = _usdcAddress;
    }

    function setProtocolFeeAddress(address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        protocolFeeAddress = _address;
    }

    function setDistributionFeeAddress(address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        distributionFeeAddress = _address;
    }

    function setProtocolFeePercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Percentage cannot exceed 100");
        protocolFeePercentage = _percentage;
    }

    function setDistributionFeePercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Percentage cannot exceed 100");
        distributionFeePercentage = _percentage;
    }

    function mint(uint256 id, address _creator, address _owner, uint256 price) public onlyOwner {
        uint256 protocolFee = (price * protocolFeePercentage) / 100;
        uint256 creatorPayment = price - protocolFee;

        require(IERC20(usdcAddress).transferFrom(_owner, protocolFeeAddress, protocolFee), "Protocol fee transfer failed!");
        require(IERC20(usdcAddress).transferFrom(_owner, _creator, creatorPayment), "Payment to creator failed!");

        _mint(_owner, id);
        creator[id] = _creator;

        emit MaskieMinted(id, _creator, _owner, price);
    }

    function buy(uint256 tokenId, uint256 price, address newOwner) external onlyOwner {
        address previousOwner = ownerOf(tokenId);

        uint256 protocolFee = (price * protocolFeePercentage) / 100;
        uint256 distributionFee = (price * distributionFeePercentage) / 100;
        uint256 ownerPayment = price - protocolFee - distributionFee;

        require(IERC20(usdcAddress).transferFrom(newOwner, previousOwner, ownerPayment), "Payment to previous owner failed");
        require(IERC20(usdcAddress).transferFrom(newOwner, protocolFeeAddress, protocolFee), "Protocol fee transfer failed");
        require(IERC20(usdcAddress).transferFrom(newOwner, distributionFeeAddress, distributionFee), "Distribution fee transfer failed");

        _transfer(previousOwner, newOwner, tokenId);

        emit MaskieBought(previousOwner, newOwner, price);
    }

    function distributeRewards(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Mismatched input arrays");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(IERC20(usdcAddress).transferFrom(distributionFeeAddress, recipients[i], amounts[i]), "Reward distribution failed");
            emit RewardsDistributed(recipients[i], amounts[i]);
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}