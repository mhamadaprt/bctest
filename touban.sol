pragma solidity ^0.4.23;
 
contract Accounts {
    uint accountId;
    struct Account {
        //address addr;
        string name;
    }
    mapping(uint => Account) accounts;
 
    constructor() public {
    }
    
    function resetAccount() public returns(uint) {
        accountId = 0;
        return 0;
    }
 
    function createAccount(string _name) public returns(uint _accountId) {
        accountId += 1;
        //accounts[accountId].addr = _addr;
        accounts[accountId].name = _name;
        return accountId;
    }
    
    function editAccount(uint _id, string _name) public returns(bool) {
        if(_id > accountId)
            return false;
        //accounts[_id].addr = _addr;
        accounts[_id].name = _name;
        return true;
    }
 
    function getAccountName(uint _id) constant public returns(string _name) {
        if(_id > accountId)
            return "";
        return accounts[_id].name;
    }
    
    function getAccountCount() constant public returns(uint _count) {
        return accountId;
    }

}

contract Rotas {
    uint toubanId;
    struct Touban{
        uint ownerId;
        string title;
        string description;
        uint rotaPointer;
        uint prevAccountId;
        uint compTimestamp;
        uint[] rota;
    }
    mapping(uint => Touban) toubanList;
 

    constructor() public{
    }
 
    function createTouban(uint _ownerId, string _title, string _description) public returns(uint _toubanId) {
        toubanId += 1;
        toubanList[toubanId].ownerId = _ownerId;
        toubanList[toubanId].title = _title;
        toubanList[toubanId].description = _description;
        toubanList[toubanId].rotaPointer = 0;
        toubanList[toubanId].prevAccountId = 0;
        toubanList[toubanId].compTimestamp = 0;
        toubanList[toubanId].rota.push(_ownerId);
        return toubanId;
    }
    
    function completion(uint _toubanId) public returns(uint _nextAccountId) {
        toubanList[_toubanId].prevAccountId = toubanList[_toubanId].rota[toubanList[_toubanId].rotaPointer];
        toubanList[_toubanId].compTimestamp = now;
        if(toubanList[_toubanId].rotaPointer + 1 == toubanList[_toubanId].rota.length) {
            toubanList[_toubanId].rotaPointer = 0;
        } else {
            toubanList[_toubanId].rotaPointer += 1;
        }
        if(toubanList[_toubanId].rotaPointer + 1 == toubanList[_toubanId].rota.length) {
            return toubanList[_toubanId].rota[0];
        }
        return toubanList[_toubanId].rota[toubanList[_toubanId].rotaPointer + 1];
    }
    
    function addRota(uint _toubanId, uint _Id) public returns(uint _idCount) {
        toubanList[toubanId].rota.push(_Id);
        return toubanList[_toubanId].rota.length;
    }
 
    function getDetail(uint _toubanId, address _contractAddr) constant public returns(string _title, string _description, uint _currentAccountId, uint _nextAccountId, uint _prevAccountId, uint _compTimestamp, uint _idCount, uint[] _ids, string _currentName) {
        Accounts acc = Accounts(_contractAddr);
        
        _title = toubanList[_toubanId].title;
        _description = toubanList[_toubanId].description;
        _currentAccountId = toubanList[_toubanId].rota[toubanList[_toubanId].rotaPointer];
        if(toubanList[_toubanId].rotaPointer + 1 == toubanList[_toubanId].rota.length) {
            _nextAccountId = toubanList[_toubanId].rota[0];
        } else {
            _nextAccountId = toubanList[_toubanId].rota[toubanList[_toubanId].rotaPointer + 1];
        }
        _prevAccountId = toubanList[_toubanId].prevAccountId;
        _compTimestamp = toubanList[_toubanId].compTimestamp;
        _idCount = toubanList[_toubanId].rota.length;
        _ids = toubanList[_toubanId].rota;
        _currentName = acc.getAccountName(_currentAccountId);
        
        return;
    }
    
    function getRotaCount() constant public returns(uint _count) {
        return toubanId;
    }
    
    function getMembers(uint _toubanId) constant public returns(uint[] _ids) {
        return toubanList[_toubanId].rota;
    }
 
 /*
    //チケットを購入する
    function buyTicket(uint _ticketId,address _contractAddr, uint _buyerAccId, address _buyerAddr, uint _sellerAccId, uint _money)returns(bool _ret) {
        if(tickets[_ticketId].salesCount >= tickets[_ticketId].issuedAmount)  //チケットの発行総量より発行済み枚数が多くなる場合は処理せずに終了する
            return false;
        Accounts acc = Accounts(_contractAddr); //Acountsコントラクトを生成する
        acc.payment(_buyerAccId,_buyerAddr,_sellerAccId,_money);
        tickets[_ticketId].salesCount += 1;
            return true;
    }
*/ 
}
