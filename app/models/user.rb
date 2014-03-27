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

	def manager?
		self.role == "manager"
	end

	def editor?
		self.role == "editor"
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
