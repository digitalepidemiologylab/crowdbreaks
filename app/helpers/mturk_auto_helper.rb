module MturkAutoHelper
  def cron(new_batch_each)
    "0 0 1 */#{new_batch_each} ? *"
  end
end
