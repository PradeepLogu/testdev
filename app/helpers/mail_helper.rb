module MailHelper
    def self.email_sent(mail, id, to_address)
      @email_class = mail.class.name
      @action_name = action_name(mail)
      @id = id
      if Impression.find_by_impressionable_type_and_impressionable_id_and_controller_name_and_action_name_and_view_name('Email', @id, @email_class, @action_name, to_address.downcase).nil?
    		query = "INSERT INTO impressions (impressionable_type, impressionable_id, controller_name, action_name, view_name, created_at, updated_at) VALUES ('Email', #{@id}, '#{@email_class}', '#{@action_name}', '#{to_address.downcase}','#{Time.now}','#{Time.now}');"
    		ActiveRecord::Base.connection.execute(query)
      end
    end
    
    def self.was_email_sent?(mail, id, to_address)
      @email_class = mail.class.name
      @action_name = action_name(mail)
      @id = id
      if Impression.find_by_impressionable_type_and_impressionable_id_and_controller_name_and_action_name_and_view_name("Email", @id, @email_class, @action_name, to_address.downcase).nil?
        return false
      else
        return true
      end
    end
    
    def action_name(mail)
      "#{caller[1] =~ /`([^']*)'/ and $1}"
    end
end
