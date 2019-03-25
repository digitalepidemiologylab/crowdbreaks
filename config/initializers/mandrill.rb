require 'mandrill'
unless Rails.env.test?
  Crowdbreaks::Mandrill = Mandrill::API.new ENV['MANDRILL_API_KEY']
end
