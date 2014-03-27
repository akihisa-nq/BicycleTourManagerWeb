require 'spec_helper'

describe User do
	it "update roles for all users" do
		user1 = User.create(email: "test@test.com", password: "testtest")
		expect(user1.role).to eq "manager"

		user2 = User.create(email: "test2@test.com", password: "testtest")
		expect(user2.role).to eq nil

		attrs = {
			user1.id => { role: "editor" },
			user2.id => { role: "manager" },
		}
		User.update_role(user1, attrs)

		user1 = User.find(user1.id)
		expect(user1.role).to eq "editor"

		user2 = User.find(user2.id)
		expect(user2.role).to eq "manager"
	end
end
