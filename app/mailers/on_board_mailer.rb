class OnBoardMailer < ActionMailer::Base
 	default from: "mail@treadhunter.com"

  	def on_board_email(user)
  		@user = user
  		@tire_store = @user.tire_store
  		@tire_store = @user.account.tire_stores.first if @tire_store.nil?

  		if @user.is_admin?
    		@tire_stores = @user.tire_stores
  		else
	  		@tire_stores = []
	  		@tire_stores << @tire_store
	  	end

		#attachments['HowToEditYourStorefront.pdf'] = {
		#	:encoding => 'base64',
		#	:content  => Base64.encode64(File.read(Rails.root.join('doc', 'HowToEditYourStorefront.pdf')))
		#}

		attachments['HowToCreateNewTireListings.pdf'] = {
			:encoding => 'base64',
			:content  => Base64.encode64(File.read(Rails.root.join('doc', 'HowToCreateNewTireListings.pdf')))
		}

		attachments['HowToCreateUsedTireListings.pdf'] = {
			:encoding => 'base64',
			:content  => Base64.encode64(File.read(Rails.root.join('doc', 'HowToCreateUsedTireListings.pdf')))
		}

		if Rails.env.staging?
			# staging - do not BCC
			mail(:to => @user.email, subject: 'Welcome to TreadHunter.com!')
		else
			mail(:to => @user.email, :bcc => ["treadhunter.mailer@gmail.com", "pmikhail@treadhunter.com", "jbarker@treadhunter.com"], subject: 'Welcome to TreadHunter.com!')
		end
  	end

  	def on_board_email_private_seller(user)
  		@user = user
  		@tire_store = @user.tire_store
  		@tire_store = @user.tire_stores.first if @tire_store.nil?

  		@tire_stores = []
  		@tire_stores << @tire_store

		attachments['PrivateSellerListings.pdf'] = {
			:encoding => 'base64',
			:content  => Base64.encode64(File.read(Rails.root.join('doc', 'PrivateSellerListings.pdf')))
		}

		if Rails.env.staging?
			# staging - do not BCC
			mail(:to => @user.email, subject: 'Welcome to TreadHunter.com!')
		else
			mail(:to => @user.email, :bcc => "treadhunter.mailer@gmail.com", subject: 'Welcome to TreadHunter.com!')
		end
  	end
end
