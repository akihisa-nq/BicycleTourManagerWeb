class Ability
	include CanCan::Ability

	def initialize(user)
		user ||= User.new # guest user (not logged in)

		if user.manager?
			can :manage, User
			can :read, :all
		end

		if user.editor?
			can :manage, TourResult
			can :manage, TourPlan
			can :manage, ExclusionArea
			can :read, :all
		end

		can :read, :all
	end
end
