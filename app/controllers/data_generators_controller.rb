# encoding: utf-8
require 'faker'
require 'question_type_enum'

class DataGeneratorsController < ApplicationController
	http_basic_authenticate_with :name => "quill", :password => "oopsdata"

	@@question_type_ary = [QuestionTypeEnum::EMAIL_BLANK_QUESTION,
		QuestionTypeEnum::TEXT_BLANK_QUESTION,
		QuestionTypeEnum::NUMBER_BLANK_QUESTION,
		QuestionTypeEnum::CHOICE_QUESTION,
		QuestionTypeEnum::TIME_BLANK_QUESTION,
		QuestionTypeEnum::CONST_SUM_QUESTION,
		QuestionTypeEnum::RANK_QUESTION]

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

		clear(Question)

	end

	def generate_questions_for_survey(user_email, survey_id, question_type)
		page_number = (3 + 2 * rand).round
		0.upto(page_number-1).each do |page_index|
			question_number = (3 + 2 * rand).round
			question_number.times do
				question_type_index = (rand * (@@question_type_ary.length - 1)).round
				question_type = question_type_ary[question_type_index]

				question = Question.create_question(question_type)
				question_id = question._id
				survey = Survey.find_by_id(survey_id)
				survey.pages[page_index]["questions"].insert(0, question_id)
				survey.save
				case question_type
				when QuestionTypeEnum::EMAIL_BLANK_QUESTION
					question.issue = generate_email_blank_question_issue
				when QuestionTypeEnum::TEXT_BLANK_QUESTION
					question.issue = generate_text_blank_question_issue
				when QuestionTypeEnum::NUMBER_BLANK_QUESTION
					question.issue = generate_number_blank_question_issue
				when QuestionTypeEnum::CHOICE_QUESTION
					question.issue = generate_choice_question_issue
				when QuestionTypeEnum::CONST_SUM_QUESTION
					question.issue = generate_const_sum_question_issue
				when QuestionTypeEnum::RANK_QUESTION
					question.issue = generate_rank_question_issue
				end
				question.save
			end
		end
	end

	def generate_number_blank_question_issue
		issue = {}
		issue["precision"] = (round * 4).round
		issue["min_value"] = rand * 4
		issue["min_value"] = 4 + rand * 4
	end

	def generate_text_blank_question_issue
		issue = {}
		issue["min_length"] = (rand * 4).round
		issue["max_length"] = 4 + (rand * 4).round
		issue["has_multiple_line"] = rand > 0.5
		issue["size"] = (rand * 2).round
		return issue
	end

	def generate_email_blank_question_issue
		issue = {}
		return issue
	end

	def generate_choice_question_issue
		issue = {}
		issue["is_rand"] = rand > 0.5
		issue["is_list_style"] = rand > 0.5
		issue["min_choice"] = 1
		issue["max_choice"] = (rand * 3 + 1).round
		issue["choice_num_per_row"] = -1
		issue["choices"] = []
		(3 + 2 * rand).round.times do |input_index|
			choice = {}
			choice["input_id"] = input_index
			choice["content"] = {}
			choice["content"]["text"] = Faker::Lorem.paragraph
			choice["is_exclusive"] = rand > 0.5
			issue["choices"] << choice
		end
		issue["other_item"] = {}
		issue["other_item"]["has_other_item"] = rand > 0.5
		if issue["other_item"]["has_other_item"]
			issue["other_item"]["input_id"] = issue["choices"].length + 1
			issue["other_item"]["content"] = {}
			issue["other_item"]["content"]["text"] = Faker::Lorem.paragraph
			issue["other_item"]["is_exclusive"] = rand > 0.5
		end
		return issue
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
