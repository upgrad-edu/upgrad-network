'use strict';

const {Contract, Context} = require('fabric-contract-api');

const User = require('./participants/user.js');
const UserList = require('./participants/userlist.js');

class EdTechContext extends Context {
	constructor() {
		super();
		// Add various legder lists to the custom context
		this.userList = new UserList(this);
	}
}

class EdTechContract extends Contract {
	
	constructor() {
		// Provide a custom name to refer to this smart contract
		super('org.upgrad-network.edtech');
	}
	
	// Built in method used to build and return the context for this smart contract
	createContext() {
		return new EdTechContext();
	}
	
	/* ****** All custom functions are defined below ***** */
	
	// This is a basic user defined function used at the time of instantiating the smart contract
	// to print the success message on console
	async instantiate(ctx) {
		console.log('EdTech Smart Contract Instantiated');
	}
	
	async createUser(ctx, userId, fname, lname, email) {
		let msgSender = ctx.clientIdentity.getAttributeValue('CN');
		let userKey = User.makeKey([userId]);
		let user = await ctx.userList
				.getUser(userKey)
				.catch(err => console.log(err));
		
		if (user !== undefined) {
			throw new Error('Invalid User ID: ' + userId + '. A user with this ID already exists.');
		} else {
			let newUser = User.createInstance(userId, fname, lname, email);
			newUser.setCurrentState('CREATED');
			await ctx.userList.addUser(newUser);
			return newUser.toBuffer();
		}
	}
}

module.exports = EdTechContract;