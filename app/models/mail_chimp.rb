class MailChimp
	def self.GetNewsletterList
		begin
			Gibbon::API.api_key = "b3bbe797a54e5c9c544a257724418c36-us8"
			Gibbon::API.lists.list["data"].select{|k| k["name"] == "TreadHunter Newsletter"}.first
		rescue Exception => e 
			return nil
		end
	end

	def self.SubscribeToNewsletter(email, ip_address)
		list = MailChimp.GetNewsletterList
		if list.nil?
			return false, "We're sorry, we could not process your request at this time.  Try again later."
		elsif MailChimp.HasRegisteredFromIP?(ip_address)
			return false, "You may only register with one email address."			
		else
			begin
				MailChimp.RegisterFromIP(ip_address)
				gb = Gibbon::API.new("b3bbe797a54e5c9c544a257724418c36-us8")
				response = gb.lists.subscribe({:id => list["id"], :email => {:email => email}, :double_optin => true})
				return true, "Registration completed, you will be receiving an email to confirm your registration."
			rescue Exception => e
				return false, e.to_s.gsub(/Click here to update your profile\./, '')
			end
		end
	end

	def self.GetMemberInfo(email)
		list = MailChimp.GetNewsletterList
		if list.nil?
			return false, nil
		else
			begin
				gb = Gibbon::API.new("b3bbe797a54e5c9c544a257724418c36-us8")
				response = gb.lists.member_info({:id => list["id"], :emails => [{:email => email}]})
				return true, response
			rescue Exception => e
				return false, nil
			end
		end		
	end

    def self.RegisterFromIP(ip_address)
      if Impression.find_by_impressionable_type_and_impressionable_id_and_controller_name_and_action_name_and_view_name('RegisteredNewsletter', 0, "Registered", "Registered", ip_address).nil?
    		query = "INSERT INTO impressions (impressionable_type, impressionable_id, controller_name, action_name, view_name, created_at, updated_at) VALUES ('RegisteredNewsletter', 0, 'Registered', 'Registered', '#{ip_address}','#{Time.now}','#{Time.now}');"
    		ActiveRecord::Base.connection.execute(query)
      end
    end
    
    def self.HasRegisteredFromIP?(ip_address)
      if Impression.find_by_impressionable_type_and_impressionable_id_and_controller_name_and_action_name_and_view_name("RegisteredNewsletter", 0, "Registered", "Registered", ip_address).nil?
        return false
      else
        return true
      end
    end	
end