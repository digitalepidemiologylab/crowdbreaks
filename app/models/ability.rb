class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new

    can :manage, :question_sequence
    can :manage, :page
    can :read, Project

    if user.admin?
      can :manage, :all
    elsif user.collaborator?
      can :manage, LocalBatchJob
      can :view, :admin_dashboard
      can :view, :manage_dashboard
    elsif user.contributor?
      can :manage, LocalBatchJob
    end

  end
end
