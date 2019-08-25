'use strict';

const {Contract, Context} = require('fabric-contract-api');

// Fetch asset & participant classes
const User = require('./participants/user.js');
const UserList = require('./participants/userlist.js');
const Course = require('./assets/course');
const CourseList = require('./assets/courselist');

class EdTechContext extends Context {
	constructor() {
		super();
		// Add various legder lists to the custom context
		this.userList = new UserList(this);
		this.courseList = new CourseList(this);
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
		let msgSender = ctx.clientIdentity.getID();
		let userKey = User.makeKey([userId]);
		let user = await ctx.userList
				.getUser(userKey)
				.catch(err => console.log(err));
		
		if (user !== undefined) {
			throw new Error('Invalid User ID: ' + userId + '. A user with this ID already exists.');
		} else {
			let userObject = {
				userId: userId,
				fname: fname,
				lname: lname,
				email: email,
				owner: msgSender,
				gyan: 0,                // initialize the Gyan score to 0
				courses: {},            // initialize the list of courses
				badges: {},             // initialize the list of badges
				scholarships: {},       // initialize the list of scholarships
				createdAt: new Date(),
				updatedAt: new Date(),
			};
			let newUser = User.createInstance(userObject);
			newUser.setCurrentState('CREATED');
			await ctx.userList.addUser(newUser);
			return newUser.toBuffer();
		}
	}
	
	async createCourse(ctx, courseId, title, description, teacherId, topics) {
		let msgSender = ctx.clientIdentity.getID();
		let courseKey = Course.makeKey([courseId]);
		let course = await ctx.courseList
				.getCourse(courseKey)
				.catch(err => console.log(err));
		
		if (course !== undefined) {
			throw new Error('Invalid Course ID: ' + courseId + '. A course with this ID already exists.');
		} else {
			let courseObject = {
				courseId: courseId,
				title: title,
				description: description,
				teacherId: teacherId,
				topics: topics,
				owner: msgSender,
				createdAt: new Date(),
				updatedAt: new Date(),
			};
			let newCourse = Course.createInstance(courseObject);
			newCourse.setCurrentState('CREATED');
			await ctx.courseList.addCourse(newCourse);
			return newCourse.toBuffer();
		}
	}
	
	async joinCourse(ctx, userId, courseId) {
		let msgSender = ctx.clientIdentity.getID();
		let userKey = User.makeKey([userId]);
		let user = await ctx.userList
				.getUser(userKey)
				.catch(err => console.log(err));
		
		// Check if the user exists with this ID
		if (user === undefined) {
			throw new Error('Invalid User ID: ' + userId + '. No such user.');
		} else {
			// Add this course to the user's list of courses
			user.courses[courseId] = {
				joinDate: new Date(),
				joinedFrom: msgSender,
				activities: [],
			};
			await ctx.userList.updateUser(user);
			return user.toBuffer();
		}
	}
}

module.exports = EdTechContract;