require 'rails_helper'
require 'vcr_helper'

RSpec.describe AwsApi, '#tweet', :vcr do
  before { @api = AwsApi.new }
  context 'existing index' do
    let(:es_index_name) { 'project_vaccine_*' }
    let(:user_id) { 0 }

    it 'gets a tweet correctly' do
      tweet = @api.tweet(index: es_index_name, user_id: user_id)
      expect(tweet).to be_a_kind_of(Services::Tweet)
      expect(tweet).to have_attributes(id: be, text: be)
    end
  end

  # context 'inexistent index' do
  #   let(:es_index_name) { 'project_inexistent' }
  #   let(:user_id) { 0 }

  #   it 'gets a tweet correctly' do
  #     tweet = @api.tweet(index: es_index_name, user_id: user_id)
  #     expect(tweet).to be_a_kind_of(Services::Tweet)
  #     expect(tweet).to have_attributes(id: be, text: be)
  #   end
  # end
end
