require 'csv'

namespace :import do
  desc "Insert data from a csv file from S3 into results table"
  task from_csv: :environment do |t, args|
    puts 'Downloading CSV file from S3...'
    s3 = Aws::S3::Client.new(access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])

    obj = s3.get_object({bucket: ENV['S3_BUCKET_NAME'], key: "other/#{ENV['filename']}"})
    csv = CSV.parse(obj.body, :headers => true)

    project = Project.find_by('es_index_name': 'project_vaccine_sentiment')
    answer_pro = Answer.where(label: 'pro-vaccine').first
    answer_anti = Answer.where(label: 'anti-vaccine').first
    answer_neutral = Answer.where(label: 'neutral').first

    if not ENV['username'].present?
      puts "Set username environemnt variable"
      next
    end

    u = User.find_by(username: ENV['username'])
    if not u.present?
      puts "User #{ENV['username']} is not present in the database. Create the user first."
      next
    end

    id_dict = {'pro-vaccine': answer_pro.id, 'anti-vaccine': answer_anti.id, 'other': answer_neutral.id}
    count = 0
    total = csv.length
    csv.each do |row|
      if count % 100 == 0
        puts "Processing row #{count} out of #{total}..."
      end
      Result.create!(tweet_id: row["tweet_id"], user_id: u.id, project_id: project.id, mturk_result: true, answer_id: id_dict[row["option"].to_sym])
      count += 1
    end
  end
end
