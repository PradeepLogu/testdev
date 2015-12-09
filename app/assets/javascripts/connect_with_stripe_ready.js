function stripe_ready(jQuery) {
	$('#terms_check').val(false);

	$('#terms_check').change(function() {
		if(!$(this).is(':checked')){
			$('#submit_button').attr("disabled","disabled");   
			$('#submit_button').addClass("btn-disable");
		} else {
			$('#submit_button').removeAttr('disabled');
			$('#submit_button').removeClass("btn-disable");
		}
	});

	$('#submit_button').click(function() {
		$("#stripe-fade").show();
		try {
			Stripe.bankAccount.createToken({
					country: "US",
					currency: "USD",
				routing_number: $('input#routingNumber').val(),
				account_number: $('input#accountNumber').val()
			}, stripeResponseHandler);
		} catch(e) {
			alert(e);
			$("#stripe-fade").hide();
		}
	});
};