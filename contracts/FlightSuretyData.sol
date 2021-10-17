pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;
    using SafeMath for uint8;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    struct Airline {
        bool isRegistered;
        bool hasPayedFee;
        uint8 nrOfVotes;
    }
    mapping(address => Airline) private airlines;
    mapping(address => bool) private authorizedContracts;
    uint8 nrOfAirlines = 0;
    // Fee to be paid when registering oracle
    uint256 public constant AIRLINE_REGISTRATION_FEE = 10 ether;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    address firstAirline
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        Airline storage airline = airlines[firstAirline];
        airline.nrOfVotes = 1;
        airline.isRegistered = true;
        nrOfAirlines = 1;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireAuthorizedAirline()
    {
        bool isRegistered = airlines[msg.sender].isRegistered;
        bool hasPayedFee = airlines[msg.sender].hasPayedFee;
        require(isRegistered && hasPayedFee, "Airline is not registered or has not payed fee");
        _;
    }

    modifier requireFullPayment()
    {
        require(msg.value >= AIRLINE_REGISTRATION_FEE, "Must pay full airline registration fee");
        _;
    }

    modifier requireAuthorizedContract()
    {
        require(authorizedContracts[msg.sender] == true, "The calling address must be authorized");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    function isAuthorizedAirline(address _airline) public returns(bool)
    {
        bool isRegistered = airlines[_airline].isRegistered;
        bool hasPayedFee = airlines[_airline].hasPayedFee;
        return (isRegistered && hasPayedFee);
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (   
                                address _airline
                            )
                            public
                            requireIsOperational
                            requireAuthorizedContract
    {
        Airline storage airline = airlines[_airline];
        airline.nrOfVotes = uint8(airline.nrOfVotes.add(1));
        bool hasMPC = airline.nrOfVotes >= (nrOfAirlines / 2);
        if (nrOfAirlines < 4 || hasMPC) {
            airline.isRegistered = true;
            nrOfAirlines = uint8(nrOfAirlines.add(1));
        }
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                                address _airline
                            )
                            public
                            payable
                            requireIsOperational
                            requireFullPayment
    {
        address(this).transfer(msg.value);
        airlines[_airline].hasPayedFee = true;
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    function isAirline(address _airline) view public returns(bool)
    {
        return airlines[_airline].isRegistered;
    }

    function hasPayedAirlineFee(address _airline) view public returns(bool)
    {
        return airlines[_airline].hasPayedFee;
    }

    function authorizeContract(address _contract) public requireContractOwner
    {
        authorizedContracts[_contract] = true;
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
    }


}

