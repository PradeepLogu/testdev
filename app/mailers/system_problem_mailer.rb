class SystemProblemMailer < ActionMailer::Base
  default from: "mail@treadhunter.com"

  def system_problem_text(problem_description)
    @problem_description = problem_description
    mail(:to => system_problem_email_address(), :cc => system_problem_cc_email_address(), 
    	:bcc => system_problem_bcc_email_address(), subject: 'not used')
  end

  def system_problem(problem_description)
  	@problem_description = problem_description
  	mail(:to => system_problem_email_address(), :cc => system_problem_cc_email_address(), 
    	:bcc => system_problem_bcc_email_address(), subject: 'System Problem - TreadHunter.com')
  end  
end
