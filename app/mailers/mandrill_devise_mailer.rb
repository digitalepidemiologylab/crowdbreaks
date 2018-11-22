class MandrillDeviseMailer < Devise::Mailer
   include Devise::Controllers::UrlHelpers

   def confirmation_instructions(record, token, _ = {})
     options = {
       subject: t('confirmation_instructions.subject'),
       email: record.email,
       global_merge_vars:  [
         { name: 'GREETING', content: I18n.t('default_greeting', username: record.username)},
         { name: 'BUTTON_URL', content: confirmation_url(record, confirmation_token: token, locale: I18n.locale) },
         { name: 'BODY_TEXT', content: I18n.t('confirmation_instructions.body_html')},
         { name: 'BUTTON_TEXT', content: I18n.t('confirmation_instructions.button_text')},
         { name: 'WRONG_RECIPIENT', content: I18n.t('email_wrong_recipient')},
       ],
       template: 'crowdbreaks-devise'
     }
     mandrill_send options
   end

   def unlock_instructions(record, token, _ = {})
     options = {
       subject: I18n.t('unlock_instructions.subject'),
       email: record.email,
       global_merge_vars:  [
         { name: 'GREETING', content: I18n.t('default_greeting', username: record.username)},
         { name: 'BUTTON_URL', content: unlock_url(record, unlock_token: token, locale: I18n.locale) },
         { name: 'BODY_TEXT', content: I18n.t('unlock_instructions.body_html')},
         { name: 'BUTTON_TEXT', content: I18n.t('unlock_instructions.button_text')},
         { name: 'WRONG_RECIPIENT', content: I18n.t('email_wrong_recipient')},
       ],
       template: 'crowdbreaks-devise'
     }
     mandrill_send options
   end

   def reset_password_instructions(record, token, _ = {})
     options = {
       subject: I18n.t('reset_password_instructions.subject'),
       email: record.email,
       global_merge_vars:  [
         { name: 'GREETING', content: I18n.t('default_greeting', username: record.username)},
         { name: 'BUTTON_URL', content: edit_password_url(record, reset_password_token: token, locale: I18n.locale) },
         { name: 'BODY_TEXT', content: I18n.t('reset_password_instructions.body_html')},
         { name: 'BUTTON_TEXT', content: I18n.t('reset_password_instructions.button_text')},
         { name: 'WRONG_RECIPIENT', content: I18n.t('email_wrong_recipient')},
       ],
       template: 'crowdbreaks-devise'
     }
     mandrill_send options
   end

   def password_change(record, _ = {})
     options = {
       subject: I18n.t('password_change.subject'),
       email: record.email,
       global_merge_vars:  [
         { name: 'GREETING', content: I18n.t('default_greeting', username: record.username)},
         { name: 'BODY_TEXT', content: I18n.t('password_change.body_html')},
         { name: 'WRONG_RECIPIENT', content: I18n.t('email_wrong_recipient')},
       ],
       template: 'crowdbreaks-devise-text-only'
     }
     mandrill_send options
   end

   def email_change(record, _ = {})
     options = {
       subject: I18n.t('email_change.subject'),
       email: record.email,
       global_merge_vars:  [
         { name: 'GREETING', content: I18n.t('default_greeting', username: record.username)},
         { name: 'BODY_TEXT', content: I18n.t('email_change.body_html')},
         { name: 'WRONG_RECIPIENT', content: I18n.t('email_wrong_recipient')},
       ],
       template: 'crowdbreaks-devise-text-only'
     }
     mandrill_send options
   end

   def mandrill_send(options = {})
     mailer = ApplicationMailer.new
     mailer.send(options)
   end
end
