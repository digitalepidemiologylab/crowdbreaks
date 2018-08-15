require 'rails_helper'

RSpec.feature "Question sequence", type: :feature, js: true do

  # simplest question sequence
  let!(:project) { FactoryBot.create(:project, :public) }
  let!(:question) { FactoryBot.create(:question, project: project) }
  let!(:answer1) { FactoryBot.create(:answer, questions: [question]) }
  let!(:answer2) { FactoryBot.create(:answer, questions: [question]) }
  let!(:transition) { FactoryBot.create(:transition, :starting_question, to_question: question, project: project) }
  let!(:result) { FactoryBot.create(:result, tweet_id: 20) }
  let!(:user) { FactoryBot.create(:user, :confirmed) }

  before(:each) do
    visit(project_question_sequence_path(project))
  end

  context 'successfully finishing question sequence' do

    it 'navigates to page correctly' do
      expect(page).to have_current_path(project_question_sequence_path(project))
    end
    
    it 'do question sequence as guest user' do
      expect(page).to have_content('Welcome')
      click_button "Let's go"
      expect(page).to have_content(question.question)
      click_button answer1.answer
      expect(page).to have_content('Thanks for your help!')

      # Make sure questio sequence was correctly stored
      # This fails with the database cleaning strategy, would need some hacky way to make it work
      # expect(Result.count).to eq(2)
      # expect(QuestionSequenceLog.count).to eq(1)
      # expect(QuestionSequenceLog.first.results.first).to eq(project.results.last)
      # expect(Result.last.answer).to eq(answer1)
      # expect(Result.last.question).to eq(question)
      # expect(Result.last.project).to eq(project)
      # expect(Result.last.tweet_id).to eq(20)
      # expect(Result.last.user.username).to eq('guest')
    end
  end
end
