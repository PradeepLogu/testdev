(function ($) {
  "use strict";

  $.fn.embedyt = function (youid) {
    var htm = '<div class="divvid" id="player' + youid + '"' + ' style="background-image:url(' + 
      '/assets/image.png' + ');' + 'width:320px;height:180px;text-align:center;line-height:180px;' +  '">' + 
      '<img class="imgvid" src="/assets/' + youid + '.png" style="cursor:pointer" width="320" height="180">' + 
      '<div id="banner-overlay">Click to View</div></img></div>';
    this.html(htm);
    this.find("div.divvid").bind('click', function () {
      var ifhtml = '<iframe width="320" height="180" src="http://www.youtube.com/embed/' + youid + 
          '?autoplay=1" frameborder="0" allowfullscreen></iframe>';
      jQuery(this).css("cursor", "progress");
      jQuery(this).parent().parent().html(ifhtml);
    });
  };

}(jQuery));

jQuery(function () {
  jQuery("div.youtubeembed").each(function (index) {
    jQuery(this).embedyt(jQuery(this).attr('id'));
  });
});