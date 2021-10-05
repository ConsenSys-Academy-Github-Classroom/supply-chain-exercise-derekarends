// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {
  address public owner;
  uint public skuCount;
  mapping(uint => Item) private items;

  enum State {
    ForSale,
    Sold,
    Shipped,
    Received
  }

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }
  
  /* 
   * Events
   */

  event LogForSale(uint256 sku);
  event LogSold(uint256 sku);
  event LogShipped(uint256 sku);
  event LogReceived(uint256 sku);

  /* 
   * Modifiers
   */

  modifier isOwner() {
    require (msg.sender == owner, "Only an owner can do this");
    _;
  }

  modifier verifyCaller (address _address) { 
    require (msg.sender == _address, "Sender must match address"); 
    _;
  }

  modifier paidEnough(uint _price) { 
    require(msg.value >= _price, "Not enough value provided"); 
    _;
  }

  modifier checkValue(uint _sku) {
    _;
    uint amountToRefund = msg.value - items[_sku].price;
    require(amountToRefund <= msg.value, "Refund is invalid");
    (bool success, ) = items[_sku].buyer.call.value(amountToRefund)("");
    require(success, "Failed to refund");
  }

  modifier forSale(uint _sku) {
    require (items[_sku].seller != address(0) && items[_sku].state == State.ForSale, "Item must be for sale");
    _;
  }
 
  modifier sold(uint _sku) {
    require (items[_sku].state == State.Sold, "Item must be sold");
    _;
  }

  modifier shipped(uint _sku) {
    require (items[_sku].state == State.Shipped, "Item must be shipped");
    _;
  }

  modifier received(uint _sku) {
    require (items[_sku].state == State.Received, "Item must be received");
    _;
  }

  constructor() public {
    owner = msg.sender;
    skuCount = 0;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    items[skuCount] = Item({
     name: _name, 
     sku: skuCount, 
     price: _price, 
     state: State.ForSale, 
     seller: msg.sender, 
     buyer: address(0)
    });
    
    emit LogForSale(skuCount);
    skuCount = skuCount + 1;
    return true;
  }

  // Implement this buyItem function. 
  // 1. it should be payable in order to receive refunds
  // 2. this should transfer money to the seller, 
  // 3. set the buyer as the person who called this transaction, 
  // 4. set the state to Sold. 
  // 5. this function should use 3 modifiers to check 
  //    - if the item is for sale, 
  //    - if the buyer paid enough, 
  //    - check the value after the function is called to make 
  //      sure the buyer is refunded any excess ether sent. 
  // 6. call the event associated with this function!
  function buyItem(uint sku) 
    public 
    payable
    forSale(sku)
    paidEnough(sku)
    checkValue(sku)
  {
    items[sku].state = State.Sold;
    items[sku].buyer = msg.sender;
    (bool success, ) = items[sku].seller.call.value(items[sku].price)("");
    require(success, "Failed to pay seller");
    emit LogSold(sku);
  }

  // 1. Add modifiers to check:
  //    - the item is sold already 
  //    - the person calling this function is the seller. 
  // 2. Change the state of the item to shipped. 
  // 3. call the event associated with this function!
  function shipItem(uint sku) 
    public
    verifyCaller(items[sku].seller)
    sold(sku)
    {
      items[sku].state = State.Shipped;
      emit LogShipped(sku);
    }

  // 1. Add modifiers to check 
  //    - the item is shipped already 
  //    - the person calling this function is the buyer. 
  // 2. Change the state of the item to received. 
  // 3. Call the event associated with this function!
  function receiveItem(uint sku)
    public
    verifyCaller(items[sku].buyer)
    shipped(sku)
  {
    items[sku].state = State.Received;
    emit LogReceived(sku);
  }

  // @dev Fetches a item from our list
  function fetchItem(uint _sku) 
    public 
    view
    returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) 
  {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }
}
