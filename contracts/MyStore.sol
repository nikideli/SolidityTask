// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;
import "./Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MyStore is Ownable {
    uint private constant RETURNBLOCKS = 100; 

    struct Product {
        string name;
        uint quantity;
    }

    struct Client {
        address clientAddress;
        mapping(uint => Transaction) productsBought;
    }

    struct Transaction {
        uint productId;
        uint blockNumber;
        uint quantity;
    }

    uint private productCount = 0;
    mapping(string => uint) private productIds;
    mapping(uint => Product) private productsLedger;
    mapping(address => Client) private clients;
    mapping(uint => address[]) private clientsHistory;

    function addProduct(string calldata _productName, uint _quantity) public onlyOwner {
       if (productIds[_productName] == 0)
       {
           productCount++;
           productIds[_productName] = productCount;
           productsLedger[productIds[_productName]].name = _productName;
           productsLedger[productIds[_productName]].quantity = _quantity;
       }
        else
        {
            productsLedger[productIds[_productName]].quantity += _quantity;
        }   
    }

    function showProducts() public view returns(string[] memory)
    {
        string[] memory ret = new string[](productCount);
        uint arrayIndex = 0;
        for (uint i = 0; i < productCount; i++) 
        {
            if (productsLedger[i + 1].quantity > 0)
            {
                ret[arrayIndex] = string(abi.encodePacked(Strings.toString(i + 1), ". ", productsLedger[i+1].name, ": ", Strings.toString(productsLedger[i + 1].quantity)));
                arrayIndex++;
            }
        }
        return ret;
    }

    function addClientToHistory(address _clientAddress, uint _prodId) private {
        bool alreadyExists;
        for (uint i = 0 ; i < clientsHistory[_prodId].length; i++)
        {
            if (clientsHistory[_prodId][i] == _clientAddress)
            {
                alreadyExists = true;
                break;
            }
        }

        if (!alreadyExists)
        {
            clientsHistory[_prodId].push(_clientAddress);
        }
    }

    function buy(uint _prodId, uint _productQuantity) public
    {
        require(_productQuantity > 0, "Cannot buy 0 productsLedger!");
        require(_prodId <= productCount, "No such product!");
        require(clients[msg.sender].productsBought[_prodId].quantity == 0, "Already bought!");
        require(productsLedger[_prodId].quantity >= _productQuantity, "There is not enough quantity in the store!");
        
        productsLedger[_prodId].quantity -= _productQuantity;
        if (clients[msg.sender].clientAddress != msg.sender)
            clients[msg.sender].clientAddress = msg.sender; 
        
        clients[msg.sender].productsBought[_prodId].productId = _prodId;
        clients[msg.sender].productsBought[_prodId].quantity = _productQuantity;
        clients[msg.sender].productsBought[_prodId].blockNumber = block.number;

        addClientToHistory(msg.sender, _prodId);
    }

    function returnProduct(uint _prodId, uint _productQuantity) public
    {
        require(_productQuantity > 0, "Cannot return 0 products!");
        require(clients[msg.sender].productsBought[_prodId].quantity >= _productQuantity, "Cannot return more than you have bought!");
        require((block.number - clients[msg.sender].productsBought[_prodId].blockNumber) <= RETURNBLOCKS, "Transaction is older than 100 blocks!");

        clients[msg.sender].productsBought[_prodId].quantity -= _productQuantity; 
        productsLedger[_prodId].quantity += _productQuantity;
    }

    function showClientsHistory(uint _prodId) public view returns(address[] memory)
    {
        return clientsHistory[_prodId]; 
    }    
}