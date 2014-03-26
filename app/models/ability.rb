class Ability
	include CanCan::Ability

	def initialize(user)
		user ||= User.new # guest user (not logged in)
		if user.manager?
			can :manage, :all
		elsif user.editor?
			can :edit, TourResult
		else
			can :read, :all
		end
	end
end
