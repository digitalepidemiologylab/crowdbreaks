class Project < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged
  has_many :questions
  has_many :transitions
  has_many :results
  has_many :mturk_batch_jobs
  has_many :local_batch_jobs

  translates :title, :description

  validates_presence_of :title, :description

  default_scope { order(created_at: :asc)  }

  def display_name
    title
  end

  def initial_question
    first_transition = transitions.find_by(from_question: nil)
    return nil if first_transition.nil?
    first_transition.to_question
  end

  def self.is_up_to_date(remote_config)
    # test if given stream configuration is identical to projects
    return false if remote_config.length != Project.where(active_stream: true).count
    remote_config.each do |c|
      p = Project.find_by(slug: c[0])
      return false if p.nil?
      if p.keywords.sort != c[1]['keywords'].sort
        return false
      end
      if p.lang.sort != c[1]['languages'].sort
        return false
      end
      if p.es_index_name != c[1]['es_index_name']
        return false
      end
    end
    return true
  end
end
