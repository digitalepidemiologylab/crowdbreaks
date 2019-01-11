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
  scope :for_current_locale, -> {where("'#{I18n.locale.to_s}' = ANY (locales)")}

  enum storage_mode: [:'s3-es', :'s3-es-no-retweets', :s3, :test_mode]

  def display_name
    title
  end

  def initial_question
    first_transition = transitions.find_by(from_question: nil)
    return nil if first_transition.nil?
    first_transition.to_question
  end

  def to_csv
    CSV.generate do |csv|
      # questions
      csv << ['Questions']
      question_cols = ['id', 'question', 'instructions']
      csv << question_cols
      questions.each do |question|
        csv << question.attributes.values_at(*question_cols)
      end
      # answers
      csv << ['Answers']
      answer_cols = ['id', 'answer']
      csv << answer_cols
      questions.each do |question|
        question.answers.each do |answer|
          csv << answer.attributes.values_at(*answer_cols)
        end
      end
    end
  end

  def self.is_up_to_date(remote_config)
    # test if given stream configuration is identical to projects
    return false if remote_config.nil?
    return false if remote_config.length != Project.where(active_stream: true).count
    remote_config.each do |c|
      p = Project.find_by(slug: c['slug'])
      return false if p.nil?
      if p.keywords.sort != c['keywords'].sort
        return false
      end
      if p.lang.sort != c['lang'].sort
        return false
      end
      if p.es_index_name != c['es_index_name']
        return false
      end
      if p.storage_mode != c['storage_mode']
        return false
      end
    end
    return true
  end
end
