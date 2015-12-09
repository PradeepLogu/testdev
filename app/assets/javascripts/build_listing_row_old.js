var view = function(tirelisting){
    ///////////////////
    tire_manufacturer_name = this.span({'class': 'name'}, tirelisting.tire_manufacturer.name);
    tire_model = this.div({'class': 'name'}, 
                        tirelisting.tire_model == null ? '' : tirelisting.tire_model.name);
    pic = this.div({}, 
                        ((tirelisting.photo1_thumbnail == null ? '' : 
                            '<img src="' + tirelisting.photo1_thumbnail + '">')));
    tire_manu_column = this.div({'class': 'manufacturer'}, 
                    [tire_manufacturer_name,
                     '<img src="/assets/' + tirelisting.tire_manufacturer.name + '.gif" border="0"/>',
                     tire_model,
                     pic]);
    ///////////////////
    if (tirelisting.tire_category == null) {
        tire_category_column = this.div({'class': 'category-type'}, 'n/a');
    }
    else {
        tire_category_column = this.div({'class': 'category-type'},
                            tirelisting.tire_category.category_name);
    }
    ///////////////////
    if (typeof tirelisting.tire_size != 'undefined') {
        tire_size_column = this.div({'class': 'tire-size'}, tirelisting.tire_size.sizestr);
    }
    else
        tire_size_column = this.div({'class': 'tire-size'}, '&nbsp;');

    ///////////////////
    qty_column = this.div({'class': 'quantity'}, tirelisting.quantity);
    ///////////////////
    if (tirelisting.is_new == true) {
        new_image = '<img src="/assets/new_icon.png">';
        // treadlife_hidden_value = '<font style="visibility: hidden; width:0px; float:left;">100</font>';
        treadlife_column = this.div({'class': 'treadlife'}, new_image);
        treadlife_value = '100';
    }
    else {
        if (tirelisting.treadlife == null) {
            // for sorting purposes so undefined doesn't sort to the top
            treadlife_column = this.div({'class': 'treadlife', 'style': 'visibility:hidden;'}, '0');
            treadlife_value = '0';
        }
        else {
            treadlife_column = this.div({'class': 'treadlife'}, 
                            ((tirelisting.treadlife == null ? '&nbsp;' : tirelisting.treadlife + '%')));
            treadlife_value = tirelisting.treadlife;
        }
    }
    ///////////////////


    price = this.span({'class': 'price-data'}, '$' + tirelisting.formatted_price)
    price_column = this.div({'class': 'price'},
                            [price, '<br />',
                    ((tirelisting.includes_mounting) ? '' : '<font size="1"> (inc. mounting)</font> ')]);
    ///////////////////
    if (typeof tirelisting.tire_store != 'undefined') {
        logo = this.div({}, 
                            ((tirelisting.logo_thumbnail == null ? '' : 
                                '<img src="' + tirelisting.logo_thumbnail + '">')));
        store_column = this.div({'class': 'store'}, 
                                ['<a href="/tire-stores/' + tirelisting.store_to_param + '">' + 
                                    tirelisting.store_visible_name  + '</a>',
                                    logo]);
        ///////////////////
        distance_column = this.div({'class': 'dist'}, 
                                Math.round(tirelisting.distance) +
                                 ((Math.round(tirelisting.distance) == 1) ? " mile" : " miles"));
    }
    ///////////////////


    //privateinfo = this.div({'class': 'span1'},
    //                    [tirelisting.tire_store.private_seller ? '<img src="/assets/check.png">' : ''])

    moreinfo = this.div({'class': 'span1 more-info', 'id': 'l_' + tirelisting.id});

    divclear = this.div({'class': 'clear'});

    infographic = this.div({'class': 'infographic', 'id': 'l_' + tirelisting.id},
                                '<span><div><h3 class="orange">Loading...</h3></div></span>');

    hidden_treadlife_value = '<div class="hidden-treadlife" style="visibility: hidden; width:0px; float:left;">' + treadlife_value + '</div>'

    ///////////////////

    if (tirelisting.tire_store == null)
        complete_row = this.div({'id': 'results-item'},
                        [tire_manu_column, qty_column, tire_size_column,
                        tire_category_column, treadlife_column, price_column, 
                        infographic, hidden_treadlife_value, divclear])
    else
        complete_row = this.div({'id': 'results-item'},
                        [tire_manu_column, qty_column, tire_category_column, 
                        treadlife_column, price_column, 
                        store_column, distance_column, 
                        infographic, hidden_treadlife_value, divclear]);
    return this.link('/tire_listings/' + tirelisting.id,
        {'id': tirelisting.id}, 
        complete_row);
};