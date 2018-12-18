namespace :tasks do
  desc "Clean tasks"
  task cleanup_assigned: :environment do
    desc "Deletes assigned/failed tasks"
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end
    batch_name = ENV['batch_name']
    if batch_name.present?
      puts "Selecting tasks from batch #{batch_name}..."
      tasks = MturkBatchJob.find_by(name: batch_name).tasks.assigned
    else
      tasks = Task.all.assigned
    end

    if tasks.count == 0
      Rails.logger.info('No assigned tasks found. Aborting...') and next
    end
    Rails.logger.info("Found in total #{tasks.length} assigned tasks. Delete now? (y/n?)")
    yes_no = STDIN.gets.chomp
    if yes_no == 'y'
      Rails.logger.info("Starting to delete...")
      tasks.destroy_all
    else
      Rails.logger.info("Aborting.") and next
    end
    Rails.logger.info("Successfully finished.")
  end
end
