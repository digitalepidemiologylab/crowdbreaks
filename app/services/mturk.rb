class Mturk
  LAYOUT_ID = '3TWWBMKU94TCKLWG04TCWEF5VEQXWM'
  BONUS_AMOUNT = 0.1
  REWARD_AMOUNT = 0.1

  # class methods
  def self.create_hits
    STDOUT.puts 'Which environement do you want to use? Sandbox (s) or Production (p)?'
    host_type = STDIN.gets.chomp
    host = (host_type == 'p' ? :Production : :Sandbox)
    p "HOST: #{host}"

    STDOUT.puts 'How many hits do you want to create?'
    num_assignments = STDIN.gets.chomp.to_i
    p "Number of HITs: #{num_assignments}"

    mechanical_turk_requester = Amazon::WebServices::MechanicalTurkRequester.new Host: host, AWSAccessKeyId: ENV['AWS_ACCESS_KEY_ID'], AWSAccessKey: ENV['AWS_SECRET_ACCESS_KEY']

    title = 'Crowdbreaks'
    desc = 'Answer a sequence of questions about a tweet'
    keywords = 'twitter, science, sentiment, vaccinations'
    reward_amount = 0.10 # 10 cents
    bonus_amount = 0.10 # 10 cents
    project_name = 'vaccine-sentiment-tracking'
    base_url = ENV['HOST']
    if base_url.include? 'localhost' 
      warn('Use in staging or production for this to work...')
    end
    puts "Using the following LayoutID: #{LAYOUT_ID}"

    # LayoutID
    puts "Would you like to change the layout ID? (y/n)"
    change = STDIN.gets.chomp
    if change == 'y'
      puts 'Fill in your new layout ID: '
      layout_id = STDIN.gets.chomp
      puts "New layoutID is #{layout_id}"
    end

    puts "Creating #{num_assignments} HITs..."
    num_assignments.times do |i|
      puts "Creating Hit number #{i}..."
      token_set = MturkToken.create
      props = {
        Title: title,
        Description: desc,
        MaxAssignments: 1,
        Reward: {
          Amount: reward_amount,
          CurrencyCode: 'USD'
        },
        Keywords: keywords,
        LifetimeInSeconds: 60 * 60 * 24 * 1,
        HITLayoutId: layout_id,
        HITLayoutParameter: [
          {Name: 'bonus', Value: bonus_amount.to_s},
          {Name: 'reward', Value: reward_amount.to_s},
          {Name: 'token', Value: token_set.token.to_s},
          {Name: 'project_name', Value: project_name},
          {Name: 'base_url', Value: base_url}
        ]
      }
      result = mechanical_turk_requester.createHIT(props)
      if result[:HITTypeId].present?
        token_set.update_attributes!(hit_id: result[:HITTypeId])
        puts "Find HIT at: https://workersandbox.mturk.com/mturk/preview?groupId=#{result[:HITTypeId]} with token: #{token_set.token}, and key: #{token_set.key}"
      else
        puts "No HITTypeID is present"
      end
    end
  end

  def self.list_hits(production=false)
    client = production ? self.production_client : self.client
    hits = client.list_hits.hits
    puts "Number of hits: #{hits.length}"
    hits.each do |hit|
      puts "HIT ID: #{hit.hit_id}"
      puts "Title: #{hit.title}"
      puts "Status: #{hit.hit_status}"
      puts "-----------------------------"
    end; nil
  end

  def self.delete_all_hits(production=false)
    client = production ? self.production_client : self.client
    puts "You are going to delete the following HITs:"
    self.list_hits
    puts "Are you sure (y/n)"
    yes_no = STDIN.gets.chomp
    return if yes_no == 'n'
    hits = client.list_hits.hits
    host = (production ? :Production : :Sandbox)
    p "HOST: #{host}"
    mechanical_turk_requester = Amazon::WebServices::MechanicalTurkRequester.new Host: host, AWSAccessKeyId: ENV['AWS_ACCESS_KEY_ID'], AWSAccessKey: ENV['AWS_SECRET_ACCESS_KEY']
    hits.each do |hit|
      begin
        puts "----------------------------"
        puts "Deleting HIT #{hit.hit_id} ..."
        puts "Hit has status of #{hit.hit_status}"

        # hits in state 'Unassignable' can't be deleted until hit is returned/completed
        if hit.hit_status == 'Unassignable'
          raise 'The hit is currently being processed by a worker and can therefore not be deleted...'
        elsif hit.hit_status == 'Reviewable'
          # approve hit if in 'Reviewable' status
          puts "Auto-approving hit..."
          resp = client.list_assignments_for_hit(hit_id: hit.hit_id)
          a_id = resp.assignments[0].assignment_id
          client.approve_assignment(assignment_id: a_id)
        elsif hit.hit_status == 'Assignable'
          puts "Force expiring hit..."
          mechanical_turk_requester.forceExpireHIT(HITId: hit.hit_id)
        end
        # try deleting
        resp = client.delete_hit(hit_id: hit.hit_id)
      rescue Exception => e   # this is bad style, please forgive me
        puts "Could not delete hit... caught following exception:"
        p e
        # resp = client.delete_hit(hit_id: id)
      else
        puts "Successfully deleted hit!"
      end
    end; nil
  end

  def self.delete_hit(hit_id, production=false)
    client = production ? self.production_client : self.client
    resp = client.delete_hit(hit_id: hit_id)
  end

  def self.calculate_bonus(num_questions)
    (num_questions - 1) * BONUS_AMOUNT
  end

  def self.grant_bonus(assignment_id:, worker_id:, num_questions_answered:)
    bonus_amount = (num_questions_answered - 1)* BONUS_AMOUNT
    resp = client.send_bonus(
      worker_id: worker_id.to_s,
      bonus_amount: bonus_amount.to_s,
      assignment_id: assignment_id.to_s,
      reason: "You answered a total of #{num_questions_answered} questions. Therefore your bonus is #{num_questions_answered-1} * #{BONUS_AMOUNT}. Thank you for your help.",
      unique_request_token: rand(36**20).to_s(36)  # creates random string of length 19 or 20
    )
  end

  private

  def self.client
    Aws::MTurk::Client.new(endpoint: 'https://mturk-requester-sandbox.us-east-1.amazonaws.com')
  end

  def self.production_client
    Aws::MTurk::Client.new
  end
end
