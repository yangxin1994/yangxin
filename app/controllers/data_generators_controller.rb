# encoding: utf-8
require 'faker'

class DataGeneratorsController < ApplicationController
	http_basic_authenticate_with :name => "quill", :password => "oopsdata"
	def index
	end

	def generate
		clear(User)
		# create users that are not registered
		@users = []
		3.times do |n|
			user = {}
			user["email"] = Faker::Internet.email
			user["username"] = user["email"]
			user["password"] = (0...6).map{ ('a'..'z').to_a[rand(26)] }.join
			user["status"] = 0
			user["status_shown"] = "未注册"
			user.merge("password" => Encryption.encrypt_password(user["password"]))
			user_inst = User.new(user.merge("password" => Encryption.encrypt_password(user["password"])))
			user_inst.save
			@users << user
		end
		# create users that are registered but not activated
		3.times do |n|
			user = {}
			user["email"] = Faker::Internet.email
			user["username"] = user["email"]
			user["password"] = (0...6).map{ ('a'..'z').to_a[rand(26)] }.join
			user["status"] = 1
			user["status_shown"] = "未激活"
			user.merge("password" => Encryption.encrypt_password(user["password"]))
			user_inst = User.new(user.merge("password" => Encryption.encrypt_password(user["password"])))
			user_inst.save
			@users << user
		end
		# create users that are activated but not initialized
		3.times do |n|
			user = {}
			user["email"] = Faker::Internet.email
			user["username"] = user["email"]
			user["password"] = (0...6).map{ ('a'..'z').to_a[rand(26)] }.join
			user["status"] = 2
			user["status_shown"] = "未填写个人基本信息"
			user.merge("password" => Encryption.encrypt_password(user["password"]))
			user_inst = User.new(user.merge("password" => Encryption.encrypt_password(user["password"])))
			user_inst.save
			@users << user
		end
		# create users that have not answered the user attributes survey
		3.times do |n|
			user = {}
			user["email"] = Faker::Internet.email
			user["username"] = user["email"]
			user["password"] = (0...6).map{ ('a'..'z').to_a[rand(26)] }.join
			user["status"] = 3
			user["status_shown"] = "未填写详细信息问卷"
			user.merge("password" => Encryption.encrypt_password(user["password"]))
			user_inst = User.new(user.merge("password" => Encryption.encrypt_password(user["password"])))
			user_inst.save
			@users << user
		end
		# create users that finish initialization
		3.times do |n|
			user = {}
			user["email"] = Faker::Internet.email
			user["username"] = user["email"]
			user["password"] = (0...6).map{ ('a'..'z').to_a[rand(26)] }.join
			user["status"] = 4
			user["status_shown"] = "已完成初始化步骤"
			user.merge("password" => Encryption.encrypt_password(user["password"]))
			user_inst = User.new(user.merge("password" => Encryption.encrypt_password(user["password"])))
			user_inst.save
			@users << user
		end
	end


	def clear(*models)
		models.each do |model|
			model.all.each do |instance|
				instance.destroy
			end
		end
	end
end
