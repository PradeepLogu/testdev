function connect_with_stripe(e) {
	// e.preventDefault();
	var $this = $(this);

	var modal = $("#dialog-stripe-info");
	modal.dialog({
		width: 500,
		modal: true
	});

    $('html, body').animate({
        scrollTop: $("#dialog-stripe-info").offset().top
    }, 50);

   	$('#terms_check').val(false);

	$("#stripeAccountToken").val("");
	$("#stripeTaxID").val("");
	$("#stripeBusinessName").val("");
	$("#stripeBusinessType").val("");

	return false;
};

var stripeResponseHandler = function(status, response) {
	if (response.error) {
		$("#stripe-fade").hide();
		alert(response.error.message);
	} else {
		var token = response.id;
		/* send the token to the server along with the withdraw request */
		$("#stripe-fade").hide();
		$("#dialog-stripe-info").dialog("close");

		$("#stripeAccountToken").val(token);
		$("#stripeTaxID").val($("input#taxID").val());
		$("#stripeBusinessName").val($("input#businessName").val());
		$("#stripeBusinessType").val($("select#businessType").val());
	}
};
