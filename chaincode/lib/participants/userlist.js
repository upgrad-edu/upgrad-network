'use strict';

const StateList = require('./../../ledger-api/statelist.js');
const User = require('./user.js');

class UserList extends StateList{
	
	constructor(ctx) {
		super(ctx, 'org.upgrad-network.edtech.participants.userlist');
		this.use(User);
	}
	
	async getUser(userKey) {
		return this.getState(userKey);
	}
	
	async addUser(user) {
		return this.addState(user);
	}
}

module.exports = UserList;