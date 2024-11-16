// SPDX-License-Identifier: MIT
// by 0xAA
pragma solidity ^0.8.21;

import "../721/IERC165.sol";
import "../721/IERC721.sol";
import "../721/IERC721Receiver.sol";
import "../721/IERC721Metadata.sol";
import "./String.sol";

contract ERC721 is IERC721, IERC721Metadata{
    using Strings for uint256;

    string public override name;
    string public override symbol;

    mapping( uint => address) private _owner; //token=>owner's address
    mapping(address=> uint) private _balance; //address => token number
    mapping(uint=>address) private _tokenApprovals; //token id => approve address
    mapping(address=>mapping(address=>bool)) private _operatorApprovals; //owner addr=>operator 

    error ERC721InvalidReceiver(address receiver);

    constructor(string memory name_, string memory symbol_){
        name = name_;
        symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool){
        return interfaceId == type(IERC721).interfaceId || 
               interfaceId == type(IERC165).interfaceId || 
               interfaceId == type(IERC721Metadata).interfaceId;
    }

    function balanceOf(address owner) external view override returns (uint) {
        require(owner != address(0), "owner == zero address");
        return _balance[owner];
    }

    function ownerOf(uint tokenId) public view override returns (address owner){
        owner = _owner[tokenId];
        require(owner != address(0), "owner is address 0");
    }

     function isApprovedForAll(address owner, address operator) external view override returns(bool){
        return _operatorApprovals[owner][operator];
     }

     function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
     }

    function getApproved(uint tokenId) external view override returns(address){
        require(_owner[tokenId] != address(0), "address is 0");
        return _tokenApprovals[tokenId];
    }

    function _approve(address owner, address to, uint tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function approve(address to, uint tokenId) external override {
        address owner = _owner[tokenId];
        require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "not owner nor approved for all"
        );
        _approve(owner, to, tokenId);
    }

    function _isApprovedOrOwner(
        address owner,
        address spender,
        uint tokenId
    ) private view returns (bool) {
        return (spender == owner || _tokenApprovals[tokenId] == spender || _operatorApprovals[owner][spender]) ;
    }

     function _transfer(
        address owner,
        address from,
        address to,
        uint tokenId
    ) private{
        require(from == owner, "not onwer");
        require(to != address(0), "transfer to the zero address");

        _approve(owner, to, tokenId);
        _balance[from] -= 1;
        _balance[to] += 1;
        _owner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        address own = _owner[tokenId];
        require(_isApprovedOrOwner(own, from, tokenId), "no owner nor approved!");

        _transfer(own, from, to, tokenId);
    }

    function _safeTransfer(
        address owner,
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private {
        _transfer(owner, from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, _data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) public override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _safeTransfer(owner, from, to, tokenId, _data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "mint to zero address");
        require(_owner[tokenId] == address(0), "token already minted");

        _balance[to] += 1;
        _owner[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint tokenId) internal virtual  {
        address owner = _owner[tokenId];
        require(msg.sender == owner, "not owner of token"); 

        _approve(owner, address(0), tokenId);

        _balance[owner] -= 1;
        delete _owner[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private{
        if(to.code.length > 0){
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns(bytes4 retval){
                if(retval != IERC721Receiver.onERC721Received.selector){
                    revert ERC721InvalidReceiver(to);
                }
            }catch (bytes memory reason){
                if(reason.length == 0){
                    revert ERC721InvalidReceiver(to);
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_owner[tokenId] != address(0), "Token Not Exist");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
}