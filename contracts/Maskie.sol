// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Maskie is OwnableUpgradeable, ERC721Upgradeable, AccessControlUpgradeable {
    using Strings for uint256;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    string public baseURI;
    address public usdcAddress;
    mapping(uint256 => address) public creator;

    address public protocolFeeAddress;
    address public distributionFeeAddress;

    uint256 public protocolFeePercentage;  // default to 5%
    uint256 public distributionFeePercentage; // default to 10%

    event MaskieMinted(uint256 indexed tokenId, address indexed creator, address indexed owner, uint256 price);
    event MaskieBought(uint256 indexed tokenId, address previousOwner, address newOwner, uint256 price);
    event RewardsDistributed(address indexed to, uint256 amount);

    function initialize() public initializer {
        __ERC721_init("Maskie", "MASK");
        __Ownable_init();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        protocolFeePercentage = 5;
        distributionFeePercentage = 10;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    function setUsdcAddress(address _usdcAddress) external onlyOwner {
        require(_usdcAddress != address(0), "Invalid address");
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

    function mint(uint256 id, address _creator, address _owner, uint256 price) external onlyRole(ADMIN_ROLE) {
        uint256 protocolFee = (price * protocolFeePercentage) / 100;
        uint256 creatorPayment = price - protocolFee;

        require(IERC20(usdcAddress).transferFrom(_owner, protocolFeeAddress, protocolFee), "Protocol fee transfer failed!");
        require(IERC20(usdcAddress).transferFrom(_owner, _creator, creatorPayment), "Payment to creator failed!");

        _mint(_owner, id);
        creator[id] = _creator;

        emit MaskieMinted(id, _creator, _owner, price);
    }

    function buy(uint256 id, uint256 price, address _newOwner) external onlyRole(ADMIN_ROLE) {
        address previousOwner = ownerOf(id);
        require(previousOwner != address(0), 'Token does not exist');

        uint256 protocolFee = (price * protocolFeePercentage) / 100;
        uint256 distributionFee = (price * distributionFeePercentage) / 100;
        uint256 ownerPayment = price - protocolFee - distributionFee;

        require(IERC20(usdcAddress).transferFrom(_newOwner, previousOwner, ownerPayment), "Payment to previous owner failed");
        require(IERC20(usdcAddress).transferFrom(_newOwner, protocolFeeAddress, protocolFee), "Protocol fee transfer failed");
        require(IERC20(usdcAddress).transferFrom(_newOwner, distributionFeeAddress, distributionFee), "Distribution fee transfer failed");

        _transfer(previousOwner, _newOwner, id);

        emit MaskieBought(id, previousOwner, _newOwner, price);
    }

    function distribute(address[] memory recipients, uint256[] memory amounts) external onlyRole(ADMIN_ROLE) {
        require(recipients.length == amounts.length, "Mismatched input arrays");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(IERC20(usdcAddress).transferFrom(distributionFeeAddress, recipients[i], amounts[i]), "Reward distribution failed");
            emit RewardsDistributed(recipients[i], amounts[i]);
        }
    }

    function grantAdminRole(address account) public onlyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    function revokeAdminRole(address account) public onlyOwner {
        revokeRole(ADMIN_ROLE, account);
    }

    function isAdmin(address account) public view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}