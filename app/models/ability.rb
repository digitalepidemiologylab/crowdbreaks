class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new
    if user.admin?
      can :manage, :all
      
      # API controller
      can :configure, :stream
      can :access, :user_activity_data
      can :access, :sentiment_visualization
    else
      # default rule
      can :read, :all

      # test page
      cannot :test, :page

      # question sequence
      can :show, :question_sequence
      can :show, :mturk_question_sequence
      can :create, Result

    end
  end
end
