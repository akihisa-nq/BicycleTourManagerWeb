class User < ActiveRecord::Base
	before_save :set_manager_if_first_user

	# Include default devise modules. Others available are:
	# :confirmable, :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable,
		:recoverable, :rememberable, :trackable, :validatable

	def manager?
		self.role == "manager"
	end

	def editor?
		self.role == "editor"
	end

	private

	def set_manager_if_first_user
		if User.all.count == 0
			self.role = "manager"
		end
	end
end
