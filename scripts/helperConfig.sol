//SPDX-License-Identifier : MIT
pragma solidity^0.8.9;


error helpferConfig_incorrectChain();

contract helperConfig {
    
    uint256 public constant ETH_SAP_ID = 11155111; 
    uint256 public constant LOCAL_ID = 31337; 

    struct params{
        address  vrfCordinator;
        uint32  _callBackGas;
        bytes32 _keyhash;
        uint256 _subId;
    };


//    params public parameters; 

    mapping(uint256 chainID => params) public networkConfiguration;
    

    constructor(){
        networkConfiguration[ETH_SAP_ID] = sapETH();
    }

    function decideConfiguration(uint256 ChainID) public view returns (params memory){
        if(networkConfiguration[ChainID].vrfCordinator != address(0)){
            return etworkConfiguration[ChainID];
        }else if(ChainID==LOCAL_ID){
            return AnvilCnfiguration();
        }else{
            revert helpferConfig_incorrectChain();
        }
    }


    function sapEth() public view returns(params memory){
        return params({
            vrfCordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            _callBackGas = 50000,
            _keyhash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            _subId = 0
        });
    }




    function AnvilConfiguration() public view returns(params memory){
        //will return me local chain configuration
    }

}