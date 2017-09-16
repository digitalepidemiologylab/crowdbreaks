require "rails_helper"

RSpec.feature "Question sequence", :type => :feature do
  # general setup
  let!(:answer_1) { create(:answer, answer: "Answer 1") }
  let!(:answer_2) { create(:answer, answer: "Answer 2") }
  let!(:answer_3) { create(:answer, answer: "Answer 3") }
  let!(:answer_set) { create(:answer_set, name: 'default', answer0: answer_1, answer1: answer_2, answer2: answer_3) }
  let(:locale) { :en }

  # linear 1
  # Q1 +----> Q2 +----> END
  let!(:project_1) { create(:project, title: "Scenario 1", es_index_name: "project_vaccine_sentiment") }
  let!(:question_1_1) { create(:question, question: 'Question 1.1', project: project_1, answer_set: answer_set) }
  let!(:question_1_2) { create(:question, question: 'Question 1.2', project: project_1, answer_set: answer_set) } 
  let!(:transition_1_1) { create(:transition, project: project_1, from_question: nil, to_question: question_1_1) } 
  let!(:transition_1_2) { create(:transition, project: project_1, from_question: question_1_1, to_question: question_1_2) } 
  # let!(:active_tweet_1) { create(:active_tweet, project: project_1) }

  # linear 2
  # Q1 +--A1--> Q2 +----> END
  let!(:project_2) { create(:project, title: "Scenario 2", es_index_name: "project_vaccine_sentiment") }
  let!(:question_2_1) { create(:question, question: 'Question 2.1', project: project_2, answer_set: answer_set) }
  let!(:question_2_2) { create(:question, question: 'Question 2.2', project: project_2, answer_set: answer_set) } 
  let!(:transition_2_1) { create(:transition, project: project_2, from_question: nil, to_question: question_2_1) } 
  let!(:transition_2_2) { create(:transition, project: project_2, from_question: question_2_1, to_question: question_2_2, answer: answer_1) } 
  # let!(:active_tweet_2) { create(:active_tweet, project: project_2) }

  #  non-linear 3
  #     A1 +--Q2--+
  #        |      |
  # Q1 +---+      +--> Q4 +--> END
  #        |      |
  #     A2 +--Q3--+
  let!(:project_3) { create(:project, title: "Scenario 3", es_index_name: "project_vaccine_sentiment") }
  let!(:question_3_1) { create(:question, question: 'Question 3.1', project: project_3, answer_set: answer_set) }
  let!(:question_3_2) { create(:question, question: 'Question 3.2', project: project_3, answer_set: answer_set) } 
  let!(:question_3_3) { create(:question, question: 'Question 3.3', project: project_3, answer_set: answer_set) } 
  let!(:question_3_4) { create(:question, question: 'Question 3.4', project: project_3, answer_set: answer_set) } 
  let!(:transition_3_1) { create(:transition, project: project_3, from_question: nil, to_question: question_3_1) } 
  let!(:transition_3_2) { create(:transition, project: project_3, from_question: question_3_1, to_question: question_3_2, answer: answer_1) } 
  let!(:transition_3_3) { create(:transition, project: project_3, from_question: question_3_1, to_question: question_3_3, answer: answer_2) } 
  let!(:transition_3_4) { create(:transition, project: project_3, from_question: question_3_2, to_question: question_3_4) } 
  let!(:transition_3_5) { create(:transition, project: project_3, from_question: question_3_3, to_question: question_3_4) } 
  # let!(:active_tweet_3) { create(:active_tweet, project: project_3) }
  
  # invalid 4 
  let!(:project_4) { create(:project, title: "Scenario 4", es_index_name: "project_vaccine_sentiment") }
  let!(:question_4_1) { create(:question, question: 'Question 4.1', project: project_4, answer_set: answer_set) }
  let!(:question_4_2) { create(:question, question: 'Question 4.2', project: project_4, answer_set: answer_set) }
  let!(:question_4_3) { create(:question, question: 'Question 4.3', project: project_4, answer_set: answer_set) }
  let!(:transition_4_1) { create(:transition, project: project_4, from_question: nil, to_question: question_4_1) } 
  let!(:transition_4_2) { create(:transition, project: project_4, from_question: question_4_1, to_question: question_4_2, answer: answer_2) } 
  let!(:transition_4_3) { create(:transition, project: project_4, from_question: question_4_1, to_question: question_4_3, answer: answer_2) } 

  before(:each) do
    visit projects_path
  end

  scenario "is linear 1" do
    expect(page).to have_text("Scenario 1")

    # get to initial  question
    click_link "btn-start-project-#{project_1.id}"
    expect(page).to have_text("Question 1.1")
    expect(page).to have_text("Answer 1")
    expect(page).to have_text("Answer 2")
    expect(page).to have_text("Answer 3")

    # click any button to get to next question
    click_button "Answer 1"
    expect(page).to have_text("Question 1.2")

    # Answer last question
    click_button "Answer 2"
    expect(page).to have_text('Thanks for your help!')
  end

  scenario "is linear 2.1, continues on giving the specified answer for question" do
    expect(page).to have_text("Scenario 2")

    # get to initial  question
    click_link "btn-start-project-#{project_2.id}"

    # click Answer 1 button to get to next question
    click_button "Answer 1"
    expect(page).to have_text("Question 2.2")
  end

  scenario "is linear 2.2, stops on giving the non-specified answer for question" do
    # get to initial  question
    click_link "btn-start-project-#{project_2.id}"

    # click Answer 2 should find no possible transition (as transition is only defined for answer_1)
    click_button "Answer 2"
    expect(page).to have_text('Thanks for your help!')
  end

  scenario "is non-linear 3.1, first branch" do
    # get to initial  question
    click_link "btn-start-project-#{project_3.id}"
    expect(page).to have_text("Question 3.1")

    # top branch
    click_button "Answer 1"
    expect(page).to have_text("Question 3.2")

    # get to last question (any answer)
    click_button "Answer 1"
    expect(page).to have_text("Question 3.4")

    # finish sequence
    click_button "Answer 1"
    expect(page).to have_text('Thanks for your help!')
  end

  scenario "is non-linear 3.2, second branch" do
    # get to initial  question
    click_link "btn-start-project-#{project_3.id}"

    # lower branch
    click_button "Answer 2"
    expect(page).to have_text("Question 3.3")

    # get to last question (any answer)
    click_button "Answer 2"
    expect(page).to have_text("Question 3.4")

    # finish sequence
    click_button "Answer 2"
    expect(page).to have_text('Thanks for your help!')
  end

  scenario "is non-linear 3.3, invalid branch" do
    # get to initial  question
    click_link "btn-start-project-#{project_3.id}"

    # invalid/undefined branch
    click_button "Answer 3"
    expect(page).to have_text('Thanks for your help!')
  end

  scenario "is invalid (multiple transition for same answer)" do
    # get to initial  question
    click_link "btn-start-project-#{project_4.id}"

    # invalid/undefined branch
    expect { click_button "Answer 2" }.to raise_error('Multiple transitions defined for given answer!')
  end
end
