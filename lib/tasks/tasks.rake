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

    tasks_to_delete = []
    tasks_to_update = []
    tasks.each do |task|
      if task.results.count == 0
        tasks_to_delete.push(task.id)
      else
        tasks_to_update.push(task.id)
      end
    end
    if tasks.count == 0
      Rails.logger.info('No assigned tasks found. Aborting...') and next
    end
    if tasks_to_delete.length > 0
      Rails.logger.info("Found in total #{tasks.length} assigned tasks of which #{tasks_to_delete.length} have no results associated. Delete these now and set others as completed? (y/n?)")
    else
      Rails.logger.info("Found in total #{tasks.length} assigned tasks but all of them have results associated.") and next
    end
    yes_no = STDIN.gets.chomp
    if yes_no == 'y'
      Rails.logger.info("Starting to update/delete...")
      Task.where(id: tasks_to_delete).destroy_all
      Task.where(id: tasks_to_update).update_all(lifecycle_status: :completed)
    else
      Rails.logger.info("Aborting.") and next
    end
    Rails.logger.info("Successfully finished.")
  end
end
