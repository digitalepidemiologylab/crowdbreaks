require 'rails_helper'
require 'vcr_helper'
require 'json'

# ElasticsearchApi
describe AwsApi, '#ping_es', :vcr do
  subject { AwsApi.new }

  it 'pings ES' do
    response = subject.ping_es
    expect(response).to be_an_instance_of Helpers::ApiResponse
    expect(response).to be_success
    expect(response.body).to be_in([true, false])
  end
end

describe AwsApi, '#es_stats', :vcr do
  subject { AwsApi.new }

  it 'test index is in stats' do
    response = subject.es_stats
    expect(response).to be_an_instance_of Helpers::ApiResponse
    expect(response).to be_success
    expect(response.body).to include 'indices'
    expect(response.body['indices']).to have_key ES_TEST_INDEX
  end
end

describe AwsApi, '#es_health', :vcr do
  subject { AwsApi.new }

  it 'gets health status from ES' do
    response = subject.es_health
    expect(response).to be_an_instance_of Helpers::ApiResponse
    expect(response).to be_success
    expect(response.body).to include('status')
  end
end

describe AwsApi, '#predictions', :vcr do
  subject { AwsApi.new }

  it 'get predictions' do
    response = subject.predictions(
      index: ES_TEST_INDEX,
      question_tag: 'sentiment',
      answer_tags: %w[negative neutral positive],
      run_name: 'fasttext_v2',
      start_date: 'now-1d', end_date: 'now', interval: '1h'
    )
    expect(response).to be_an_instance_of Helpers::ApiResponse
    expect(response).to be_success
    expect(response.body).to be_an_instance_of Hash
  end
end

describe AwsApi, '#tweets', :vcr do
  subject { AwsApi.new }

  context 'existing index' do
    let(:es_index_name) { ES_TEST_INDEX }

    it 'gets tweets correctly' do
      response = subject.tweets(index: es_index_name)
      expect(response).to be_an_instance_of Helpers::ApiResponse
      expect(response).to be_success
      expect(response.body).to be_an_instance_of Array
      expect(response.body).not_to be_empty
      response.body.each do |tweet|
        expect(tweet).to be_an_instance_of Helpers::Tweet
        expect(tweet).to have_attributes(id: be, text: be, index: be)
      end
    end
  end

  context 'inexistent index' do
    let(:es_index_name) { 'project_inexistent' }

    it 'gets an empty array' do
      response = subject.tweets(index: es_index_name)
      expect(response).to be_an_instance_of Helpers::ApiResponse
      expect(response).to be_success
      expect(response.body).to be_empty
    end
  end
end

describe AwsApi, '#update_tweet', :vcr do
  subject { AwsApi.new }
  let(:user_id) { 12_345 }
  let(:tweet_id) { ES_TEST_TWEET }

  context 'existing index' do
    let(:es_index_name) { ES_TEST_INDEX }

    it 'updates the tweet successfully' do
      response = subject.update_tweet(index: es_index_name, user_id: user_id, tweet_id: tweet_id)
      expect(response).to be_an_instance_of Helpers::ApiResponse
      expect(response).to be_success
      expect(response.body).to be_an_instance_of Hash
      expect(response.body).to include('result' => 'updated')
    end
  end

  context 'inexistent index' do
    let(:es_index_name) { 'project_inexistent' }

    it 'gets a BadRequest error' do
      response = subject.update_tweet(index: es_index_name, user_id: @user_id, tweet_id: tweet_id)
      expect(response).to be_an_instance_of Helpers::ApiResponse
      expect(response).to be_error
      expect(response.body).to be_nil
      expect(response.message).to include('Elasticsearch::Transport::Transport::Errors::NotFound')
    end
  end
end

# MlApi
describe AwsApi, '#endpoint_labels', :vcr do
  subject { AwsApi.new }
  let(:endpoint_name) { 'crowdbreaks-6512709bc4' }

  it 'endpoint labels are correct' do
    response = subject.endpoint_labels(endpoint_name)
    expect(response).to be_an_instance_of Helpers::ApiResponse
    expect(response).to be_success
    expect(response.body).to be_an_instance_of Hash
    expect(response.body).not_to be_empty
    expect(response.body).to have_key :labels
    expect(response.body).to have_key :label_vals
  end
end

describe AwsApi, '#list_model_endpoints', :vcr do
  subject { AwsApi.new }

  it 'existing models are listed' do
    response = subject.list_model_endpoints
    expect(response).to be_an_instance_of Helpers::ApiResponse
    expect(response).to be_success
    expect(response.body).to be_an_instance_of Array
    expect(response.body).not_to be_empty
    expect(response.body[0]).to be_an_instance_of Hash
  end
end

describe AwsApi, '#predict', :vcr do
  subject { AwsApi.new }
  let(:endpoint_name) { 'crowdbreaks-6512709bc4' }

  it 'prediction comes through' do
    response = subject.predict(text: 'hi there', endpoint_name: endpoint_name)
    expect(response).to be_an_instance_of Helpers::ApiResponse
    expect(response).to be_success
    expect(response.body).to be_an_instance_of String
    expect(JSON.parse(response.body)).to be_an_instance_of Hash
  end
end
