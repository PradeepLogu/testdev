var cur_store_visible_name = '';
var last_known_result = null;

var compressNodes;
var curCompressedNode;

var filter_callbacks = {
	deleteExistingCompressed: function(result) {
		deleteCompressedNodes();
	},

	compressListings: function(result) {
		last_known_result = result;
		createCompressedNodes(result);
	}
};

function toggleStoreDisplay(e) {
	// e.parent().parent().parent() returns a compressed-store-node.  His next sibling
	// should be our compressed-node
	e.parent().parent().parent().next().slideToggle('fast'); 
	if (e.context.innerText.indexOf('expand') >= 0) {
		e.context.innerHTML = (e.context.innerHTML.replace('expand', 'contract'));
		e.context.innerHTML = (e.context.innerHTML.replace('see_more', 'see_less'));
	} else { 
		e.context.innerHTML = (e.context.innerHTML.replace('contract', 'expand'));
		e.context.innerHTML = (e.context.innerHTML.replace('see_less', 'see_more'));
	};
}(jQuery);

function deleteCompressedNodes() {
	existingNodes = document.getElementsByClassName('compressed-node');
	for (i=0; i < existingNodes.length; i++) {
		// reparent the child nodes, these should all be listings
		for (j=0; j < existingNodes[i].childNodes.length; j++) {
			document.getElementById('tirelistings_list').insertBefore(existingNodes[i].childNodes[j], existingNodes[i]);
		}
	}

	// now delete the compressed-nodes themselves.  For whatever reason, this
	// doesn't work properly when inside the previous loop.  Sigh....
	deleteAllByClassName('compressed-node');
	deleteAllByClassName('compressed-store-node');
}

function deleteAllByClassName(className) {
	existingNodes = document.getElementsByClassName(className);
	while (existingNodes.length > 0) {
		existingNodes[0].parentNode.removeChild(existingNodes[0]);
		existingNodes = document.getElementsByClassName(className);
	}
}

function createCompressedNodes(result) {
	curCompressedNode = null;
	compressNodes = new Array()

	// create initial compress
	$.each(result, function(i,v) {
		createCompressibleNodeArray(v);
	});

	// make sure the last one gets added to the array if applicable
	if (isCompressible(curCompressedNode))
		compressNodes.push(curCompressedNode);

	var listings = document.getElementsByClassName("results-item");
	var curListingNode;

	for (i=0; i < listings.length; i++) {
		// Check if node is hidden through filtering.
		if (window.getComputedStyle(listings[i].parentNode, null).getPropertyValue('display') != 'none') {
			var listing_id = listings[i].parentNode.id.replace('tire_listing_', '');
			for (j=0; j < compressNodes.length; j++) {
				if (compressNodes[j].compressedNodes[0].id == listing_id)
				{
					// toggle link is created by AJAX now since it's too big for javascript	
					var toggleDiv, ajaxDiv;
					curListingNode = listings[i];
					curCompressNode = compressNodes[j];

		            $.ajax({url:"/ajax/build_store_placeholder/?distance=" + listings[i].childNodes[2].childNodes[3].innerText + "&tire_listing_ids=" + compressNodes[j].listing_ids.toString(),success:function(result) {	
						// Need to insert our compressible node here.
						toggleDiv = document.createElement("div");
						toggleDiv.setAttribute('class', 'compressed-node');

						ajaxDiv = document.createElement('div');
						ajaxDiv.setAttribute('class', 'compressed-store-node');
		            	ajaxDiv.innerHTML = result;
		            }, async: false});
		            // now we need to put all listings in compressedNodes
					// as children of our new node
					for (k=0; k < curCompressNode.compressedNodes.length; k++) {
						listingNode = document.getElementById('tire_listing_' + curCompressNode.compressedNodes[k].id);
						if (listingNode != null) {
							toggleDiv.appendChild(listingNode);
						}
					};

					// Finally, we need to put our ajaxDiv and our toggleDiv, which represent the new
					// compressed store node, into the document.
					if (listings[i] && listings[i].parentNode && listings[i].parentNode.parentNode) {
						listings[i].parentNode.parentNode.insertBefore(ajaxDiv, listings[i].parentNode);
			            listings[i].parentNode.parentNode.insertBefore(toggleDiv, listings[i].parentNode);
			        }
			        else {
			        	// this seems to happen when the last node is a compressed node.
			        	var rootElement = document.getElementById('tirelistings_list');
			        	rootElement.insertBefore(ajaxDiv, rootElement.lastChild);
			        	rootElement.insertBefore(toggleDiv, rootElement.lastChild);
			        }
				}
			}
		}
	}
}

function createCompressibleNodeArray(tire_listing) {
	if (!tire_listing.private_seller) {
		if (curCompressedNode == null) {
			// create a new one
			curCompressedNode = new Object();
			curCompressedNode.tire_store = tire_listing.tire_store;
			curCompressedNode.compressedNodes = new Array;
			curCompressedNode.compressedNodes.push(tire_listing);
			curCompressedNode.listing_ids = new Array;
			curCompressedNode.listing_ids.push(tire_listing.id);
		}
		else {
			// is this the same store?
			if (curCompressedNode.tire_store.id == tire_listing.tire_store.id) {
				curCompressedNode.compressedNodes.push(tire_listing);
				curCompressedNode.listing_ids.push(tire_listing.id);
			}
			else {
				// need to add to grand list if applicable
				if (isCompressible(curCompressedNode))
				{
					compressNodes.push(curCompressedNode);
				}
				curCompressedNode = new Object();
				curCompressedNode.tire_store = tire_listing.tire_store;
				curCompressedNode.compressedNodes = new Array;
				curCompressedNode.compressedNodes.push(tire_listing);
				curCompressedNode.listing_ids = new Array;
				curCompressedNode.listing_ids.push(tire_listing.id);
			}
		}
	}
}

function isCompressible(compressedNode)
{
	if (compressedNode != null) {
		if (compressedNode.compressedNodes.length > 3)
			return true;
		else
			return false;
	}
}
