$(function() {
  $( "#dialog-sizesearch" ).dialog({
    autoOpen: <%= params.nil? || params[:contact].blank? ? false : true %>,
    show: "blind",
    hide: "explode",
    position: ['left', 0],
    width: "auto"
  });
});

$(document).ready(function() {
  $(".tabSizeLink").each(function(){
    $(this).click(function(){
      tabId = $(this).attr('id');
      if (tabId == "tb-1")
        otherTabId = "tb-2";
      else
        otherTabId = "tb-1";
      $(".tabSizeLink").removeClass("activeLink");
      $(this).addClass("activeLink");
      $(".tabcontent").addClass("hide");
      $("#"+tabId+"-1").removeClass("hide");

      copy_radio_value_between_tabs(otherTabId, tabId, "new_or_used");
      
      return false;   
    });
  }); 
});

function copy_radio_value_between_tabs(source_tabId, dest_tabId, element_selector) {
  var sourceValue = $('#'+source_tabId+"-1").find("a[rel='tire_search[" + element_selector + "]'][class~='jqTransformChecked']").next('input').val();
  var destOldChecked = $('#'+dest_tabId+"-1").find("a[rel='tire_search[" + element_selector + "]'][class~='jqTransformChecked']");
  destOldChecked.removeClass('jqTransformChecked');

  var destNewChecked = $('#'+dest_tabId+"-1").find("input#" + element_selector + "[value=" + sourceValue + "]");
  destNewChecked.prev('a').click();
}