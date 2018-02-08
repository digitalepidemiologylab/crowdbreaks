namespace :counter do
  desc "Reset question sequence counter"
  task reset_question_sequences_count: :environment do
    Project.all.each do |project|
      project.question_sequences_count = project.results.group(:tweet_id, :user_id).count.length
      project.save
      puts "Update count of #{project.question_sequences_count} question sequences for project '#{project.title}'"
    end
  end
end
