class Samples::User
	def self.set_test_users
		::User.create(email: "test@test.com", password: "testtest", role: "manager")
		::User.create(email: "test2@test.com", password: "testtest", role: "editor")
	end
end
