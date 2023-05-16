require 'rails_helper'

RSpec.describe LocalBatchJobsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let!(:user1) { FactoryBot.create(:user, :contributor, :confirmed) }
  let!(:user2) { FactoryBot.create(:user, :contributor, :confirmed) }
  let!(:user3) { FactoryBot.create(:user, :contributor, :confirmed) }
  let!(:project) { FactoryBot.create(:project) }
  # user 1 and 3 are allowed to work on batch
  let!(:local_batch_job) { FactoryBot.create(:local_batch_job, users: [user1, user3], project: project) }

  let!(:local_tweet1) { FactoryBot.create(:local_tweet, local_batch_job: local_batch_job, tweet_id: '998872933304094720') }
  let!(:local_tweet2) { FactoryBot.create(:local_tweet, local_batch_job: local_batch_job, tweet_id: '20') }

  # User2 did tweet 1
  let!(:result1) { FactoryBot.create(:result, tweet_id: local_tweet1.tweet_id, project: project, user: user2) }
  # User1 did tweet 1 but not related to local batch
  let!(:result2) { FactoryBot.create(:result, project: project, tweet_id: local_tweet1.tweet_id, user: user1) }
  # User3 did tweet 1 in batch
  let!(:result3) { FactoryBot.create(:result, project: project, local_batch_job: local_batch_job, tweet_id: local_tweet1.tweet_id, user: user3) }

  xdescribe 'GET #show' do
    it 'allows users belonging to batch' do
      sign_in user1
      get :show, params: { id: local_batch_job.slug }
      expect(response).to render_template('show')
    end

    it 'does not allow guest' do
      get :show, params: { id: local_batch_job.slug }
      expect(response).to redirect_to(root_path)
    end

    it 'does not allow foreign user' do
      sign_in user2
      get :show, params: { id: local_batch_job.slug }
      expect(response).to redirect_to(root_path)
    end

    it 'loads correct project' do
      sign_in user1
      get :show, params: { id: local_batch_job.slug }
      expect(assigns(:project).id).to eq(project.id)
      expect(assigns(:local_batch_job).id).to eq(local_batch_job.id)
      expect(assigns(:instructions)).to eq(local_batch_job.instructions)
    end

    it 'shows correct counts' do
      sign_in user1
      get :show, params: { id: local_batch_job.slug }
      expect(assigns(:total_count)).to eq(2)
      expect(assigns(:user_count)).to eq(0)
    end

    it 'shows correct counts' do
      sign_in user3
      get :show, params: { id: local_batch_job.slug }
      expect(assigns(:total_count)).to eq(2)
      expect(assigns(:user_count)).to eq(1)
    end

    it 'gives correct tweet ID user1' do
      sign_in user1
      get :show, params: { id: local_batch_job.slug }
      expect(assigns(:tweet_id)).to eq(local_tweet1.tweet_id).or eq(local_tweet2.tweet_id)
    end

    it 'gives correct tweet ID for user3' do
      sign_in user3
      get :show, params: { id: local_batch_job.slug }
      expect(assigns(:tweet_id)).to eq(local_tweet2.tweet_id)
    end
  end
end
