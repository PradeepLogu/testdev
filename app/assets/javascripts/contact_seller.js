$(function() {
	$( "#dialog-contactseller" ).dialog({
		autoOpen: <%= params.nil? || params[:contact].blank? ? false : true %>,
		show: "blind",
		hide: "explode",
		width: "auto"
	});
});