// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

struct Product{
    string product_title;
    bytes32 product_qrcode;
    string date_created;
    string product_desc;
    uint price;
    address original_owner;
    address payable curr_owner;
    string priv_code;       //Only visible to the owner of the product
    //Will keep a log of all the owners of the product and a corresponsing log of the dates the ownership was transferred to that owner. latest owner will be the current owner
    address[] prevowner;
    string[] ownershipdate;
}

struct Bid{
    uint BidID;
    string code;
    uint offer;
    address buyer;
    bool status;
}

contract jinjja{
    Product[] ProductsList;
    address owner;
    Bid[] Bids;

    constructor(){
        owner = msg.sender;
    }

    //============================================UTILITY FUNCTIONS==============================================

    function strConcat(string memory _a, string memory _b) public returns(string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory ba = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) ba[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) ba[k++] = _bb[i];
        return string(ba);  
    }

    function getGeneralInfo(Product memory p) public returns (string memory) {
        string memory tempprod;
        tempprod = strConcat(p.product_desc,p.product_desc);
        return tempprod;
    }

    function getIndex(bytes32 code) public view returns (uint){
        for(uint i = 0; i < ProductsList.length;i++){
            if(ProductsList[i].product_qrcode == code){
                return i;
            }
        }
        return 9999;
    }

    function getIndexfromTitle(string memory title) public view returns (uint){
        for(uint i = 0; i < ProductsList.length;i++){
            if(keccak256(bytes(ProductsList[i].product_title ))== keccak256(bytes(title))){
                return i;
            }
        }
        return 9999;
    }

    function convertToBytes32(string memory str) public view returns(bytes32){
        return keccak256(bytes(str));
    }

    //=======================================IMPORTANT BUSINESS LOGIC FUNCTIONS==================================
    //Add a new product
    function AddProduct(string memory title,string memory code,string memory dt, string memory desc, uint p ) public {
        bool found = false;
        for(uint i = 0; i < ProductsList.length; i++){
            if (keccak256(bytes(ProductsList[i].priv_code))==keccak256(bytes(code))){
                found = true;
                break;
            }
        }
        if(found == false){
            Product memory temp;
            temp.product_title = title;
            temp.priv_code = code;
            temp.product_qrcode = keccak256(bytes(code));
            temp.date_created= dt;
            temp.product_desc = desc;
            temp.price = p;
            temp.original_owner = msg.sender;
            temp.curr_owner = payable(msg.sender);
            ProductsList.push(temp);
            ProductsList[ProductsList.length-1].prevowner.push(payable(msg.sender));
            ProductsList[ProductsList.length-1].ownershipdate.push(dt);
        }
    }

    function PlaceBid(string memory title , uint offer) public {
        uint ind = getIndexfromTitle(title);
        if(ProductsList[ind].price <= offer){
            Bid memory tempbid;
            tempbid.buyer = msg.sender;
            tempbid.status = false;
            tempbid.offer = offer;
            tempbid.BidID = Bids.length;
            tempbid.code = ProductsList[ind].priv_code;
            Bids.push(tempbid);
        }
    }

    function viewBids() public view returns (Bid[] memory ){
        return Bids;
    }

    function AcceptBid(uint bidid)public {
        uint ind = getIndex(convertToBytes32(Bids[bidid].code));
        if (msg.sender == ProductsList[ind].curr_owner){
            if(bidid >= 0 && bidid <= Bids.length){
                Bids[bidid].status = true;
            }
        }
    }

    function ConfirmPurchase(uint bidid, string memory dt) public payable{
        if(bidid >= 0 && bidid <= Bids.length){
            uint ind = getIndex(convertToBytes32(Bids[bidid].code));
            if(Bids[bidid].status == true && Bids[bidid].buyer == msg.sender && Bids[bidid].offer <= msg.value){
                //ProductsList[ind].curr_owner.transfer(msg.value * 1 ether);
                TransferOwnerShip(Bids[bidid].buyer,Bids[bidid].code, dt);
            }
        }
    }

    function TransferOwnerShip(address buyer, string memory code, string memory dt) public{
        uint ind = getIndex(convertToBytes32(code));
        if (ind != 9999){
            ProductsList[ind].curr_owner = payable(buyer);
            ProductsList[ind].ownershipdate.push(dt);
            ProductsList[ind].prevowner.push(buyer);
        }
    }

    function VerifyProduct(string memory code) public view returns(string memory ){
        uint ind = getIndex(convertToBytes32(code));
        if (ind != 9999){
            if(ProductsList[ind].product_qrcode == keccak256(bytes(code))){
                return "REAL";
            }   
            else{
                return "FAKE";
            }
        }
        else{
            return "FAKE";
        }
    }

    //====================================GETTER FUNCTIONS TO GET DETAILS ABOUT A PRODUCT========================
    function returnList() public returns(string memory){
        string memory storelist;
        for (uint i = 0 ; i < ProductsList.length; i++){
            storelist = strConcat(storelist,getGeneralInfo(ProductsList[i]));
        }
        return storelist;
    }

    function GetHiddenList() public view returns(Product[] memory){
        if(msg.sender == owner){
            return ProductsList;
        }
    }

    function getCurrentOwner(string memory code) public view returns(address){
        uint ind = getIndex(convertToBytes32(code));
        if (ind != 9999){
            return ProductsList[ind].curr_owner;
        }
        else{
            return address(0);
        }
    }
    function getCurrentOwnerfromName(string memory title) public view returns(address){
        uint ind = getIndexfromTitle(title);
        if (ind != 9999){
            return ProductsList[ind].curr_owner;
        }
        else{
            return address(0);
        }
    }

    function getOriginalOwner(string memory code) public view returns(address){
        uint ind = getIndex(convertToBytes32(code));
        if (ind != 9999){
            return ProductsList[ind].original_owner;
        }
        else{
            return address(0);
        }
    }
    function getOriginalOwnerfromName(string memory code) public view returns(address){
        uint ind = getIndexfromTitle(code);
        if (ind != 9999){
            return ProductsList[ind].original_owner;
        }
        else{
            return address(0);
        }
    }

    function getProductDetails(string memory code) public returns(string memory){
        uint ind = getIndex(convertToBytes32(code));
        if (ind != 9999){
            return getGeneralInfo(ProductsList[ind]);
        }
        return ("***INCORRECT PRODUCT CODE***");
    }

    function getPrice(string memory code) public view returns(uint ){
        uint ind = getIndex(convertToBytes32(code));
        if (ind != 9999){
            return ProductsList[ind].price;
        }
        return 0;
    }
    function getPricefromName(string memory title) public view returns(uint ){
        uint ind = getIndexfromTitle(title);
        if (ind != 9999){
            return ProductsList[ind].price;
        }
        return 0;
    }

    function getTitle(string memory code) public view returns(string memory ){
        uint ind = getIndex(convertToBytes32(code));
        if (ind != 9999){
            return ProductsList[ind].product_title;
        }
        return "INCORRECT CODE";
    }

    function getDescription(string memory code) public view returns(string memory ){
        uint ind = getIndex(convertToBytes32(code));
        if (ind != 9999){
            return ProductsList[ind].product_desc;
        }
        return "INCORRECT CODE";
    }

    function getPrevOwners(string memory code) public view returns(address[] memory){
        uint ind = getIndex(convertToBytes32(code));
        if (msg.sender == owner || msg.sender == ProductsList[ind].curr_owner){
            return ProductsList[ind].prevowner;
        }
    }

    function getPrevOwnersDates(string memory code) public view returns(string[] memory ){
        uint ind = getIndex(convertToBytes32(code));
        if (msg.sender == owner || msg.sender == ProductsList[ind].curr_owner){
            return ProductsList[ind].ownershipdate;
        }
    }

    function getQrcode(string memory title)public view returns(bytes32){
        uint ind = getIndexfromTitle(title);
        if (ind != 9999){
            return ProductsList[ind].product_qrcode;
        }
    }

}