class Ability
	include CanCan::Ability

	def initialize(user)
		user ||= User.new # guest user (not logged in)

		case
		when user.manager?
			can :manage, User
			can :read, :all

		when user.editor?
			can :manage, TourResult
			can :manage, ExclusionArea
			can :read, :all

		else
			can :read, :all
		end
	end
end
