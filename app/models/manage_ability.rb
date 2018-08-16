class ManageAbility
  include CanCan::Ability

  # Defines all abilities under /manage namespace
  
  def initialize(user)
    user ||= User.new
    if user.admin?
      can :manage, :all
    elsif user.collaborator?
      # dashboard - pipeline
      can :view, :dashboard
      can :configure, :streaming
      can :manage, :elasticsearch_index
      # dashboard - mturk
      can :manage, MturkBatchJob
      can :manage, MturkTweet
      can :manage, MturkWorker
      can :list, :hits
      # dashboard - other
      can :view, :sentiment_analysis
      cannot :view, :user_activity
      can :manage, LocalBatchJob
    elsif user.contributor?
      # to be specified
    end
  end
end
