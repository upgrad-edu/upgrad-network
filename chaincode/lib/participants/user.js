'use strict';

const State = require('./../../ledger-api/state');

class User extends State {
	
	constructor(userObject) {
		super(User.getClass(), [userObject.userId]);
		Object.assign(this, userObject);
	}
	
	// Getters and Setters
	setCurrentState(newState) {
		this.currentState = newState;
	}
	
	// Helper Functions
	
	/**
	 * Get class of this participant
	 * @returns {string}
	 */
	static getClass() {
		return 'org.upgrad-network.edtech.participants.user';
	}
	
	/**
	 * Convert the buffer stream received from blockchain into an object of type User
	 * @param buffer
	 */
	static fromBuffer(buffer) {
		return User.deserialize(Buffer.from(JSON.parse(buffer)));
	}
	
	/**
	 * Convert the object of type User to a buffer stream
	 * @returns {Buffer}
	 */
	toBuffer() {
		return Buffer.from(JSON.stringify(this));
	}
	
	/**
	 * Convert the buffer steam into an object of type User
	 * @param data
	 */
	static deserialize(data) {
		return User.deserializeClass(data, User);
	}
	
	/**
	 * Create a new instance of this participant
	 * @param userId
	 * @param fname
	 * @param lname
	 * @param email
	 * @returns {User}
	 */
	static createInstance(userId, fname, lname, email) {
		return new User({userId, fname, lname, email});
	}
}

module.exports = User;