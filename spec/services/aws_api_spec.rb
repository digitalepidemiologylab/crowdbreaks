require 'rails_helper'
require 'vcr_helper'
require 'json'

RSpec.describe AwsApi, '#tweets', :vcr do
  before { @api = AwsApi.new }
  before { @user_id = 0 }

  context 'existing index' do
    let(:es_index_name) { ES_TEST_INDEX_PATTERN }

    it 'gets tweets correctly' do
      tweets = @api.tweets(index: es_index_name, user_id: @user_id)
      expect(tweets).to be_an_instance_of Helpers::ApiResponse
      expect(tweets.body).to be_an_instance_of Array
      expect(tweets.body).not_to be_empty
      tweets.body.each do |tweet|
        expect(tweet).to be_an_instance_of Helpers::Tweet
        expect(tweet).to have_attributes(id: be, text: be, index: be)
      end
    end
  end

  context 'inexistent index' do
    let(:es_index_name) { 'project_inexistent' }

    it 'gets an empty array' do
      tweets = @api.tweets(index: es_index_name, user_id: @user_id)
      expect(tweets).to be_an_instance_of Helpers::ApiResponse
      expect(tweets.body).to be_nil
    end
  end
end

RSpec.describe AwsApi, '#update_tweet', :vcr do
  before { @api = AwsApi.new }
  before { @user_id = 12_345 }

  context 'existing index' do
    let(:es_index_name) { ES_TEST_INDEX }

    it 'updates the tweet successfully' do
      response = @api.update_tweet(index: es_index_name, user_id: @user_id, tweet_id: ES_TEST_TWEET)
      expect(response).to be_an_instance_of Helpers::ApiResponse
      expect(response.body).to be_an_instance_of Hash
      expect(response.body).to include('result' => 'updated')
    end
  end

  context 'inexistent index' do
    let(:es_index_name) { 'project_inexistent' }

    it 'gets a BadRequest error' do
      response = @api.update_tweet(index: es_index_name, user_id: @user_id, tweet_id: ES_TEST_TWEET)
      expect(response).to be_an_instance_of Helpers::ApiResponse
      expect(response.body).to be_nil
      expect(response.message).to include('Elasticsearch::Transport::Transport::Errors::NotFound')
    end
  end
end

RSpec.describe AwsApi, '#es_health', :vcr do
  before { @api = AwsApi.new }

  it 'gets health status from ES' do
    response = @api.es_health
    expect(response).to be_an_instance_of Helpers::ApiResponse
    expect(response.body).to include('status')
  end
end

RSpec.describe AwsApi, '#es_stats', :vcr do
  before { @api = AwsApi.new }

  it 'test index is in stats' do
    response = @api.es_stats
    expect(response).to be_an_instance_of Helpers::ApiResponse
    expect(response.body).to include 'indices'
    expect(response.body['indices']).to have_key ES_TEST_INDEX
  end
end

RSpec.describe AwsApi, '#endpoint_labels', :vcr do
  before { @api = AwsApi.new }
  before { @model_name = 'crowdbreaks-6512709bc4' }

  it 'endpoint labels are correct' do
    response = @api.endpoint_labels(@model_name)
    expect(response).to be_an_instance_of Helpers::ApiResponse
    expect(response.body).to be_an_instance_of Hash
    expect(response.body).not_to be_empty
    expect(response.body).to have_key :labels
    expect(response.body).to have_key :label_vals
  end
end

RSpec.describe AwsApi, '#list_model_endpoints', :vcr do
  before { @api = AwsApi.new }

  it 'existing models are listed' do
    response = @api.list_model_endpoints
    expect(response).to be_an_instance_of Helpers::ApiResponse
    expect(response.body).to be_an_instance_of Array
    expect(response.body).not_to be_empty
    expect(response.body[0]).to be_an_instance_of Hash
  end
end

RSpec.describe AwsApi, '#predict', :vcr do
  before { @api = AwsApi.new }
  before { @endpoint_name = 'crowdbreaks-6512709bc4' }

  it 'prediction comes through' do
    response = @api.predict(text: 'hi there', endpoint_name: @endpoint_name)
    expect(response).to be_an_instance_of Helpers::ApiResponse
    expect(response.body).to be_an_instance_of String
    expect(JSON.parse(response.body)).to be_an_instance_of Hash
  end
end

RSpec.describe AwsApi, '#get_predictions', :vcr do
  before { @api = AwsApi.new }
  before { @endpoint_name = 'crowdbreaks-6512709bc4' }

  it 'get predictions' do
    response = @api.get_predictions(
      index: ES_TEST_INDEX_PATTERN,
      question_tag: 'sentiment',
      answer_tags: %w[negative neutral positive],
      run_name: 'fasttext_v2',
      start_date: 'now-1d', end_date: 'now', interval: '1h'
    )
    expect(response).to be_an_instance_of Helpers::ApiResponse
    expect(response.body).to be_an_instance_of Hash
  end
end
