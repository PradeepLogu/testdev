class TireSize < ActiveRecord::Base
  attr_accessible :diameter, :ratio, :sizestr, :wheeldiameter, :created_at, :updated_at

  before_save :set_fields
  # before_save {|tire_size| tire_size.sizestr = sizestr.upcase}

  has_many :tire_models
  has_many :tire_manufacturers, :through => :tire_models

  has_many :auto_options
  has_many :reservations
  has_many :tire_listings
  has_many :auto_years, :through => :auto_options
  has_many :auto_models, :through => :auto_years, :uniq => true, :order => :name
  has_many :auto_manufacturers, :through => :auto_models, :uniq => true, :order => :name

  def wheeldiameter_int=(wheeldiameter)
    self.wheeldiameter = val.to_i
  end

  def wheeldiameter_int
    "#{wheeldiameter}"
  end

  def self.all_diameters
    find(:all, :select => "distinct diameter", :order => "diameter")
  end

  def self.all_ratios(diam)
    if diam
      where(:diameter => diam).select('distinct ratio').order("ratio")
    else
      find(:all, :select => "distinct ratio", :order => "ratio")
    end
  end

  def self.all_wheeldiameters(ratio)
    if ratio
      where(:ratio => ratio).select('distinct wheeldiameter::integer as wheeldiameter').order("wheeldiameter")
    else
      find(:all, :select => "distinct wheeldiameter", :order => "wheeldiameter")
    end
  end

  def self.valid_sizes
    find(:all, :select => 'tire_sizes.id, tire_sizes.sizestr', :joins => 'INNER JOIN tire_models on tire_models.tire_size_id = tire_sizes.id', :group => 'tire_sizes.id', :order => 'tire_sizes.sizestr')
  end

  private 
    def set_fields
      if sizestr.blank? or sizestr.nil?
        self.sizestr = diameter + "/" + ratio + "R" + sprintf("%g", wheeldiameter)
      else
        # populate diameter, ratio, wheel diameter based on sizestr field
        m1 = /(\d{2,})\/(\d{2,}).*?(\d{2,}\.*\d*)/.match(self.sizestr)
        self.diameter = m1[1]
        self.ratio = m1[2]
        self.wheeldiameter = m1[3]
        self.sizestr = self.diameter.to_s + "/" + self.ratio.to_s + "R" + sprintf("%g", self.wheeldiameter)
      end

      self.sizestr = self.sizestr.upcase
    end
end
