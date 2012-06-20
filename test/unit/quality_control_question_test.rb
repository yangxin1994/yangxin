# encoding: utf-8
require 'test_helper'

class QualityControlQuestionTest < ActiveSupport::TestCase
	test "quality control question (objective) creation" do
		clear(User, QualityControlQuestion)

		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		retval = QualityControlQuestion.create_objective_question(oliver)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = QualityControlQuestion.create_objective_question(jesse)
		assert_equal QualityControlQuestion::OBJECTIVE_QUESTION, retval["question_type"]
		assert_equal jesse.email, retval["creator_email"]
		assert retval["question_id"].start_with?("quality_control")
	end
	
	test "quality control question (matching) creation" do
		clear(User, QualityControlQuestion)

		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		retval = QualityControlQuestion.create_matching_questions(oliver)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = QualityControlQuestion.create_matching_questions(jesse)
		assert_equal QualityControlQuestion::MATCHING_QUESTION, retval[0]["question_type"]
		assert_equal QualityControlQuestion::MATCHING_QUESTION, retval[1]["question_type"]
		assert_equal jesse.email, retval[0]["creator_email"]
		assert_equal jesse.email, retval[1]["creator_email"]
		assert retval[0]["question_id"].start_with?("quality_control")
		assert retval[1]["question_id"].start_with?("quality_control")
	end
	
	test "quality control question show" do
		clear(User, QualityControlQuestion)

		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		objective_question_id = create_quality_control_objective_question(jesse)
		matching_question_id_1, matching_question_id_2 = *create_quality_control_matching_question(jesse)

		objective_question = QualityControlQuestion.find_by_id(objective_question_id)
		retval = objective_question.show(oliver) 
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = objective_question.show(jesse) 
		assert_equal QualityControlQuestion::OBJECTIVE_QUESTION, retval["question_type"]
		assert_equal jesse.email, retval["creator_email"]
		assert retval["question_id"].start_with?("quality_control")

		matching_question = QualityControlQuestion.find_by_id(matching_question_id_1)
		retval = matching_question.show(jesse) 
		assert_equal QualityControlQuestion::MATCHING_QUESTION, retval[0]["question_type"]
		assert_equal QualityControlQuestion::MATCHING_QUESTION, retval[1]["question_type"]
		assert_equal jesse.email, retval[0]["creator_email"]
		assert_equal jesse.email, retval[1]["creator_email"]
		assert retval[0]["question_id"].start_with?("quality_control")
		assert retval[1]["question_id"].start_with?("quality_control")
	end

	test "quality control question update" do
		clear(User, QualityControlQuestion)

		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		objective_question_id = create_quality_control_objective_question(jesse)
		matching_question_id_1, matching_question_id_2 = *create_quality_control_matching_question(jesse)


		objective_question = QualityControlQuestion.find_by_id(objective_question_id)
		objective_question_obj = objective_question.show(jesse) 
		objective_question_obj["is_list_style"] = true
		objective_question_obj["choice_num_per_row"] = 5
		objective_question_obj["choices"] << {"choice_id" => SecureRandom.uuid, "content" => "A"}
		objective_question_obj["choices"] << {"choice_id" => SecureRandom.uuid, "content" => "B"}
		objective_question_obj["answer_choice_id"] = "wrong_choice_id"

		retval = objective_question.update_question(objective_question_obj, oliver)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = objective_question.update_question(objective_question_obj, jesse)
		assert_equal ErrorEnum::WRONG_QUALITY_CONTROL_QUESTION_ANSWER, retval

		objective_question_obj["answer_choice_id"] = objective_question_obj["choices"][0]["choice_id"]
		retval = objective_question.update_question(objective_question_obj, jesse)
		assert_equal true, retval["is_list_style"]
		assert_equal 5, retval["choice_num_per_row"]
		assert_equal 2, retval["choices"].length
		assert_equal retval["choices"][0]["choice_id"], retval["answer_choice_id"]
		retval = QualityControlQuestion.find_by_id(retval["question_id"]).show(jesse) 
		assert_equal true, retval["is_list_style"]
		assert_equal 5, retval["choice_num_per_row"]
		assert_equal 2, retval["choices"].length
		assert_equal retval["choices"][0]["choice_id"], retval["answer_choice_id"]


		matching_question_1 = QualityControlQuestion.find_by_id(matching_question_id_1)
		matching_question_2 = QualityControlQuestion.find_by_id(matching_question_id_2)
		matching_question_1_obj, matching_question_2_obj = *matching_question_1.show(jesse) 
		matching_question_1_obj["choices"] << {"choice_id" => SecureRandom.uuid, "content" => "1A"}
		matching_question_1_obj["choices"] << {"choice_id" => SecureRandom.uuid, "content" => "1B"}
		matching_question_2_obj["choices"] << {"choice_id" => SecureRandom.uuid, "content" => "2A"}
		matching_question_2_obj["choices"] << {"choice_id" => SecureRandom.uuid, "content" => "2B"}
		matching_question_1_obj["matching_question_id"] = "wrong question id"

		matching_question_1_obj["matching_question_id"] = matching_question_2_obj["question_id"]
		matching_question_1_obj["choices"].pop
		retval = matching_question_1.update_question([matching_question_1_obj, matching_question_2_obj], jesse)
		assert_equal ErrorEnum::WRONG_QUALITY_CONTROL_QUESTION_ANSWER, retval

		matching_question_1_obj["choices"] << {"choice_id" => SecureRandom.uuid, "content" => "1B"}
		retval = matching_question_1.update_question([matching_question_1_obj, matching_question_2_obj], jesse)
		assert_equal QualityControlQuestion::MATCHING_QUESTION, retval[0]["question_type"]
		assert_equal QualityControlQuestion::MATCHING_QUESTION, retval[1]["question_type"]
		assert_equal jesse.email, retval[0]["last_mender_email"]
		assert_equal jesse.email, retval[1]["last_mender_email"]
		assert retval[0]["question_id"].start_with?("quality_control")
		assert retval[1]["question_id"].start_with?("quality_control")
		retval = QualityControlQuestion.find_by_id(retval[0]["question_id"]).show(jesse) 
		assert_equal QualityControlQuestion::MATCHING_QUESTION, retval[0]["question_type"]
		assert_equal QualityControlQuestion::MATCHING_QUESTION, retval[1]["question_type"]
		assert_equal jesse.email, retval[0]["last_mender_email"]
		assert_equal jesse.email, retval[1]["last_mender_email"]
		assert retval[0]["question_id"].start_with?("quality_control")
		assert retval[1]["question_id"].start_with?("quality_control")
	end

	test "quality control question delete" do
		clear(User, QualityControlQuestion)

		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		objective_question_id = create_quality_control_objective_question(jesse)
		matching_question_id_1, matching_question_id_2 = *create_quality_control_matching_question(jesse)

		objective_question = QualityControlQuestion.find_by_id(objective_question_id)
		matching_question_2 = QualityControlQuestion.find_by_id(matching_question_id_2)

		retval = objective_question.delete(oliver)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = objective_question.delete(jesse)
		assert retval
		assert_nil QualityControlQuestion.find_by_id(objective_question_id)

		retval = matching_question_2.delete(jesse)
		assert retval
		assert_nil QualityControlQuestion.find_by_id(matching_question_id_1)
		assert_nil QualityControlQuestion.find_by_id(matching_question_id_2)
	end

	test "quality control question list" do
		clear(User, QualityControlQuestion)

		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		objective_question_id_ary = create_multiple_quality_control_objective_question(jesse)
		matching_question_id_ary = create_multiple_quality_control_matching_question(jesse)

		retval = QualityControlQuestion.list_objective_questions(oliver)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = QualityControlQuestion.list_objective_questions(jesse)
		assert_equal objective_question_id_ary.length, retval.length

		retval = QualityControlQuestion.list_matching_questions(jesse)
		assert_equal matching_question_id_ary.length, retval.length

		retval.each do |matching_question_pair|
			assert_equal 2, matching_question_pair.length
		end
	end

	def create_quality_control_objective_question(creator)
		retval = QualityControlQuestion.create_objective_question(creator)
		return retval["question_id"]
	end

	def create_quality_control_matching_question(creator)
		retval = QualityControlQuestion.create_matching_questions(creator)
		return retval.map {|q| q["question_id"]}
	end

	def create_multiple_quality_control_objective_question(creator)
		question_id_ary = []
		retval = QualityControlQuestion.create_objective_question(creator)
		question_id_ary << retval["question_id"]
		retval = QualityControlQuestion.create_objective_question(creator)
		question_id_ary << retval["question_id"]
		retval = QualityControlQuestion.create_objective_question(creator)
		question_id_ary << retval["question_id"]
		return question_id_ary
	end

	def create_multiple_quality_control_matching_question(creator)
		question_id_ary = []
		retval = QualityControlQuestion.create_matching_questions(creator)
		question_id_ary << retval.map {|q| q["question_id"]}
		retval = QualityControlQuestion.create_matching_questions(creator)
		question_id_ary << retval.map {|q| q["question_id"]}
		retval = QualityControlQuestion.create_matching_questions(creator)
		question_id_ary << retval.map {|q| q["question_id"]}
		return question_id_ary
	end
end
