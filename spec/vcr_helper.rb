require 'vcr'

VCR.configure do |config|
  config.configure_rspec_metadata!
  config.cassette_library_dir = 'spec/vcr'
  config.hook_into :webmock
  config.define_cassette_placeholder('<AWS_ACCESS_KEY_ID>', ENV['AWS_ACCESS_KEY_ID'])
  config.define_cassette_placeholder('<AWS_SECRET_ACCESS_KEY>', ENV['AWS_SECRET_ACCESS_KEY'])
  config.allow_http_connections_when_no_cassette = true
end
