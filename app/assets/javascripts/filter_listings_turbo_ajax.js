var showAllListings = false;

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
}

$(document).ready(function() {
    window.scrollTo(0, 0);
    bindLiveEvents();
});