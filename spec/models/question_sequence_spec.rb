require 'rails_helper'

RSpec.describe QuestionSequence, type: :model do
  let!(:project) { FactoryBot.create(:project) }
  let!(:question1) { FactoryBot.create(:question, project: project) }
  let!(:question2) { FactoryBot.create(:question, project: project) }
  let!(:answer1) { FactoryBot.create(:answer, questions: [question1]) }
  let!(:answer2) { FactoryBot.create(:answer, questions: [question1]) }
  let!(:transition1) { FactoryBot.create(:transition, :starting_question, to_question: question1, project: project) }
  let!(:transition2) { FactoryBot.create(:transition, from_question: question1, to_question: question2, project: project) }


  it "loads question sequence" do
    qs = QuestionSequence.new(project).load
    expect(qs[:questions][question1.id][:question]).to eq(question1.question)
    expect(qs[:questions][question1.id][:answers][0][:answer]).to eq(question1.answers.first.answer)
    expect(qs[:transitions]['start'][0][:to_question]).to eq(question1.id)
    expect(qs[:num_transitions]).to eq(2)
  end

  it "destroys question sequence" do
    QuestionSequence.new(project).destroy
    expect(Answer.count).to eq(0)
    expect(Question.count).to eq(0)
    expect(Transition.count).to eq(0)
    expect(Project.count).to eq(1)
  end

  it "updates question sequence" do
    p = project
    q = question1
    qs = QuestionSequence.new(p).edit
    questions = qs[:questions]
    questions[q.id][:question] = 'changed'
    questions[q.id][:original_id] = question1.id
    transitions = qs[:transitions]
    QuestionSequence.new(p).update(questions, transitions)
    q.reload
    expect(q.question).to eq('changed')
  end
end

