require 'RMagick'

class TextToGIF
	def create_phone_gif_for_tire_store(tire_store)
		# let's see if we've already created the image.  If so, don't recreate it.
		imagename = "#{tire_store.phone_number_image_name}.gif"
		filename = "#{Rails.root}/public/system/tire_listings/photo1s/#{imagename}"
		urlname = "/system/tire_listings/photo1s/#{imagename}"

		if !FileTest.exists?(filename)
			#Image parameters
			options = {:img_width => 130, :img_height => 25, :text_color => "#333", :font_size => 18,
						:text => tire_store.visible_phone.empty? ? 'n/a' : tire_store.visible_phone, 
						:bg_color => "#EFEFEF"}

			#Initialize a container with it's width and height
			container=Magick::Image.new(options[:img_width],options[:img_height]){
				self.background_color = options[:bg_color]
			}

			#Initialize a new image
			image=Magick::Draw.new
			image.stroke('transparent')
			image.fill(options[:text_color])
			image.font='/var/lib/defoma/x-ttcidfont-conf.d/dirs/TrueType/Verdana_Italic.ttf'
			image.pointsize=options[:font_size]
			image.font_weight=Magick::BoldWeight
			image.text(0,0,options[:text])
			image.text_antialias(false)
			image.font_style=Magick::NormalStyle
			image.gravity=Magick::CenterGravity

			#Place the image onto the container
			image.draw(container)
			#container=container.raise(3,1)

			# To test the image(a pop up will show you the generated dynamic image)
			#container.display

			# generated image will be saved in public directory
			puts "Writing #{filename}"
			begin
				container.write(filename)
			rescue
				# not much we can do about it...
				puts "Write to #{filename} failed..."
			end
		end

		return urlname
	end

	def create_default_leftlogo_for_tire_store(tire_store)
		# let's see if we've already created the image.  If so, don't recreate it.
		imagename = "#{ERB::Util.url_encode(tire_store.visible_name)}_left.gif"
		filename = "#{Rails.root}/public/system/tire_listings/photo1s/#{tire_store.visible_name}_left.gif"
		urlname = "/system/tire_listings/photo1s/#{imagename}"

		if !FileTest.exists?(filename)
			#Image parameters
			options = {:img_width => 600, :img_height => 150, 
						:text_color => "#333", :font_size => 50,
						:text => tire_store.visible_name, 
						:bg_color => "#FFFFFF"}

			#Initialize a container with it's width and height
			container=Magick::Image.new(options[:img_width],options[:img_height]){
				self.background_color = options[:bg_color]
			}

			#Initialize a new image
			image=Magick::Draw.new
			image.stroke('transparent')
			image.fill(options[:text_color])
			image.font='/var/lib/defoma/x-ttcidfont-conf.d/dirs/TrueType/Verdana_Italic.ttf'
			image.pointsize=options[:font_size]
			image.font_weight=Magick::BoldWeight
			image.text(0,0,options[:text])
			image.text_antialias(false)
			image.font_style=Magick::ItalicStyle
			image.gravity=Magick::WestGravity

			#Place the image onto the container
			image.draw(container)
			#container=container.raise(3,1)

			# To test the image(a pop up will show you the generated dynamic image)
			#container.display

			# generated image will be saved in public directory
			begin
				container.write(filename)
			rescue
				# not much we can do about it...
				puts "Write to #{filename} failed..."
			end
		end

		return urlname
	end

	def create_default_rightlogo_for_tire_store(tire_store)
		# let's see if we've already created the image.  If so, don't recreate it.
		imagename = "#{ERB::Util.url_encode(tire_store.visible_name)}_right.gif"
		filename = "#{Rails.root}/public/system/tire_listings/photo1s/#{tire_store.visible_name}_right.gif"
		urlname = "/system/tire_listings/photo1s/#{imagename}"

		if !FileTest.exists?(filename)
			#Image parameters
			options = {:img_width => 324, :img_height => 150, 
						:text_color => "#333", :font_size => 18,
						:bg_color => "#FFFFFF"}

			#Initialize a container with it's width and height
			container=Magick::Image.new(options[:img_width],options[:img_height]){
				self.background_color = options[:bg_color]
			}

			#Initialize a new image
			image=Magick::Draw.new
			image.stroke('transparent')
			image.fill(options[:text_color])
			image.font='/var/lib/defoma/x-ttcidfont-conf.d/dirs/TrueType/Verdana_Italic.ttf'
			image.pointsize=options[:font_size]
			image.font_weight=Magick::BoldWeight
			#image.text(0,0,options[:text])
			image.text(0, 0, tire_store.address1)
			if tire_store.address2 && tire_store.address2.size > 0
				image.text(0, 25, tire_store.address2)
				image.text(0, 50, "#{tire_store.city}, #{tire_store.state} #{tire_store.zipcode}")
				image.text(0, 75, "#{tire_store.visible_phone}")
			else
				image.text(0, 25, "#{tire_store.city}, #{tire_store.state} #{tire_store.zipcode}")
				image.text(0, 50, "#{tire_store.visible_phone}")
			end
			image.text_antialias(false)
			image.font_style=Magick::NormalStyle
			image.gravity=Magick::WestGravity

			#Place the image onto the container
			image.draw(container)
			#container=container.raise(3,1)

			# To test the image(a pop up will show you the generated dynamic image)
			#container.display

			# generated image will be saved in public directory
			begin
				container.write(filename)
			rescue
				# not much we can do about it...
				puts "Write to #{filename} failed..."
			end
		end

		return urlname
	end
end