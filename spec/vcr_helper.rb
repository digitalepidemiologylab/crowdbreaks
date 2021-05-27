require 'vcr'

VCR.configure do |config|
  config.configure_rspec_metadata!
  config.cassette_library_dir = 'spec/vcr'
  config.hook_into :webmock
  config.define_cassette_placeholder('<ES_HOST_PORT>', ENV['ES_HOST_PORT'])
  config.define_cassette_placeholder('<AWS_ACCESS_KEY_ID>', ENV['AWS_ACCESS_KEY_ID'])
  config.define_cassette_placeholder('<AWS_SECRET_ACCESS_KEY>', ENV['AWS_SECRET_ACCESS_KEY'])
end
