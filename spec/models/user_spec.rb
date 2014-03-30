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

	describe "guest" do
		it "can only read" do
			User.create(email: "test@test.com", password: "testtest")

			user = User.new(email: "test2@test.com", password: "testtest")
			user.role = nil
			user.save!

			expect(user.editor?).to eq false
			expect(user.manager?).to eq false

			expect(user.can? :manage, User).to eq false
			expect(user.can? :manage, TourResult).to eq false
			expect(user.can? :read, TourResult).to eq true
		end
	end

	describe "manager" do
		it "can manage and read" do
			User.create(email: "test@test.com", password: "testtest")

			user = User.new(email: "test2@test.com", password: "testtest")
			user.role = "manager"
			user.save!

			expect(user.editor?).to eq false
			expect(user.manager?).to eq true

			expect(user.can? :manage, User).to eq true
			expect(user.can? :manage, TourResult).to eq false
			expect(user.can? :read, TourResult).to eq true
		end
	end

	describe "editor" do
		it "can edit and read" do
			User.create(email: "test@test.com", password: "testtest")

			user = User.new(email: "test2@test.com", password: "testtest")
			user.role = "editor"
			user.save!

			expect(user.editor?).to eq true
			expect(user.manager?).to eq false

			expect(user.can? :manage, User).to eq false
			expect(user.can? :edit, TourResult).to eq true
			expect(user.can? :read, TourResult).to eq true
		end
	end
end
