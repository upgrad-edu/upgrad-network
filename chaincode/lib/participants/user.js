'use strict';

const State = require('./../../ledger-api/state');

class User extends State {
	
	/**
	 * Constructor function
	 * @param userObject {Object}
	 */
	constructor(userObject) {
		super(User.getClass(), [userObject.userId]);
		Object.assign(this, userObject);
	}
	
	// Getters and Setters
	
	/**
	 * Set the value of currentState
	 * @param newState {String}
	 */
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
	 * @param buffer {Buffer}
	 */
	static fromBuffer(buffer) {
		return User.deserialize(Buffer.from(JSON.parse(buffer.toString())));
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
	 * @param data {Buffer}
	 */
	static deserialize(data) {
		return User.deserializeClass(data, User);
	}
	
	/**
	 * Create a new instance of this participant
	 * @returns {User}
	 * @param userObject {Object}
	 */
	static createInstance(userObject) {
		return new User(userObject);
	}
	
}

module.exports = User;