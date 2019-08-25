'use strict';

const State = require('./../../ledger-api/state');

class Course extends State {
	
	/**
	 * Constructor function
	 * @param courseObject
	 */
	constructor(courseObject) {
		super(Course.getClass(), [courseObject.courseId]);
		Object.assign(this, courseObject);
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
	 * Get class of this course
	 * @returns {string}
	 */
	static getClass() {
		return 'org.upgrad-network.edtech.assets.course';
	}
	
	/**
	 * Convert the buffer stream received from blockchain into an object of type Course
	 * @param buffer {Buffer}
	 */
	static fromBuffer(buffer) {
		return Course.deserialize(Buffer.from(JSON.parse(buffer.toString())));
	}
	
	/**
	 * Convert the object of type Course to a buffer stream
	 * @returns {Buffer}
	 */
	toBuffer() {
		return Buffer.from(JSON.stringify(this));
	}
	
	/**
	 * Convert the buffer steam into an object of type Course
	 * @param data {Buffer}
	 */
	static deserialize(data) {
		return Course.deserializeClass(data, Course);
	}
	
	/**
	 * Create a new instance of this course
	 * @returns {Course}
	 * @param courseObject {Object}
	 */
	static createInstance(courseObject) {
		return new Course(courseObject);
	}
	
}

module.exports = Course;