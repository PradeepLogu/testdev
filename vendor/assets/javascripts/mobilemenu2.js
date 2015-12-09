$(function() {
	var pull 		= $('#pull');
		menu 		= $('#header-inner-nav2 ul');
		menuHeight	= menu.height();

	$(pull).on('click', function(e) {
		e.preventDefault();
		//e.stopPropagation();
		menu.slideToggle();
	});
	//$("html").on('click', function (e) {
	// menu.slideUp();
	// });
	$(window).resize(function(){
		var w = $(window).width();
		if(w > 320 && menu.is(':hidden')) {
			menu.removeAttr('style');
		}
	});
});