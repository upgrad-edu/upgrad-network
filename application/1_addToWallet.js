'use strict';

/**
 * This is a Node.JS module to load a user's Identity to his wallet.
 * This Identity will be used to sign transactions initiated by this user.
 * Defaults:
 *  User Name: Admin
 *  User Organization: Amazon
 *  User Role: Admin
 *
 */

const fs = require('fs'); // FileSystem Library
const { FileSystemWallet, X509WalletMixin } = require('fabric-network'); // Wallet Library provided by Fabric
const path = require('path'); // Support library to build filesystem paths in NodeJs

const fixtures = path.resolve(__dirname, '../'); // Directory where all Network artifacts are stored

// A wallet stores a collection of Identities
const wallet = new FileSystemWallet('../identity/amazon');

async function main() {
	
	// Main try/catch block
	try {
		
		// Fetch the credentials from our previously generated Crypto Materials required to create this user's identity
		const credPath = path.join(fixtures, '/crypto-config/peerOrganizations/amazon.upgrad-network.com/users/Admin@amazon.upgrad-network.com');
		const cert = fs.readFileSync(path.join(credPath, '/msp/signcerts/Admin@amazon.upgrad-network.com-cert.pem')).toString();
		const key = fs.readFileSync(path.join(credPath, '/msp/keystore/af30f29edc31aa602c35da37b486d4faa762debd1a093b5c334d0e779bc42743_sk')).toString();
		
		// Load credentials into wallet
		const identityLabel = 'Admin@amazon.upgrad-network.com';
		const identity = X509WalletMixin.createIdentity('AmazonMSP', cert, key);
		
		await wallet.import(identityLabel, identity);
		
	} catch (error) {
		console.log(`Error adding to wallet. ${error}`);
		console.log(error.stack);
	}
}

main().then(() => {
	console.log('Added a new Identity for Admin user Aakash in Amazon\'s wallet.');
}).catch((e) => {
	console.log(e);
	console.log(e.stack);
	process.exit(-1);
});