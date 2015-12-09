class LearningCenter
	include HTTParty
	base_uri 'learn.treadhunter.com'

	TIPS_AND_TRICKS = "Tips And Tricks"
	WHAT_SIZE_IS_RIGHT = "What Tire Size Is Right For Me?"
	SEO_BRANDS_PAGE = "SEO Brands Page"
	SEO_TIRE_STORES_SEARCH_RESULTS_PAGE = "SEO Tire Stores Search Results"
	SEO_BROWSE_TIRES_PAGE = "SEO Browse Tires Page"
	SEO_BROWSE_BY_CAR_TYPE_PAGE = "SEO Browse By Car Type Page"	
	SEO_HOMEPAGE = "SEO HomePage"
	FAQ = "FAQ"
	GLOSSARY = "Glossary"
	TERMS = "Terms"


	class WPBase
		attr_accessor :lc, :may_need_sorting, :orig_title

		def initialize(lc, hash)
			self.lc = lc
			hash.each do |k, v|
				if self.respond_to?(k)
					if k == "title" || k == "title_plain"
						# if it's a title, they may have used a sorting technique.
						# you can name your categories 1. Blah 2. Another 3. My Title
						# and they will sort alphabetically by default.  We need
						# to strip off the numbering.
						if v != v.sub(/^\d*\.* */, "")
							if k == "title"
								self.orig_title = v
								self.may_need_sorting = true 
							end
							v = v.sub(/^\d*\.* */, "")
						elsif k == "title"
							self.may_need_sorting = false
						end
					end
					self.send("#{k}=", v)
				end
			end
		end

		def self.parse_posts(lc, body_json)
			result = []

			body_json.each do |post|
				result << Post.new(lc, post)
			end

			# check and see if posts are in "10. xxx" title format.  If so, they
			# need to be sorted.
			if result.size > 0
				if result[0].may_need_sorting && result[0].respond_to?(:orig_title)
					result.sort!{ |a, b| (a.orig_title || a.title) <=> (b.orig_title || b.title) }
				end
			end

			return result
		end

		def self.parse_categories(lc, body_json)
			result = []

			body_json.each do |cat|
				result << Category.new(lc, cat)
			end

			return result
		end

	end

	class Tag < WPBase
		attr_accessor :id, :slug, :title, :description, :post_count
	end

	class Category < WPBase
		attr_accessor :id, :slug, :title, :description, :parent, :post_count

		def posts
			@posts ||= begin
				lc = LearningCenter.new if lc.nil?

				lc.posts_by_category_id(self.id)
			rescue Exception => e
				puts "Got an exception #{e.to_s} #{e.backtrace}"
				@posts = nil
			end
		end
	end

	class Glossary < Category
		attr_accessor :header_text

		def initialize(lc)
			self.lc = lc
		end

		def posts
			@posts ||= begin
				self.lc = LearningCenter.new if self.lc.nil?

				@sub_categories ||= begin 
					self.lc.all_categories(self.id)
				end

				if @terms_cat.nil?
					@sub_categories.each do |sub|
						if sub.title == TERMS 
							@terms_cat = sub 
							break
						end
					end
				end

				if @terms_cat
					@terms_cat.posts
				else
					nil 
				end
			rescue Exception => e
				puts "Got an exception #{e.to_s} #{e.backtrace}"
				@posts = nil 
			end
		end

		def my_posts
			@my_posts || self.lc.posts_by_category_name(GLOSSARY)
		end

		def header_text
			@header_text ||= begin
				self.lc.find_post_by_title_in_posts_array(my_posts, "Header Text") || ""
			end
		end

		def alphabet_array(only_letters_with_terms=true)
			alpha_hash = {}
			if !only_letters_with_terms
				("A".."Z").each do |l|
					alpha_hash[l] = []
				end
			end
			self.posts.each do |p|
				if alpha_hash[p.title[0].upcase].nil?
					alpha_hash[p.title[0].upcase] = []
				end
				alpha_hash[p.title[0].upcase] << [p.title, p.content_without_p_tags]
			end
			return alpha_hash.to_a.sort!{ |a, b| a[0] <=> b[0] }
		end
	end

	class Author < WPBase
		attr_accessor :id, :slug, :name, :first_name, :last_name, :nickname
		attr_accessor :url, :description
	end

	MIME_IMAGE = "image/jpeg"

	class Attachment < WPBase
		attr_accessor :id,  :url, :slug, :description
		attr_accessor :url, :description, :caption, :mime_type, :images
	end

	class Post < WPBase
		attr_accessor :id, :slug, :status, :title, :title_plain, :type, :url
		attr_accessor :content, :excerpt, :date, :modified, :tags, :author, :categories, :attachments

		def initialize(lc, post_hash)
			super(lc, post_hash)

			self.tags = []
			post_hash["tags"].each do |tag|
				self.tags << Tag.new(lc, tag)
			end
			self.categories = []
			post_hash["categories"].each do |cat|
				self.categories << Category.new(lc, cat)
			end
			self.author = Author.new(lc, post_hash["author"])

			#print "Loading attachments"
			post_hash["attachments"].each do |attachment|
				print attachment.to_s
				self.attachments << Attachment.new(lc, attachment)
			end

			self
		end

		def content_without_html
			if content.blank?
				return ""
			else
				return content.gsub(/<[^>]*>/, "")
			end
		end

		def content_without_p_tags
			if content.blank?
				return ""
			else
				return content.gsub(/^\<p\>/, "").gsub(/\<\/p\>$/, "") 
			end
		end

		def to_s
			return content_without_html
		end
	end

	#def initialize #(id, page)
	#	@options = {} #{ query: {id: id, page: page, json: '1'} }
	#end

	def faq_category_name
		return FAQ
	end

	def faq
		return posts_by_category_name(faq_category_name)
	end

	def tips_and_tricks_posts
		return posts_by_category_name(TIPS_AND_TRICKS)
	end

	def what_size_is_right_posts
		return posts_by_category_name(WHAT_SIZE_IS_RIGHT)
	end

	def seo_brands_page_posts
		result = posts_by_category_name(SEO_BRANDS_PAGE)
		return result
	end

	def seo_tires_stores_search_results_page_posts
		return posts_by_category_name(SEO_TIRE_STORES_SEARCH_RESULTS_PAGE)
	end

	def seo_browse_tires_page_posts
		return posts_by_category_name(SEO_BROWSE_TIRES_PAGE)
	end

	def seo_browse_by_car_type_page_posts
		return posts_by_category_name(SEO_BROWSE_BY_CAR_TYPE_PAGE)
	end

	def seo_homepage_posts
		return @seo_homepage_posts ||= posts_by_category_name(SEO_HOMEPAGE)
	end

	def most_recent_post
		return get_recent_posts.first
	end

	def cities_for_state(state_abbr)
		cities_post = nil
		seo_homepage_posts.each do |post|
			if post.title_plain == "#{state_abbr.upcase} Cities"
				cities_post = post
				break
			end
		end

		if cities_post.nil?
			return nil
		else
			return cities_post.content_without_html.split("\n")
		end
	end

	def cities_for_region(region_name)
		cities_post = nil
		seo_homepage_posts.each do |post|
			if post.title_plain.upcase == "#{region_name.upcase} REGION CITIES"
				cities_post = post
				break
			end
		end

		if cities_post.nil?
			return nil
		else
			return cities_post.content_without_html.gsub(/, /, ',').split("\n").map{|city_state| city_state.split(",")}
		end
	end	

	def get_recent_posts
		body = self.class.get("/?json=get_recent_posts")

		return WPBase.parse_posts(self, body["posts"])
	end

	def all_categories(parent_id=nil)
		result = []
		if parent_id.nil?
			body = self.class.get("/?json=get_category_index")
		else
			body = self.class.get("/?json=get_category_index&parent=#{parent_id}")
		end

		return WPBase.parse_categories(self, body["categories"])
	end

	def posts_by_tag_slug(tag_slug)
		body = self.class.get("/?json=get_tag_posts&tag_slug=#{tag_slug}")

		return WPBase.parse_posts(self, body["posts"])
	end

	def posts_by_category_slug(category_slug)
		body = self.class.get("/?json=get_slug_posts&category_slug=#{category_slug}")

		return WPBase.parse_posts(self, body["posts"])
	end

	def get_brands_page_seo
		return posts_by_category_slug(SEO_BRANDS_PAGE_CAT_SLUG)
	end

	def category_by_id(category_id)
		result = nil
		all_categories.each do |cat|
			if category_id == cat.id
				result = cat
				break
			end
		end
		return result
	end

	def category_by_name(category_name)
		result = nil
		all_categories.each do |cat|
			if category_name.downcase == cat.title.downcase
				result = cat
				break
			end
		end
		return result
	end

	def posts_by_category_name(category_name)
		result = nil
		cat = category_by_name(category_name)
		result = posts_by_category_id(cat.id) unless cat.nil?
		return result
	end

	def posts_by_category_id(category_id)
		body = ""
		get_bench = Benchmark.measure {
			#body = self.class.get("/?json=get_category_posts&id=#{category_id}&count=100")
			body = JSON.load(open("http://learn.treadhunter.com/?json=get_category_posts&id=#{category_id}&count=100"))
		}

		all_posts = []

		parse_bench = Benchmark.measure{
			all_posts += WPBase.parse_posts(self, body["posts"])
			i = 1

			while i < body["pages"] # parse body to get pages
				i = i + 1
				#body = self.class.get("/?json=get_category_posts&id=#{category_id}&page=#{i}&count=100")
				body = JSON.load(open("http://learn.treadhunter.com/?json=get_category_posts&id=#{category_id}&page=#{i}&count=100"))
				all_posts += WPBase.parse_posts(self, body["posts"])
			end
		}

		return all_posts
	end

	def subcategories_by_category_name(category_name)
		result = nil
		cat = category_by_name(category_name)
		if cat
			result = all_categories(cat.id)
		end
		return result
	end

	def get_post_by_id(id)
		result = nil
		body = self.class.get("/?json=get_post&post_id=#{id}")

		if body["post"]
			result = Post.new(self, body["post"])
		end

		return result
	end

	def find_post_by_title_in_posts_array(ar_posts, post_title)
		begin
			tmp = []
			ar_posts.each do |post|
				if post.title.downcase.gsub(/\&\#8217\;/, "'") == post_title.downcase
					tmp << post 
				end
			end
			#tmp = ar_posts.select{|p| p.title.downcase == post_title.downcase}
			if tmp.size == 0
				return nil 
			else
				return tmp.first 
			end
		rescue
			return nil
		end
	end
end