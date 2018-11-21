class MandrillDeviseMailer < Devise::Mailer
   include Devise::Controllers::UrlHelpers


   def confirmation_instructions(record, token, _ = {})
     options = {
       subject: 'Confirmation',
       email: record.email,
       global_merge_vars:  [
         { name: 'CONFIRMATION_URL', content: confirmation_url(record, confirmation_token: token) },
       ],
       template: 'devise-confirmation-instructions'
     }
     mandrill_send options
   end


   def mandrill_send(options = {})
     message = {
       subject: options[:subject],
       from_name: 'Crowdbreaks',
       from_email: 'no-reply@crowdbreaks.org',
       to: [
         {
           email: options[:email],
           type: 'to'
         }
       ],
       global_merge_vars:  options[:global_merge_vars]
     }
     res = Crowdbreaks::Mandrill.messages.send_template(options[:template], [], message) unless Rails.env.test?
     [res, message]
   rescue Mandrill::Error => e
     Rails.logger.debug(e)
     raise e
   end
end
