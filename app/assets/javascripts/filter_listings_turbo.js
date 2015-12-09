var fJS;
var showAllListings = false;

function filterInit(){

    var tirelistings;
    var settings = initSettings();

    var ts = new Date().getTime() / 1000;
    tirelistings = initTireListings();
    x =  FilterJS(tirelistings, "#tirelistings_list", null, settings);
    var ts2 = new Date().getTime() / 1000;
    // console.log("FilterJS took " + (ts2 - ts).toString() + " seconds");

    return x;
}

function bindLiveEvents() {
    $("div.infographic").hover(
        function (event) {
            $.ajax({url:"/tire_listings/ajax/" + event.target.id,success:function(result){
                document.getElementById(event.target.id).getElementsByTagName('span')[0].innerHTML = result;
            }});
        }
    );
    $('.listing-detail div').click(function (event) {
        if ($(this).attr('id').substr(0, 8) == 'list_id_') {
            var listing_id = $(this).attr('id').substr(8);
            var path = '/tire_listings/' + listing_id;
            window.open(path, '_self', false); 
        };
    });

    $('#tire_manufacturer_all, #tire_store_all, #quantities_all, #wheelsizes_all, #seller_types_all, #tire_category_all').closest('ul').children().find(':checkbox').attr('checked', true);
    $('#tire_manufacturer_all, #tire_store_all, #quantities_all, #wheelsizes_all, #seller_types_all, #tire_category_all').click(function(){
        $(this).closest('ul').children().find(':checkbox').attr('checked', $(this).is(':checked'));
    });
}

$(document).ready(function() {
    window.scrollTo(0, 0);

    if (fJS == null) {
        fJS = filterInit(); 
        bindLiveEvents();  
    };
});