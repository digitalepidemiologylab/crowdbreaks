class AdminAbility
  include CanCan::Ability

  # Defines all abilities under /admin namespace

  def initialize(user)
    user ||= User.new
    if user.admin? || user.super_admin?
      can :manage, :all
    elsif user.collaborator?
      can :view, :manage_dashboard
      can :view, :admin_dashboard
      can :manage, Project
      cannot :destroy, Project
      can :manage, :question_sequence
      can :manage, Result
    elsif user.contributor?
      # to be specified
    end
  end
end
