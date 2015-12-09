class Branding < ActiveRecord::Base
	attr_accessible :tire_store_id, :expiration_date, :listing_html, :store_html, :logo
	attr_accessible :tab1title, :tab1content, :tab2title, :tab2content
	attr_accessible :tab3title, :tab3content, :tab4title, :tab4content
	attr_accessible :tab5title, :tab5content
	attr_accessible :template_number, :slogan, :slogan_description
	has_attached_file :logo, :styles => { :medium => "300x300>", :thumb => "50x50>" }
  	serialize :properties, ActiveRecord::Coders::Hstore
  	validates_inclusion_of :storefront_tab1, :in => [true, false]
  	validates_inclusion_of :storefront_tab2, :in => [true, false]
  	validates_inclusion_of :storefront_tab3, :in => [true, false]
  	validates_inclusion_of :storefront_tab4, :in => [true, false]
  	validates_inclusion_of :storefront_tab5, :in => [true, false]

	belongs_to :tire_store

	has_many :assets
	has_many :asset_usages

    attr_accessor :delete_logo
    attr_accessible :delete_logo
    before_validation { logo.clear if delete_logo == '1' }

	%w[storefront_tab1 storefront_tab2 storefront_tab3 storefront_tab4 storefront_tab5].each do |key|
		attr_accessible key

		define_method(key) do
			result = properties && properties[key]

			return true if result == true || result =~ (/(true|t|yes|y|1)$/i)
			return false 
		end

		define_method("#{key}=") do |value|
		  self.properties = (properties || {}).merge(key => value)
		end
	end

	def has_widget?
		!self.slogan.nil? && !self.slogan_description.nil?
	end

	def tab_count
		tabs.count
	end

	def tabs
		ar = []
		if self.tab1title && self.tab1title.length > 0 &&
			self.tab1content && self.tab1content.length > 0
			ar << self.tab1content
		end
		if self.tab2title && self.tab2title.length > 0 &&
			self.tab2content && self.tab2content.length > 0
			ar << self.tab2content
		end
		if self.tab3title && self.tab3title.length > 0 &&
			self.tab3content && self.tab3content.length > 0
			ar << self.tab3content
		end
		if self.tab4title && self.tab4title.length > 0 &&
			self.tab4content && self.tab4content.length > 0
			ar << self.tab4content
		end
		if self.tab5title && self.tab5title.length > 0 &&
			self.tab5content && self.tab5content.length > 0
			ar << self.tab5content
		end

		ar
	end

	def storefront_tabs
		ar = []
		if self.tab1title && self.tab1title.length > 0 &&
			self.tab1content && self.tab1content.length > 0 &&
			self.storefront_tab1
			ar << self.tab1content
		end
		if self.tab2title && self.tab2title.length > 0 &&
			self.tab2content && self.tab2content.length > 0 &&
			self.storefront_tab2
			ar << self.tab2content
		end
		if self.tab3title && self.tab3title.length > 0 &&
			self.tab3content && self.tab3content.length > 0 &&
			self.storefront_tab3
			ar << self.tab3content
		end
		if self.tab4title && self.tab4title.length > 0 &&
			self.tab4content && self.tab4content.length > 0 &&
			self.storefront_tab4
			ar << self.tab4content
		end
		if self.tab5title && self.tab5title.length > 0 &&
			self.tab5content && self.tab5content.length > 0 &&
			self.storefront_tab5
			ar << self.tab5content
		end

		ar
	end

	def tab_titles
		ar = []
		if self.tab1title && self.tab1title.length > 0 &&
			self.tab1content && self.tab1content.length > 0
			ar << self.tab1title
		end
		if self.tab2title && self.tab2title.length > 0 &&
			self.tab2content && self.tab2content.length > 0
			ar << self.tab2title
		end
		if self.tab3title && self.tab3title.length > 0 &&
			self.tab3content && self.tab3content.length > 0
			ar << self.tab3title
		end
		if self.tab4title && self.tab4title.length > 0 &&
			self.tab4content && self.tab4content.length > 0
			ar << self.tab4title
		end
		if self.tab5title && self.tab5title.length > 0 &&
			self.tab5content && self.tab5content.length > 0
			ar << self.tab5title
		end

		ar
	end

	def storefront_tab_titles
		ar = []
		if self.tab1title && self.tab1title.length > 0 &&
			self.tab1content && self.tab1content.length > 0 &&
			self.storefront_tab1
			ar << self.tab1title
		end
		if self.tab2title && self.tab2title.length > 0 &&
			self.tab2content && self.tab2content.length > 0 &&
			self.storefront_tab2
			ar << self.tab2title
		end
		if self.tab3title && self.tab3title.length > 0 &&
			self.tab3content && self.tab3content.length > 0 &&
			self.storefront_tab3
			ar << self.tab3title
		end
		if self.tab4title && self.tab4title.length > 0 &&
			self.tab4content && self.tab4content.length > 0 &&
			self.storefront_tab4
			ar << self.tab4title
		end
		if self.tab5title && self.tab5title.length > 0 &&
			self.tab5content && self.tab5content.length > 0 &&
			self.storefront_tab5
			ar << self.tab5title
		end

		ar
	end

end
