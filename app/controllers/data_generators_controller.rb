# encoding: utf-8
require 'faker'

class DataGeneratorsController < ApplicationController
	http_basic_authenticate_with :name => "quill", :password => "oopsdata"


	def index
	end

	def generate
		@user_status_shown = ["未注册", "未激活", "未填写个人基本信息", "未填写详细信息问卷", "已完成初始化步骤"]
		@survey_status_shown = ["正常", "已删除"]
		@survey_publish_status_shown = ["", "关闭中", "审核中", "", "暂停中", "", "", "" "发布中"]

		clear(User)
		@users = []
		number = 3
		(0..4).each do |status|
			@users << generate_users(number, status)
		end

		clear(Survey)
		normal_users = @users[-1]
		@surveys = []
		@surveys << generate_survey(normal_users[0]["email"], 0, 1)
		@surveys << generate_survey(normal_users[0]["email"], 0, 2)
		@surveys << generate_survey(normal_users[0]["email"], -1, 1)
		@surveys << generate_survey(normal_users[0]["email"], 0, 4)
		@surveys << generate_survey(normal_users[1]["email"], 0, 1)
		@surveys << generate_survey(normal_users[1]["email"], 0, 1)
		tags = Faker::Lorem.words(5)
		@surveys.each do |survey|
			generate_tags(survey, tags.shuffle[1..3])
		end
		#render :text => (@surveys[0].tags.map {|t| t.content}).join(', ') and return
		#render :text => @surveys[0].user.email
	end

	def generate_survey(user_email, status, publish_status)
		survey = {}
		survey["title"] = Faker::Lorem.sentence
		survey["subtitle"] = Faker::Lorem.sentence
		survey["welcome"] = Faker::Lorem.sentence
		survey["closing"] = Faker::Lorem.sentence
		survey["header"] = Faker::Lorem.sentence
		survey["description"] = Faker::Lorem.paragraph
		survey["status"] = status
		survey["publish_status"] = publish_status
		survey_inst = Survey.new(survey)
		survey_inst.save
		survey_inst.user = User.find_by_email(user_email)
		return survey_inst
	end

	def generate_tags(survey, tags)
		tags.each do |tag|
			survey.add_tag(tag)
		end
	end

	def generate_users(number, status)
		# create users that are not registered
		users = []
		number.times do |n|
			user = {}
			user["email"] = Faker::Internet.email
			user["username"] = user["email"]
			user["password"] = (0...6).map{ ('a'..'z').to_a[rand(26)] }.join
			user["status"] = status
			user["status_shown"] = @user_status_shown[status]
			user.merge("password" => Encryption.encrypt_password(user["password"]))
			user_inst = User.new(user.merge("password" => Encryption.encrypt_password(user["password"])))
			user_inst.save
			users << user
		end
		return users
	end

	def clear(*models)
		models.each do |model|
			model.all.each do |instance|
				instance.destroy
			end
		end
	end
end
