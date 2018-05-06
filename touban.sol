pragma solidity ^0.4.23;
import "github.com/Arachnid/solidity-stringutils/src/strings.sol";

/**
* Accounts: 人コントラクト
* 人マスタを管理する
* 実態は名前の連想配列のみ
*
*/
contract Accounts {
    using strings for *;
    address private contractOwner;
    uint accountId;
    struct Account {
        //address addr;
        string name;
    }
    mapping(uint => Account) accounts;

    // コンストラクタ
    constructor() public {
      contractOwner = msg.sender;
    }

    /**
    *  resetAccount: 人マスタを初期化する
    *  accountIDをゼロにしているだけ
    *
    *  @return {uint} 常に0
    */
    function resetAccount() public returns(uint) {
        accountId = 0;
        return 0;
    }

    /**
    *  createAccount: 人マスタに一人追加する
    *  とりあえず名前のみ。配列の一番後ろに追加される
    *
    *  @param _name 追加する人の名前
    *  @return {uint} _accountId 追加した人のID
    */
    function createAccount(string _name) public returns(uint _accountId) {
        accountId += 1;
        //accounts[accountId].addr = _addr;
        accounts[accountId].name = _name;
        return accountId;
    }

    /**
    *  editAccount: 指定IDの名前を変更する
    *
    *  @param _id 変更するID
    *  @param _name 変更後の名前
    *  @return {bool} ture:成功 false:IDが範囲外
    */
    function editAccount(uint _id, string _name) public returns(bool) {
        if(_id > accountId)
            return false;
        //accounts[_id].addr = _addr;
        accounts[_id].name = _name;
        return true;
    }

    /**
    *  getAccountName: 指定IDの名前を取得する
    *
    *  @param _id ID
    *  @return {string} _name 名前 IDが無効の場合は空の文字列
    */
    function getAccountName(uint _id) constant public returns(string _name) {
        if(_id > accountId)
            return "";
        return accounts[_id].name;
    }

    /**
    *  getAccountCount: 人マスタに登録されている人数を取得する
    *
    *  @return {uint} _count 人数
    */
    function getAccountCount() constant public returns(uint _count) {
        return accountId;
    }

    /**
    *  getAccountList: 人マスタに登録されている名前のリストを取得する
    *
    *  @return {string} _nameList 名前のリスト カンマ区切り
    */
    function getAccountList() constant public returns(string _nameList) {
        _nameList = "";
        for(uint i = 1; i <= accountId; i++) {
            if(i != 1) {
              _nameList = _nameList.toSlice().concat(",".toSlice());
            }
            _nameList = _nameList.toSlice().concat(accounts[i].name.toSlice());
        }
        return;
    }



    function kill () public {
        require (msg.sender == contractOwner);
        selfdestruct (contractOwner);
    }

    function () public payable {
        revert ();
    }

}


/**
* Rotas: 当番コントラクト
* 当番表を管理する
* structの連想配列 中身は↓を参照してください
*
*/
contract Rotas {
    address private contractOwner;
    uint toubanId;
    struct Touban{
        uint ownerId; // オーナーID この当番表を作った人のID
        string title; // 当番の名称
        string description; // 当番の説明
        uint rotaPointer; // 当番表のポインタ 当番表配列のこの添字の人が現在の担当者
        uint prevAccountId; // 一つ前の担当者 いない場合は０
        uint compTimestamp; // 一つ前の担当者が完了した日時 unixtime
        uint[] rota; // 当番表 人IDの配列
    }
    mapping(uint => Touban) toubanList;

    // コンストラクタ
    constructor() public{
        contractOwner = msg.sender;
    }

    /**
    *  createTouban: 当番を作成する
    *  注：オーナーIDの妥当性チェックはしていません
    *  オーナーは当番表に入れられる（最初はオーナー一人だけの当番になる）
    *
    *  @param _ownerId オーナーの人ID
    *  @param _title 当番の名称
    *  @param _description 当番の説明
    *  @return {uint} _toubanId 作成した当番ID
    */
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

    /**
    *  completion: 完了処理
    *  指定された当番IDを完了する：
    *    当番表のポインタを一つ進める。最後の人だった場合は最初に戻す。
    *    「前の担当者」に今の担当をセットする。「前の完了日時」に現在日時をセットする。
    *
    *  @param _toubanId 当番ID
    *  @return {uint} _nextAccountId 次に担当者になった人のID 当番IDが無効の場合は０
    */
    function completion(uint _toubanId) public returns(uint _nextAccountId) {
        if(_toubanId > toubanId)
          return 0;
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

    /**
    *  addRota: 指定した当番の当番表に人を追加する
    *  注：人IDの妥当性チェックはしていません
    *  指定された当番IDを完了する：
    *    当番表のポインタを一つ進める。最後の人だった場合は最初に戻す。
    *    「前の担当者」に今の担当をセットする。完了日時をセットする。
    *
    *  @param _toubanId 当番ID
    *  @param _Id 追加する人のID
    *  @return {uint} _idCount 当番表の人数 当番IDが無効の場合は０
    */
    function addRota(uint _toubanId, uint _Id) public returns(uint _idCount) {
        if(_toubanId > toubanId)
          return 0;
        toubanList[toubanId].rota.push(_Id);
        return toubanList[_toubanId].rota.length;
    }

    /**
    *  getDetail: 指定した当番の詳細を取得する
    *  人の名前を返すため、人コントラクトのアドレスが必要
    *
    *  @param _toubanId 当番ID
    *  @param _contractAddr 人コントラクトのアドレス
    *  @return {string} _title 当番の名称
    *  @return {string} _description 当番の説明
    *  @return {uint} _currentAccountId 現在の担当者のID
    *  @return {uint} _nextAccountId 次の担当者のID
    *  @return {uint} _prevAccountId 前の担当者のID 最初は０
    *  @return {uint} _compTimestamp 前の担当者が完了した日時 unixtime 最初は０
    *  @return {uint} _idCount 当番表の人数 当番IDが無効の場合は０
    *  @return {uint[]} _ids 当番表の人IDの配列
    *  @return {string} _currentName 現在の担当者の名前
    */
    function getDetail(uint _toubanId, address _contractAddr) constant public
        returns(string _title, string _description, uint _currentAccountId, uint _nextAccountId,
                  uint _prevAccountId, uint _compTimestamp, uint _idCount, uint[] _ids, string _currentName) {

        if(_toubanId > toubanId) {
          _idCount = 0;
          return;
        }

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

    /**
    *  getDetail: 作成済の当番の数を取得する
    *
    *  @return {uint} _count 現在存在する当番の数
    */
    function getRotaCount() constant public returns(uint _count) {
        return toubanId;
    }

    /**
    *  getMembers: 指定した当番の当番表に登録されている人のIDを配列で取得する
    *  注：当番IDの妥当性チェックをしていないので、取扱注意
    *
    *  @param _toubanId 当番ID
    *  @return {uint[]} _count 当番表の人IDの配列
    */
    function getMembers(uint _toubanId) constant public returns(uint[] _ids) {
        return toubanList[_toubanId].rota;
    }

    function kill () public {
        require (msg.sender == contractOwner);
        selfdestruct (contractOwner);
    }

    function () public payable {
        revert ();
    }

}
