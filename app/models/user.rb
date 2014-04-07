class User < ActiveRecord::Base
	before_save :set_manager_if_first_user

	# Include default devise modules. Others available are:
	# :confirmable, :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable,
		:recoverable, :rememberable, :trackable, :validatable

	def self.update_role(user, attrs)
		if user.can? :manage, User
			attrs.each do |id, attr|
				User.find(id).update(attr)
			end
		end
	end

	def roles
		(role || "").split(",").map {|r| r.strip }
	end

	def manager?
		roles.include?("manager")
	end

	def editor?
		roles.include?("editor")
	end

	def ability
		@ability ||= Ability.new(self)
	end

	delegate :can?, :cannot?, to: :ability

	private

	def set_manager_if_first_user
		if User.all.count == 0
			self.role = "manager"
		end
	end
end
