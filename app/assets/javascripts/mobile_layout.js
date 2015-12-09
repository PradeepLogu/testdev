var addMobileLayoutConverter;

(function($){
	var _oldwidth = 1100;			//Initialize with the layout's max desktop width.
	var onMobileFunctions = [];
	var onDesktopFunctions = [];

	addMobileLayoutConverter = function (on_mobile, on_desktop) {
		if ((typeof on_desktop == "function") && (typeof on_mobile == "function")) {
			onMobileFunctions.push(on_mobile);
			onDesktopFunctions.push(on_desktop);
		}
	};

	$(function() {
		$(window).resize(function() {
			var width = $(window).width();
			
			if (_oldwidth >= 768 && width < 768) {
				var len = onMobileFunctions.length;
				for(var i = 0; i < len; i++) {
					onMobileFunctions[i](width);
				}
			}
			else if (_oldwidth < 768 && width >= 768) {
				var len = onDesktopFunctions.length;
				for(var i = 0; i < len; i++) {
					onDesktopFunctions[i](width);
				}
			}
			
			_oldwidth = width;
		})
		.resize();		//Trigger initial restructuring
	});
})(jQuery);
