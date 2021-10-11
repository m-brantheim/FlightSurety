
const Test = require('../config/testConfig.js');
const BigNumber = require('bignumber.js');
const Web3 = require('web3');

contract('Flight Surety Tests', async (accounts) => {

  let config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    // await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    const status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('first airline is registered when contract is deployed', async () => {

    // ARRANGE
    // do nothing

    // ACT
    const result = await config.flightSuretyData.isAirline.call(config.firstAirline); 

    // ASSERT
    assert.equal(result, true, "First airline is not registered when contract is deployed");

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    const newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    const result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) can register an Airline using registerAirline() if it is funded', async () => {
    
    // ARRANGE
    const newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.depositRegistrationFee({ from: config.firstAirline, value: Web3.utils.toWei("10", "ether") });
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    const result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, true, "Airline should be able to register another airline if it has provided funding");

  });

  it('Up to 4 airlines can be registered without voting', async () => {
    
    // ARRANGE
    const thirdAirline = accounts[3];
    const fourthAirline = accounts[4];
    const fifthAirline = accounts[5];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(thirdAirline, {from: config.firstAirline});
        await config.flightSuretyApp.registerAirline(fourthAirline, {from: config.firstAirline});
        await config.flightSuretyApp.registerAirline(fifthAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    const thirdResult = await config.flightSuretyData.isAirline.call(thirdAirline); 
    const fourthResult = await config.flightSuretyData.isAirline.call(fourthAirline); 
    const fifthResult = await config.flightSuretyData.isAirline.call(fifthAirline); 

    // ASSERT
    assert.equal(thirdResult, true, "Airline should be able to register another airline if it has provided funding");
    assert.equal(fourthResult, true, "Airline should be able to register another airline if it has provided funding");
    assert.equal(fifthResult, false, "The fifth airline should not be registered directly without voting");
  });
});
