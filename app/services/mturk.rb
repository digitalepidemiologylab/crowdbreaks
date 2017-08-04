class Mturk
  @@layoutID = '3CM3A9T0031BGE9WDNU4QBP9FUA0SG'

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
    puts "Using the following LayoutID: #{@@layoutID}"
    puts "Would you like to change the layout ID? (y/n)"
    change = STDIN.gets.chomp
    if change == 'y'
      puts 'Fill in your new layout ID: '
      @@layoutID = STDIN.gets.chomp
      puts "New layoutID is #{@@layoutID}"
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
        HITLayoutId: @@layoutID,
        HITLayoutParameter: [
          {Name: 'bonus', Value: bonus_amount.to_s},
          {Name: 'reward', Value: reward_amount.to_s},
          {Name: 'token', Value: token_set.token.to_s}
        ]
      }
      result = mechanical_turk_requester.createHIT(props)
      if result[:HITTypeId].present?
        token_set.update_attributes!(hit_id: result[:HITTypeId])
        puts "Find HIT at: https://workersandbox.mturk.com/mturk/preview?groupId=#{result[:HITTypeId]} with token: #{token_set.token}"
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
    ids = client.list_hits.hits.pluck(:hit_id)
    ids.each do |id|
      begin
        resp = client.delete_hit(hit_id: id)
      rescue 
        p resp
        print "Hit cannot be deleted. Try expiring hit? (y/n)"
        yes_no = STDIN.gets.chomp
        if yes_no == 'y'
          resp = client.update_expiration_for_hit(hit_id: id, expire_at: Time.now)
        end
        # in the future: try (for HITs with status 'Reviewable')
        # resp = list_assignments_for_hit(hit_id: id, assignment_statuses: ["Submitted"])
        # ai = resp.assignments[0].assignment_id
        # client.approve_assignment(assignment_id: ai)
      else
        puts "Hit successfully deleted."
      end
    end
  end

  def self.delete_hit(hit_id, production=false)
    client = production ? self.production_client : self.client
    resp = client.delete_hit(hit_id: hit_id)
  end


  private

  def self.client
    Aws::MTurk::Client.new(endpoint: 'https://mturk-requester-sandbox.us-east-1.amazonaws.com')
  end

  def self.production_client
    Aws::MTurk::Client.new
  end
end
