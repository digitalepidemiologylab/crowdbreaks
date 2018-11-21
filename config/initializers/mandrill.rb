require 'mandrill'
Crowdbreaks::Mandrill = Mandrill::API.new ENV['MANDRILL_API_KEY']
