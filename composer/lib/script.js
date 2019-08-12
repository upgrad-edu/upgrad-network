/**
 * Track the trade of a commodity from one trader to another
 * @param {org.upgrad.network.TransferCommodity} tx The trade to be processed
 * @returns {org.upgrad.network.Trader} The trader from query
 * @transaction
 */
async function transferCommodity (tx) {
	console.log(tx);
	// Define factory and transaction initiator variables.
	let NS = 'org.upgrad.network';
	let me = getCurrentParticipant();
	
	// Set new values for commodity based on the input arguments.
	tx.commodity.issuer = me;
	tx.commodity.owner = tx.newOwner;
	tx.commodity.purchaseOrder = tx.purchaseOrder;
	
	// Create a new trace entry
	let newTrace = getFactory().newConcept(NS, 'Trace');
	newTrace.timestamp = new Date();
	newTrace.location = tx.shipperLocation;
	newTrace.company = me;
	// Add it to the commodity instance
	tx.commodity.trace.push(newTrace);
	
	// Update the Commodity registry with the new commodity value.
	let assetRegistry = await getAssetRegistry('org.upgrad.network.Commodity');
	await assetRegistry.update(tx.commodity);
}

/**
 * Initiate PO from one trader to another
 * @param {org.upgrad.network.InitiatePO} tx - the InitiatePO to be processed
 * @transaction
 */
async function initiatePurchaseOrder (tx) {
	console.log(tx);
	// Define factory and transaction initiator variables.
	let NS = 'org.upgrad.network';
	let me = getCurrentParticipant();
	
	// Create a new PO instance and update its values
	let order = getFactory().newResource(NS, 'PO', tx.orderId);
	order.itemList = tx.itemList;
	if (tx.orderTotalPrice) {
		order.orderTotalPrice = tx.orderTotalPrice;
	}
	order.orderStatus = 'INITIATED';
	order.orderer = me;
	order.vendor = tx.vendor;
	
	// Fetch trader from query
	let result = await query('fetchTrader', { companyName: 'Tata Motors' });
	console.log(result);
	// Add the new PO to registry
	let assetRegistry = await getAssetRegistry(order.getFullyQualifiedType());
	await assetRegistry.add(order);
	return result;
}