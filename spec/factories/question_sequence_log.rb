FactoryBot.define do
  factory :question_sequence_log do
    trait :public do
      log {
        {
          'timeInitialized': 10.minutes.ago,
          'userTimeInitialized': 10.minutes.ago,
          'answerDelay': 2000,
          'timeMounted': 9.minutes.ago,
          'totalDurationQuestionSequence': 20,
          'timeQuestionSequenceEnd': 1542657158357,
          'resets': [],
          'results': []
        }
      }
    end
    trait :local do
      log {
        {
          'timeInitialized': 10.minutes.ago,
          'userTimeInitialized': 10.minutes.ago,
          'answerDelay': 2000,
          'timeMounted': 9.minutes.ago,
          'totalDurationQuestionSequence': 20,
          'timeQuestionSequenceEnd': 1542657158357,
          'resets': [],
          'results': []
        }
      }
    end
    trait :mturk do
      log {
        {
          'timeInitialized': 10.minutes.ago,
          'userTimeInitialized': 10.minutes.ago,
          'answerDelay': 2000,
          'timeMounted': 9.minutes.ago,
          'timeMturkSubmit': 1542657160126,
          'totalDurationQuestionSequence': 20,
          'totalDurationUntilMturkSubmit': 6535,
          'timeQuestionSequenceEnd': 1542657158357,
          'resets': [],
          'results': []
        }
      }
    end
  end
end
