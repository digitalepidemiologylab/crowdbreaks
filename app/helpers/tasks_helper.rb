module TasksHelper
  def mturk_url(hittype_id, sandbox)
    sandbox_url = sandbox ? 'workersandbox' : 'www'
    "https://#{sandbox_url}.mturk.com/mturk/preview?groupId=#{hittype_id}"
  end
end
