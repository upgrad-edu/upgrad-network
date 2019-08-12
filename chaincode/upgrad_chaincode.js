
const shim = require('fabric-shim');
const util = require('util');

var Chaincode = class {
	async Init(stub) 
	{
		let ret = stub.getFunctionAndParameters();
		let params = ret.params;
		if (params.length !=2)
		{
			return shim.error("Incorrect number of arguments: function me h");
		}

		let Item1 = params[0];
		let Item1quantity = params[1];

		try{
			await stub.putState(Item1, Buffer.from(Item1quantity));
			return shim.success("success initiating the code");

		} catch(e){

			return shim.error(e);
		}

	}

	async Invoke(stub) {
		let ret = stub.getFunctionAndParameters();
		let params=ret.params;
		let fn = ret.fcn;
		if (fn === 'set'){
			var result = await this.setItemValues(stub, params);
			if (result)
				return shim.success("success");

		}
		else {
			var result = await this.getItemValues(stub, params);
			if (result)
				return shim.success("success invoking the code");
			else{
				return shim.success("Failed to get response");
			}
		}

	}

	async setItemValues(stub, args)
	{
		if (args.length !=2)
		{
			return shim.error("incorrect number of arguments");
		}
		try{
			return await stub.putState(args[0], Buffer.from(args[1]));

		} catch(e)
		{
			return shim.error(e);
		}
	}

	async getItemValues(stub, args)
	{

		if (args.length !=1)
		{
			return shim.error("incorrect number of arguments");
		}
		let jsonResp = {};
		let A=args[0];


		try {
			let Avalbytes = await stub.getState(A);
		    if (!Avalbytes) {
		      jsonResp.error = 'Failed to get state for ' + A;
		      throw new Error(JSON.stringify(jsonResp));
		    }

		    jsonResp.name = A;
		    jsonResp.amount = Avalbytes.toString();
		    console.info('Query Response:');
		    console.info(jsonResp);
			
			return await Avalbytes;

		} catch(e)
		{
			return shim.error(e);
		}

	}

}
	
shim.start(new Chaincode());













