class ConsolidatedTireListing < TireListing
  attr_accessor :num_listings
  attr_accessor :manufacturers
  attr_accessor :distance
  attr_accessor :min_price, :max_price
  
  def initialize(tire_store_id)
    super(:tire_store_id => tire_store_id)
    @manufacturers = []
    @num_listings = 0
    @min_price = 999999
    @max_price = -1
  end
  
  def add_listing(tire_listing)
    if tire_listing.tire_manufacturer.nil?
      ###puts "* can't do anything with #{tire_listing.id} - manu_id is #{tire_listing.tire_manufacturer_id}"
    else
      add_manufacturer(tire_listing.tire_manufacturer.name)
      @num_listings += 1
    end
    
    if tire_listing.respond_to?(:distance)
      self.distance = tire_listing.distance
    end
    
    if tire_listing.discounted_price.to_f < @min_price.to_f
      @min_price = tire_listing.discounted_price
    end
    
    if tire_listing.discounted_price.to_f > @max_price.to_f
      @max_price = tire_listing.discounted_price
    end
  end
  
  def self.dump(consolidated_tire_listings)
    i = 0
    while !consolidated_tire_listings[i].nil? do
      t = consolidated_tire_listings[i]
      if t.is_a?(ConsolidatedTireListing)
        puts "*#{t.tire_store.name} #{t.tire_store_id} #{t.num_listings}"
        (1..t.num_listings).each do |j|
          i += 1
          t1 = consolidated_tire_listings[i]
          puts "    #{t1.tire_store.name} #{t1.tire_store_id} #{t1.id}"
        end
      else
        puts "#{t.tire_store.name} #{t.tire_store_id}"
      end
      i += 1
    end
  end
  
  def self.insert_consolidated_listings(tire_listings)
    #return tire_listings
    
    i = 0
    new_tire_listings = []
    cur_consolidated_listing = nil
    cur_insert_position = 0
    while !tire_listings[i].nil? do
      cur_tire_listing = tire_listings[i]
      new_tire_listings << cur_tire_listing
      if cur_consolidated_listing.nil? || cur_tire_listing.tire_store_id != cur_consolidated_listing.tire_store_id
        if !cur_consolidated_listing.nil? && cur_consolidated_listing.num_listings > 3
          # we need to insert this listing
          new_tire_listings.insert(cur_insert_position, cur_consolidated_listing)
        end
        
        # now create the next potential consolidated listing
        cur_consolidated_listing = ConsolidatedTireListing.new(cur_tire_listing.tire_store_id)
        cur_consolidated_listing.add_listing(cur_tire_listing)
        
        cur_insert_position = new_tire_listings.size - 1# i
      else
        # same tire store id
        cur_consolidated_listing.add_listing(cur_tire_listing)
      end
      
      i += 1
    end
      
    if !cur_consolidated_listing.nil? && cur_consolidated_listing.num_listings > 3
      new_tire_listings.insert(cur_insert_position, cur_consolidated_listing)
    end
    
    return new_tire_listings
  end
  
  private
    def add_manufacturer(manu_name)
      if !@manufacturers.include?(manu_name)
        @manufacturers << manu_name
      end
    end
end