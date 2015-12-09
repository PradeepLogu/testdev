require 'db_mail_interceptor' #add this line

ActionMailer::Base.smtp_settings = {  
  :address              => "pod51018.outlook.com", #smtp.gmail.com",  
  :port                 => 587,  
  :domain               => "treadhunter.com",  
  :user_name            => "mail@treadhunter.com", #"treadhunter.mailer@gmail.com",  
  :password             => "+1r3sRu515",  
  :authentication       => "login",  
  :enable_starttls_auto => true  
}

ActionMailer::Base.register_interceptor(DBMailInterceptor) if (Rails.env.development?)