pragma solidity ^0.4.23;

contract SupplyChain {

    address owner;
    uint skuCount;

    mapping (uint => Item) public items;

    enum State {ForSale, Sold, Shipped, Received}

    struct Item{
        string name;
        uint sku;
        uint price;
        State state;
        address seller;
        address buyer;
    }

    event ForSale(uint sku);
    event Sold(uint sku);
    event Shipped(uint sku);
    event Received(uint sku);

    modifier verifyCaller (address _address) {
        require(msg.sender == _address);
        _;
    }

    //check if the buyer paid enough
    modifier paidEnough(uint _price) {
        require(msg.value >= _price); 
        _;
    }

    //refund if excess ether paid
    modifier checkValue(uint _sku) {
        _;
        uint _price = items[_sku].price;
        uint amountToRefund = msg.value - _price;
        items[_sku].buyer.transfer(amountToRefund);
    }

    modifier forSale (uint _sku) {
        require(items[_sku].state == State.ForSale);
        _;
    }

    modifier sold (uint _sku) {
        require(items[_sku].state == State.Sold);
        _;
    }

    modifier shipped (uint _sku) {
        require(items[_sku].state == State.Shipped);
        _;
    }
    
    modifier received (uint _sku) {
        require(items[_sku].state == State.Received);
        _;
    }

    constructor() public {
        owner = msg.sender;
        skuCount = 0;
    }

    function addItem(string _name, uint _price) public {
        emit ForSale(skuCount);
        items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: 0});
        skuCount = skuCount + 1;
    }

    function buyItem(uint _sku) public payable 
    forSale(_sku)
    paidEnough(items[_sku].price)
    checkValue(_sku)
    {    
        items[_sku].buyer = msg.sender;
        items[_sku].state = State.Sold;
        uint _price = items[_sku].price;
        items[_sku].seller.transfer(_price);
        skuCount -= 1;
        emit Sold(skuCount);
    }

    function shipItem(uint _sku) public
    sold(_sku)
    verifyCaller(items[_sku].seller)
    {
        items[_sku].state = State.Shipped;
        emit Shipped(_sku);     
    }

    function receiveItem(uint _sku) public
    shipped(_sku)
    verifyCaller(items[_sku].buyer)
    {
        items[_sku].state = State.Received;
        emit Received(_sku);
    }

    function fetchItem(uint _sku) public view returns (string name, uint sku, uint price, uint state, address seller, address buyer) {
        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        state = uint(items[_sku].state);
        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
        return (name, sku, price, state, seller, buyer);
    }

}
