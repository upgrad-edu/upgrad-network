'use strict';

/**
 * This is a Node.JS application to add a new user on the network sourced by Amazon.
 * Defaults:
 * UserId: 1234
 * fname: Aakash
 * lname: Bansal
 * Email: connect@aakashbansal.com
 */

const fs = require('fs');
const yaml = require('js-yaml');
const { FileSystemWallet, Gateway } = require('fabric-network');
const User = require('../chaincode/lib/participants/user');

// A wallet stores a collection of identities for use.
// An identity for user Aakash was initially added to this wallet.
const wallet = new FileSystemWallet('../identity/amazon');

async function main() {
	
	// A gateway defines which peers is used to access Fabric networks
	// It uses a common connection profile (CCP) to connect to a Fabric Peer
	// A CCP is defined manually in the Gateway folder
	const gateway = new Gateway();
	
	try {
		
		// Specify userName for network access
		const userName = 'Admin@amazon.upgrad-network.com';
		
		// Load connection profile; will be used to locate a gateway; The CCP is converted from YAML to JSON.
		let connectionProfile = yaml.safeLoad(fs.readFileSync('../gateway/networkConnection.yaml', 'utf8'));
		
		// Set connection options; identity and wallet
		let connectionOptions = {
			wallet: wallet,
			identity: userName,
			discovery: { enabled: false, asLocalhost: true }
		};
		
		// Connect to gateway using specified parameters
		console.log('Connecting to Fabric Gateway');
		await gateway.connect(connectionProfile, connectionOptions);
		
		// Access reliancesupplychain network
		console.log('Use network channel: channelthreeorgs');
		const network = await gateway.getNetwork('channelthreeorgs');
		
		// Get instance of deployed Supply Chain contract
		// @param Name of chaincode
		// @param Name of smart contract
		console.log('Use org.upgrad-network.edtech smart contract..');
		const contract = await network.getContract('edtech', 'org.upgrad-network.edtech');
		
		// Add a new user on the network from this organization. This participant will take the role of a shipper, exporter or buyer
		console.log('Create a new user sourced by Amazon..');
		const userResponse = await contract.submitTransaction('createUser', '12345', 'Shruti', 'Bansal', 'shruti@aakashbansal.com');
		
		// process response
		console.log('Processing create user transaction response..');
		let user = User.fromBuffer(userResponse);
		console.log(user);
		console.log('Create User Transaction complete.');
		
	} catch (error) {
		
		console.log(`Error processing transaction. ${error}`);
		console.log(error.stack);
		
	} finally {
		
		// Disconnect from the gateway
		console.log('Disconnecting from Fabric Gateway.');
		gateway.disconnect();
		
	}
}
main().then(() => {
	
	console.log('Create User program complete.');
	
}).catch((e) => {
	
	console.log('Create User program exception.');
	console.log(e);
	console.log(e.stack);
	process.exit(-1);
	
});