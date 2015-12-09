var view = function(tirelisting) {
    var complete_row;
    var divclear = this.div({'class': 'clear'});

    if (tirelisting.is_generic == false) {
        ///////////////////
        tire_manufacturer_name = this.span({'class': 'manu-name'}, tirelisting.tire_manufacturer_name);
        tire_model = this.div({'class': 'model-name'}, 
                            tirelisting.tire_model_name == null ? '' : tirelisting.tire_model_name);
        if (tirelisting.tire_category == null) {
            tire_category = this.div({'class': 'category-type'}, '');
        }
        else {
            tire_category = this.div({'class': 'category-type'},
                                tirelisting.tire_category.category_name);
        }
        tire_manu_column = this.div({'class': 'tire-manufacturer'}, 
                        ['<img src="/assets/' + tirelisting.tire_manufacturer_name + '.gif" border="0"/>',
                         tire_manufacturer_name,
                         tire_model, tire_category]);
        ///////////////////
        pic = this.div({}, ((tirelisting.photo1_thumbnail == null ? 
                                '<img src="/assets/th_icon_128.png">' : 
                                '<img src="' + tirelisting.photo1_thumbnail + '">')));
        pic_column = this.div({'class': 'tire-image'},
                                [pic]);
        ///////////////////
        if (typeof tirelisting.tire_store != 'undefined') {
            logo = this.div({}, ((tirelisting.logo_thumbnail == null ? '' : 
                                    '<img src="' + tirelisting.logo_thumbnail + '">')));
            if (tirelisting.tire_store.private_seller == true) {
                store = this.div({'class': 'tire-store'}, 
                                        [tirelisting.store_visible_name, '']);
            }
            else {
                store = this.div({'class': 'tire-store'}, 
                                        ['<a href="/tire-stores/' + tirelisting.store_to_param + '?tire_size_id=' + tirelisting.tire_size_id + '">' + 
                                            tirelisting.store_visible_name  + '</a>',
                                            logo]);
            }
            ///////////////////
            distance = this.div({'class': 'distance'}, 
                                    'Distance: ' + Math.round(tirelisting.distance) +
                                     ((Math.round(tirelisting.distance) == 1) ? " mile" : " miles"));
        }
        else {
            logo = null;
            store = null;
            distance = null;
        }
        ///////////////////
        if (typeof tirelisting.tire_size != 'undefined') {
            tire_size_column = this.div({'class': 'tire-size'}, 'Size: ' + tirelisting.tire_size.sizestr);
        }
        else
            tire_size_column = this.div({'style': 'visibility: hidden; float: left;'}, '&nbsp;');
        ///////////////////
        qty = this.div({'class': 'tire-quantity'}, 'Quantity: ' + tirelisting.quantity);    

        if (tirelisting.is_new == true) {
            new_image = '<img src="/assets/new_icon.png">';
            treadlife_field = this.div({'class': 'tire-treadlife'}, ['Treadlife: 100%', new_image]);
            // treadlife_hidden_value = '<font style="visibility: hidden; width:0px; float:left;">100</font>';
            treadlife_field = this.div({'class': 'treadlife'}, treadlife_field);
            treadlife_value = '100';
        }
        else {
            if (tirelisting.treadlife == null) {
                // for sorting purposes so undefined doesn't sort to the top
                treadlife_field = this.div({'class': 'treadlife', 'style': 'visibility:hidden;'}, '0');
                treadlife_value = '0';
            }
            else {
                treadlife_field = this.div({'class': 'tire-treadlife'}, 
                                ((tirelisting.treadlife == null ? '&nbsp;' : 'Treadlife: ' + tirelisting.treadlife + '%')));
                treadlife_value = tirelisting.treadlife;
            }
        }    
        hidden_treadlife_value = '<div class="hidden-treadlife" style="visibility: hidden; width:0px; float:left;">' + treadlife_value + '</div>'
        hidden_updated_value = '<div class="hidden-updated" style="visibility: hidden; width:0px; float:left;">' + tirelisting.updated_at + '</div>'
        
        qty_treadlife = this.div({'class': 'qty-treadlife'}, [qty, treadlife_field]);

        if (tirelisting.has_rebate && tirelisting.has_price_break) {
            promotion = '<br /><div class="promotion" id="p_' + tirelisting.id + '">Save even more after rebate!<br />Includes price break!<span></span></div>';
        }
        else if (tirelisting.has_rebate) {
            promotion = '<br /><div class="promotion" id="p_' + tirelisting.id + '">Save even more after rebate!<span></span></div>';
        }
        else if (tirelisting.has_price_break) {
            promotion = '<br /><div class="promotion" id="p_' + tirelisting.id + '">Includes price break!<span></span></div>';
        }
        else {
            promotion = '';
        }

        if (tirelisting.has_price_break) {

        }
        //promotion = this.div({'class': 'promotion', 'id': 'l_' + tirelisting.id},
        //                            '<span><div><h3 class="orange">Loading...</h3></div></span>');
        price = this.span({'class': 'price-data'}, '$' + tirelisting.discounted_price)
        price_column = this.div({'class': 'tire-price'},
                                [price, 
                        (tirelisting.is_new ? ' each' : ''),
                        '<br />' + (tirelisting.includes_mounting ? '<font size="1"> (inc. mounting)</font> ' : '') +
                        promotion]);

        price_qty_treadlife = this.div({'style': 'bottom: 0;'},
                                        [qty_treadlife, price_column])
        ///////////////////

        moreinfo = this.div({'class': 'more-info', 'id': 'l_' + tirelisting.id});

        infographic = this.div({'class': 'infographic', 'id': 'l_' + tirelisting.id},
                                    '<span><div><h3 class="orange">Loading...</h3></div></span>');

        details_column = this.div({'class': 'tire-details'},
                                    [store, tire_size_column, infographic, distance, logo,
                                    price_qty_treadlife,
                                    hidden_treadlife_value, hidden_updated_value]);

        ///////////////////

        if (tirelisting.tire_store == null)
            complete_row = this.div({'id': 'results-item', 'class': 'results-item'},
                            [tire_manu_column, pic_column, details_column, divclear])
        else
            complete_row = this.div({'id': 'results-item', 'class': 'results-item', 'name': tirelisting.id},
                            [tire_manu_column, pic_column, details_column, divclear]);
    }
    else {
        // generic
        pic = this.div({'style': 'width: 128px'}, '<img src="/assets/generic.png">');
        pic_column = this.div({'class': 'tire-image'},
                                [pic]);

        logo = this.div({}, ((tirelisting.logo_thumbnail == null ? '' : 
                                '<img style="margin-left: auto; margin-right: auto;" src="' + tirelisting.logo_thumbnail + '">')));
        distance = this.div({'class': 'distance'}, 
                                'Distance: ' + Math.round(tirelisting.distance) +
                                 ((Math.round(tirelisting.distance) == 1) ? " mile" : " miles"));
        store = this.div({'class': 'tire-manufacturer', 'style': 'text-align: center; font-size: 1.2em;'}, 
                                ['<a href="/tire-stores/' + tirelisting.store_to_param + '?tire_size_id=' + tirelisting.tire_size_id + '">' + 
                                    tirelisting.store_visible_name  + '</a>',
                                    distance, logo, '<br /><i>Brands vary</i>']);
        ///////////////////

        infographic = this.div({'class': ''}, '');

        treadlife_field = this.div({'class': 'tire-treadlife'}, 
                ((tirelisting.treadlife == null ? '&nbsp;' : '&nbsp;')));
        treadlife_value = tirelisting.treadlife;

        if (tirelisting.quantity > 0 && tirelisting.quantity < 4) {
            qty = this.div({'class': 'tire-quantity'}, 'Quantity: ' + tirelisting.quantity);
        }
        else{
            qty = this.div({'class': 'tire-quantity'}, '&nbsp;');
        }
        hidden_treadlife_value = '<div class="hidden-treadlife" style="visibility: hidden; width:0px; float:left;">' + treadlife_value + '</div>'
        hidden_updated_value = '<div class="hidden-updated" style="visibility: hidden; width:0px; float:left;">' + tirelisting.updated_at + '</div>'
        
        qty_treadlife = this.div({'class': 'qty-treadlife'}, [qty, treadlife_field]);


        if (tirelisting.has_rebate && tirelisting.has_price_break) {
            promotion = '<br /><div class="promotion" id="p_' + tirelisting.id + '">Save even more after rebate!<br />Includes price break!<span></span></div>';
        }
        else if (tirelisting.has_rebate) {
            promotion = '<br /><div class="promotion" id="p_' + tirelisting.id + '">Save even more after rebate!<span></span></div>';
        }
        else if (tirelisting.has_price_break) {
            promotion = '<br /><div class="promotion" id="p_' + tirelisting.id + '">Includes price break!<span></span></div>';
        }
        else {
            promotion = '';
        }

        if (tirelisting.has_price_break) {

        }
        //promotion = this.div({'class': 'promotion', 'id': 'l_' + tirelisting.id},
        //                            '<span><div><h3 class="orange">Loading...</h3></div></span>');
        price = this.span({'class': 'price-data'}, '$' + tirelisting.discounted_price)
        price_column = this.div({'class': 'tire-price'},
                                [price, 
                        (tirelisting.is_new ? ' each' : ''),
                        '<br />' + (tirelisting.includes_mounting ? '<font size="1"> (inc. mounting)</font> ' : '<font size="1">mounting: $' + tirelisting.mount_price + "</font>") +
                        promotion]);


        price_qty_treadlife = this.div({'style': 'bottom: 0;'},
                                        [qty_treadlife, price_column])

        gen_desc_column = this.div({'style': 'font-weight: bold; font-style: italic;'}, tirelisting.gendesc);

        details_column = this.div({'class': 'tire-details'},
                                    [gen_desc_column, infographic,
                                    price_qty_treadlife,
                                    hidden_treadlife_value, hidden_updated_value]);        
        complete_row = this.div({'id': 'results-item', 'class': 'results-item'},
                        [store, pic_column, details_column, divclear])
    }

    return this.link('/tire-listings/' + tirelisting.to_param,
        {'id': tirelisting.id}, 
        complete_row);
};