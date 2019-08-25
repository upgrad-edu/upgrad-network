'use strict';

const StateList = require('./../../ledger-api/statelist.js');
const Course = require('./course');

class CourseList extends StateList{
	
	constructor(ctx) {
		super(ctx, 'org.upgrad-network.edtech.assets.courselist');
		this.use(Course);
	}
	
	async getCourse(userKey) {
		return this.getState(userKey);
	}
	
	async addCourse(user) {
		return this.addState(user);
	}
	
	async updateCourse(course) {
		return this.updateState(course);
	}
}

module.exports = CourseList;