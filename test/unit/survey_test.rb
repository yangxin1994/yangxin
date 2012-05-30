require 'test_helper'

class SurveyTest < ActiveSupport::TestCase
	test "survey creation" do
		clear(User, Survey)

		retval = Survey.new.set_default_meta_data("wrong email")
		assert_equal ErrorEnum::EMAIL_NOT_EXIST, retval, "non-exist user creates survey"

		jesse = init_jesse
		retval = Survey.new.set_default_meta_data(jesse.email)
		assert_not_equal ErrorEnum::EMAIL_NOT_EXIST, retval, "existing user cannot create survey"
		assert_equal "", retval["survey_id"], "newly created survye should have empty id"

		retval = Survey.save_meta_data(jesse.email, retval)
		survey = Survey.find_by_id(retval["survey_id"])
		assert_equal retval["survey_id"], survey._id.to_s, "newly created survye is not correctly saved"
	end

	test "save survey meta data" do
		clear(User, Survey)

		jesse, jesse_s1 = *init_user_and_survey

		jesse_s1_obj = jesse_s1.serialize
		jesse_s1_obj["title"] = "new_title"

		new_jesse_s1_obj = Survey.save_meta_data("wrong_email@test.com", jesse_s1_obj)
		assert_equal ErrorEnum::UNAUTHORIZED, new_jesse_s1_obj, "an unauthorized user saves survey meta data"

		new_jesse_s1_obj = Survey.save_meta_data(jesse.email, jesse_s1_obj)
		assert_equal jesse_s1_obj["title"], new_jesse_s1_obj["title"], "fail to save survey meta data"
	end

	test "survey removement" do
		clear(User, Survey)

		jesse, jesse_s1 = *init_user_and_survey

		retval = jesse_s1.delete("wrong_email@test.com")
		assert_equal ErrorEnum::UNAUTHORIZED, retval, "an unauthorized user delete a survey"

		retval = jesse_s1.delete(jesse.email)
		assert_equal -1, jesse_s1.status, "unable to delete a survey"
	end

	test "survey recover" do
		clear(User, Survey)

		jesse, jesse_s1 = *init_user_and_survey

		retval = jesse_s1.recover(jesse.email)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST, retval

		retval = jesse_s1.clear("wrong_email@test.com")
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		jesse_s1.delete(jesse.email)
		retval = jesse_s1.recover(jesse.email)
		assert_equal true, retval
		assert_equal 0, jesse_s1.status
	end

	test "survey clear" do
		clear(User, Survey)

		jesse, jesse_s1 = *init_user_and_survey

		retval = jesse_s1.clear(jesse.email)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST, retval

		retval = jesse_s1.clear("wrong_email@test.com")
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		jesse_s1.delete(jesse.email)
		retval = jesse_s1.clear(jesse.email)
		assert_equal true, retval
		assert_nil Survey.find_by_id_in_trash(jesse_s1._id)
	end

	test "survey tags update" do
		clear(User, Survey)

		jesse, jesse_s1 = *init_user_and_survey

		retval = jesse_s1.update_tags("wrong_email@test.com", ["tag1", "tag2"])
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = jesse_s1.update_tags(jesse.email, ["tag1", "tag2"])
		assert_equal ["tag1", "tag2"], retval["tags"]
	end

	test "survey tag add" do
		clear(User, Survey)

		jesse, jesse_s1 = *init_user_and_survey

		retval = jesse_s1.add_tag("wrong_email@test.com", "tag1")
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = jesse_s1.add_tag(jesse.email, "tag1")
		assert_equal ["tag1"], retval["tags"]
		
		retval = jesse_s1.add_tag(jesse.email, "tag2")
		assert_equal ["tag1", "tag2"], retval["tags"]
		
		retval = jesse_s1.add_tag(jesse.email, "tag2")
		assert_equal ErrorEnum::TAG_EXIST, retval
	end

	test "survey tag remove" do
		clear(User, Survey)

		jesse, jesse_s1 = *init_user_and_survey
		retval = jesse_s1.add_tag(jesse.email, "tag1")
		retval = jesse_s1.add_tag(jesse.email, "tag2")
		
		retval = jesse_s1.remove_tag("wrong_email@test.com", "tag2")
		assert_equal ErrorEnum::UNAUTHORIZED, retval
		
		retval = jesse_s1.remove_tag(jesse.email, "tag3")
		assert_equal ErrorEnum::TAG_NOT_EXIST, retval
		
		retval = jesse_s1.remove_tag(jesse.email, "tag1")
		assert_equal ["tag2"], retval["tags"]
		
		retval = jesse_s1.remove_tag(jesse.email, "tag2")
		assert_equal [], retval["tags"]
	end

	test "page creation" do
		clear(User, Survey, Question)
		
		jesse, jesse_s1 = *init_user_and_survey

		retval = jesse_s1.create_page("wrong_email@test.com", -1)
		assert_equal ErrorEnum::UNAUTHORIZED, retval, "an unauthorized user creates a page"

		retval = jesse_s1.create_page(jesse.email, 0)
		assert_equal ErrorEnum::OVERFLOW, retval, "insert new page after a non-exist page"

		retval = jesse_s1.create_page(jesse.email, -1)
		assert_equal 1, jesse_s1.pages.length, "fail to insert a new page"
	end

	test "question creation" do
		%w[ChoiceQuestion MatrixChoiceQuestion BlankQuestion MatrixBlankQuestion SortQuestion RankQuestion ConstSumQuestion FileQuestion Paragraph].each do |question_type|
			clear(User, Survey, Question)

			jesse, jesse_s1 = *init_user_and_survey

			retval = jesse_s1.create_question("wrong_email@test.com", 0, -1, question_type)
			assert_equal ErrorEnum::UNAUTHORIZED, retval, "an unauthorized user creates a qeustion"

			retval = jesse_s1.create_question(jesse.email, 0, -1, question_type)
			assert_equal ErrorEnum::OVERFLOW, retval, "insert new question in a non-exist page"

			jesse_s1.create_page(jesse.email, -1)
			retval = jesse_s1.create_question(jesse.email, 0, "1234", question_type)
			assert_equal ErrorEnum::QUESTION_NOT_EXIST, retval, "insert new question after a non-exist question"

			retval = jesse_s1.create_question(jesse.email, 0, -1, "wrong_question_type")
			assert_equal ErrorEnum::WRONG_QUESTION_TYPE, retval, "insert a wrong type question"

			retval = jesse_s1.create_question(jesse.email, 0, -1, question_type)
			assert_equal question_type, retval["question_type"], "fail to create a new question"
		end
	end

	test "question update" do
		clear(User, Survey, Question)

		jesse, jesse_s1, questions = *init_user_and_survey_and_questions

		choice_question_obj = questions[0][0].serialize
		choice_question_obj["min_choice"] = 2
		choice_question_obj["max_choice"] = 4
		choice_question_obj["is_rand"] = true
		choice_question_obj["non_exist_attr"] = 1
		choice_question_obj["choices"] << {"content" => "first choice content", "has_input" => false, "is_exclusive" => false, "non_exist_attr" => 1}

		retval = jesse_s1.update_question("wrong_email@test.com", choice_question_obj["question_id"], choice_question_obj)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = jesse_s1.update_question(jesse.email, "wrong_question_id", choice_question_obj)
		assert_equal ErrorEnum::QUESTION_NOT_EXIST, retval

		retval = jesse_s1.update_question(jesse.email, choice_question_obj["question_id"], choice_question_obj)
		new_choice_question_obj = Question.find_by_id(retval["question_id"]).serialize
		assert_equal 2, new_choice_question_obj["min_choice"]
		assert_equal 4, new_choice_question_obj["max_choice"]
		assert_equal true, new_choice_question_obj["is_rand"]
		assert_nil new_choice_question_obj["non_exist_attr"]
		assert_not_nil new_choice_question_obj["choices"][0]["choice_id"]
		assert_equal "first choice content", new_choice_question_obj["choices"][0]["content"]
		assert_equal false, new_choice_question_obj["choices"][0]["has_input"]
		assert_equal false, new_choice_question_obj["choices"][0]["is_exclusive"]
		assert_nil new_choice_question_obj["choices"][0]["non_exist_attr"]

		matrix_choice_question_obj = questions[0][1].serialize
		matrix_choice_question_obj["row_name"] = %w[row0 row1 row2]
		matrix_choice_question_obj["row_id"] = ["", "", ""]
		matrix_choice_question_obj["is_row_rand"] = false
		matrix_choice_question_obj["row_num_per_group"] = 5
		matrix_choice_question_obj["choices"] << {"content" => "first choice content", "has_input" => false, "is_exclusive" => false}
		retval = jesse_s1.update_question(jesse.email, matrix_choice_question_obj["question_id"], matrix_choice_question_obj)
		new_matrix_choice_question_obj = Question.find_by_id(retval["question_id"]).serialize
		matrix_choice_question_obj["row_name"].each_with_index do |name, index|
			assert_equal "row#{index}", new_matrix_choice_question_obj["row_name"][index]
			assert_not_nil new_matrix_choice_question_obj["row_id"][index]
		end
		assert_equal false, new_matrix_choice_question_obj["is_row_rand"]
		assert_equal 5, new_matrix_choice_question_obj["row_num_per_group"]
		assert_not_nil new_matrix_choice_question_obj["choices"][0]["choice_id"]
		assert_equal "first choice content", new_matrix_choice_question_obj["choices"][0]["content"]
		assert_equal false, new_matrix_choice_question_obj["choices"][0]["has_input"]
		assert_equal false, new_matrix_choice_question_obj["choices"][0]["is_exclusive"]

		sort_question_obj = questions[0][2].serialize
		sort_question_obj["is_rand"] = false
		sort_question_obj["items"] << {"content" => "first sort content", "has_input" => false, "min" => 1, "max" => 2}
		retval = jesse_s1.update_question(jesse.email, sort_question_obj["question_id"], sort_question_obj)
		new_sort_question_obj = Question.find_by_id(retval["question_id"]).serialize
		assert_equal false, new_sort_question_obj["is_rand"]
		assert_not_nil new_sort_question_obj["items"][0]["item_id"]
		assert_equal "first sort content", new_sort_question_obj["items"][0]["content"]
		assert_equal false, new_sort_question_obj["items"][0]["has_input"]
		assert_equal 1, new_sort_question_obj["items"][0]["min"]
		assert_equal 2, new_sort_question_obj["items"][0]["max"]

		blank_question_obj = questions[1][0].serialize
		blank_question_obj["inputs"] << {"label" => "first blank label", "data_type" => "wrong data type"}
		retval = jesse_s1.update_question(jesse.email, blank_question_obj["question_id"], blank_question_obj)
		assert_equal ErrorEnum::WRONG_DATA_TYPE, retval
		blank_question_obj = questions[1][0].serialize
		text_input_properties = {"min_length" => 5, "max_length" => 10, "has_multiple_line" => true, "size" => 2, "non_exist_property" => "any value"}
		blank_question_obj["inputs"] << {"label" => "first blank label", "data_type" => "Text", "properties" => text_input_properties}
		text_input_properties = {"precision" => 0, "min_value" => 2, "max_value" => 20, "unit" => "time"}
		blank_question_obj["inputs"] << {"label" => "second blank label", "data_type" => "Number", "properties" => text_input_properties}
		retval = jesse_s1.update_question(jesse.email, blank_question_obj["question_id"], blank_question_obj)
		new_blank_question_obj = Question.find_by_id(retval["question_id"]).serialize
		assert_not_nil new_blank_question_obj["inputs"][0]["input_id"]
		assert_equal "first blank label", new_blank_question_obj["inputs"][0]["label"]
		assert_equal "Text", new_blank_question_obj["inputs"][0]["data_type"]
		assert_equal 5, new_blank_question_obj["inputs"][0]["properties"]["min_length"]
		assert_equal nil, new_blank_question_obj["inputs"][0]["properties"]["non_exist_property"]
		assert_equal "Number", new_blank_question_obj["inputs"][1]["data_type"]
		assert_equal 0, new_blank_question_obj["inputs"][1]["properties"]["precision"]
		assert_equal 2, new_blank_question_obj["inputs"][1]["properties"]["min_value"]
		assert_equal 20, new_blank_question_obj["inputs"][1]["properties"]["max_value"]
		assert_equal "time", new_blank_question_obj["inputs"][1]["properties"]["unit"]

		matrix_blank_question_obj = questions[1][1].serialize
		matrix_blank_question_obj["row_name"] = %w[row0 row1 row2]
		matrix_blank_question_obj["row_id"] = ["", "", ""]
		matrix_blank_question_obj["is_row_rand"] = false
		matrix_blank_question_obj["row_num_per_group"] = 5
		text_input_properties = {"min_length" => 5, "max_length" => 10, "has_multiple_line" => true, "size" => 2}
		matrix_blank_question_obj["inputs"] << {"label" => "first blank label", "data_type" => "Text", "properties" => text_input_properties}
		retval = jesse_s1.update_question(jesse.email, matrix_blank_question_obj["question_id"], matrix_blank_question_obj)
		new_matrix_blank_question_obj = Question.find_by_id(retval["question_id"]).serialize
		new_matrix_blank_question_obj["row_name"].each_with_index do |name, index|
			assert_equal "row#{index}", new_matrix_blank_question_obj["row_name"][index]
			assert_not_nil new_matrix_blank_question_obj["row_id"][index]
		end
		assert_not_nil new_matrix_blank_question_obj["inputs"][0]["input_id"]
		assert_equal "first blank label", new_matrix_blank_question_obj["inputs"][0]["label"]
		assert_equal "Text", new_matrix_blank_question_obj["inputs"][0]["data_type"]

		rank_question_obj = questions[1][2].serialize
		desc_ary = %w[good normal bad]
		rank_question_obj["items"] << {"icon" => "first icon id", "icon_num" => 4, "has_unknow" => true, "desc_ary" => desc_ary}
		retval = jesse_s1.update_question(jesse.email, rank_question_obj["question_id"], rank_question_obj)
		new_rank_question_obj = Question.find_by_id(retval["question_id"]).serialize
		assert_not_nil new_rank_question_obj["items"][0]["item_id"]
		assert_equal "first icon id", new_rank_question_obj["items"][0]["icon"]
		assert_equal 4, new_rank_question_obj["items"][0]["icon_num"]
		assert_equal true, new_rank_question_obj["items"][0]["has_unknow"]
		desc_ary.each_with_index do |desc, index|
			assert_equal desc, new_rank_question_obj["items"][0]["desc_ary"][index]
		end

		const_sum_question_obj = questions[2][0].serialize
		const_sum_question_obj["sum"] = 200
		const_sum_question_obj["items"] << {"content" => "const sum content", "has_input" => true}
		retval = jesse_s1.update_question(jesse.email, const_sum_question_obj["question_id"], const_sum_question_obj)
		new_const_sum_question_obj = Question.find_by_id(retval["question_id"]).serialize
		assert_equal 200, new_const_sum_question_obj["sum"]
		assert_not_nil new_const_sum_question_obj["items"][0]["item_id"]
		assert_equal "const sum content", new_const_sum_question_obj["items"][0]["content"]
		assert_equal true, new_const_sum_question_obj["items"][0]["has_input"]

		paragraph = questions[2][1].serialize
		paragraph["content"] = "paragraph content"
		paragraph["question_type"] = "Wrong type"
		retval = jesse_s1.update_question(jesse.email, paragraph["question_id"], paragraph)
		new_paragraph = Question.find_by_id(retval["question_id"]).serialize
		assert_equal "paragraph content", new_paragraph["content"]
		assert_equal "Paragraph", new_paragraph["question_type"]

	end

	test "question movement" do
		clear(User, Survey, Question)

		jesse, jesse_s1, questions = *init_user_and_survey_and_questions

		cloned_pages = []
		jesse_s1.serialize["pages"].each do |page|
			cloned_pages << page.clone
		end

		retval = jesse_s1.move_question("wrong_email@test.com", cloned_pages[0][2], 1, cloned_pages[1][1])
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = jesse_s1.move_question(jesse.email, "wrong_question_id", 1, cloned_pages[1][1])
		assert_equal ErrorEnum::QUESTION_NOT_EXIST, retval

		retval = jesse_s1.move_question(jesse.email, cloned_pages[0][2], 3, cloned_pages[1][1])
		assert_equal ErrorEnum::OVERFLOW, retval

		retval = jesse_s1.move_question(jesse.email, cloned_pages[0][2], 1, cloned_pages[2][1])
		assert_equal ErrorEnum::QUESTION_NOT_EXIST, retval

		retval = jesse_s1.move_question(jesse.email, cloned_pages[0][2], 1, cloned_pages[1][1])
		assert retval
		cloned_pages[1].insert(2, cloned_pages[0][2])
		cloned_pages[0].delete(cloned_pages[0][2])
		jesse_s1.pages.each_with_index do |page, page_index|
			page.each_with_index do |question_id, question_index|
				assert_equal cloned_pages[page_index][question_index], question_id
			end
		end
	end 

	test "question clone" do
		clear(User, Survey, Question)

		jesse, jesse_s1, questions = *init_user_and_survey_and_questions

		cloned_pages = []
		jesse_s1.serialize["pages"].each do |page|
			cloned_pages << page.clone
		end

		retval = jesse_s1.clone_question("wrong_email@test.com", cloned_pages[0][2], 1, cloned_pages[1][1])
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = jesse_s1.clone_question(jesse.email, "wrong_question_id", 1, cloned_pages[1][1])
		assert_equal ErrorEnum::QUESTION_NOT_EXIST, retval

		retval = jesse_s1.clone_question(jesse.email, cloned_pages[0][2], 3, cloned_pages[1][1])
		assert_equal ErrorEnum::OVERFLOW, retval

		retval = jesse_s1.clone_question(jesse.email, cloned_pages[0][2], 1, cloned_pages[2][1])
		assert_equal ErrorEnum::QUESTION_NOT_EXIST, retval

		retval = jesse_s1.clone_question(jesse.email, cloned_pages[0][2], 1, cloned_pages[1][1])
		assert retval
		cloned_pages[1].insert(2, retval["question_id"])
		jesse_s1.pages.each_with_index do |page, page_index|
			page.each_with_index do |question_id, question_index|
				assert_equal cloned_pages[page_index][question_index], question_id
			end
		end
	end

	test "question delete" do
		clear(User, Survey, Question)

		jesse, jesse_s1, questions = *init_user_and_survey_and_questions

		cloned_pages = []
		jesse_s1.serialize["pages"].each do |page|
			cloned_pages << page.clone
		end

		retval = jesse_s1.delete_question("wrong_email@test.com", cloned_pages[0][2])
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = jesse_s1.delete_question(jesse.email, "wrong_question_id")
		assert_equal ErrorEnum::QUESTION_NOT_EXIST, retval

		retval = jesse_s1.delete_question(jesse.email, cloned_pages[0][2])
		assert retval
		cloned_pages[0].delete(cloned_pages[0][2])
		jesse_s1.pages.each_with_index do |page, page_index|
			page.each_with_index do |question_id, question_index|
				assert_equal cloned_pages[page_index][question_index], question_id
			end
		end
	end

	test "page show" do
		clear(User, Survey, Question)

		jesse, jesse_s1, questions = *init_user_and_survey_and_questions

		retval = jesse_s1.show_page("wrong_email@test.com", 1)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = jesse_s1.show_page(jesse.email, 4)
		assert_equal ErrorEnum::OVERFLOW, retval

		retval = jesse_s1.show_page(jesse.email, 1)
		assert_equal questions[1][0]._id.to_s, retval[0]["question_id"]
		assert_equal questions[1][1]._id.to_s, retval[1]["question_id"]
		assert_equal questions[1][2]._id.to_s, retval[2]["question_id"]
	end

	test "page clone" do
		clear(User, Survey, Question)

		jesse, jesse_s1, questions = *init_user_and_survey_and_questions

		cloned_pages = []
		jesse_s1.serialize["pages"].each do |page|
			cloned_pages << page.clone
		end

		retval = jesse_s1.clone_page("wrong_email@test.com", 1, 2)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = jesse_s1.clone_page(jesse.email, 3, 2)
		assert_equal ErrorEnum::OVERFLOW, retval
		
		retval = jesse_s1.clone_page(jesse.email, 1, 3)
		assert_equal ErrorEnum::OVERFLOW, retval
		
		retval = jesse_s1.clone_page(jesse.email, 1, 2)
		assert retval

		cloned_pages.each_with_index do |page, page_index|
			page.each_with_index do |question_id, question_index|
				assert_equal question_id, jesse_s1.pages[page_index][question_index]
			end
		end
		assert_equal 4, jesse_s1.pages.length
		assert_equal 3, jesse_s1.pages[3].length
	end

	test "page combine" do
		clear(User, Survey, Question)

		jesse, jesse_s1, questions = *init_user_and_survey_and_questions

		cloned_pages = []
		jesse_s1.serialize["pages"].each do |page|
			cloned_pages << page.clone
		end

		retval = jesse_s1.combine_pages("wrong_email@test.com", 1, 2)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = jesse_s1.combine_pages(jesse.email, -1, 2)
		assert_equal ErrorEnum::OVERFLOW, retval
		
		retval = jesse_s1.combine_pages(jesse.email, 1, 3)
		assert_equal ErrorEnum::OVERFLOW, retval
		
		retval = jesse_s1.combine_pages(jesse.email, 1, 2)
		assert retval
		
		cloned_pages[2].each do |question_id|
			cloned_pages[1] << question_id
		end
		cloned_pages.delete_at(2)

		jesse_s1.pages.each_with_index do |page, page_index|
			page.each_with_index do |question_id, question_index|
				assert_equal cloned_pages[page_index][question_index], question_id
			end
		end
	end

	test "page move" do
		clear(User, Survey, Question)

		jesse, jesse_s1, questions = *init_user_and_survey_and_questions

		cloned_pages = []
		jesse_s1.serialize["pages"].each do |page|
			cloned_pages << page.clone
		end

		retval = jesse_s1.move_page("wrong_email@test.com", 1, 2)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = jesse_s1.move_page(jesse.email, 3, 2)
		assert_equal ErrorEnum::OVERFLOW, retval

		retval = jesse_s1.move_page(jesse.email, 1, 3)
		assert_equal ErrorEnum::OVERFLOW, retval

		retval = jesse_s1.move_page(jesse.email, 1, 2)

		cloned_pages.insert(3, cloned_pages[1])
		cloned_pages.delete_at(1)

		jesse_s1.pages.each_with_index do |page, page_index|
			page.each_with_index do |question_id, question_index|
				assert_equal cloned_pages[page_index][question_index], question_id
			end
		end
	end

	test "page delete" do
		clear(User, Survey, Question)

		jesse, jesse_s1, questions = *init_user_and_survey_and_questions

		cloned_pages = []
		jesse_s1.serialize["pages"].each do |page|
			cloned_pages << page.clone
		end

		retval = jesse_s1.delete_page("wrong_email@test.com", 1)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = jesse_s1.delete_page(jesse.email, 1)
		assert retval

		deleted_page = cloned_pages[1]
		cloned_pages.delete_at(1)

		jesse_s1.pages.each_with_index do |page, page_index|
			page.each_with_index do |question_id, question_index|
				assert_equal cloned_pages[page_index][question_index], question_id
			end
		end

		deleted_page.each do |question_id|
			assert_nil Question.find_by_id(question_id)
		end
		
	end




	def init_user_and_survey
		jesse = init_jesse
		jesse_s1 = FactoryGirl.build(:jesse_s1)
		jesse_s1.save
		return [jesse, jesse_s1]
	end

	def init_user_and_survey_and_questions
		jesse, jesse_s1 = *init_user_and_survey

		retval = jesse_s1.create_page(jesse.email, -1)
		retval = jesse_s1.create_page(jesse.email, 0)
		retval = jesse_s1.create_page(jesse.email, 1)

		retval = jesse_s1.create_question(jesse.email, 0, -1, "ChoiceQuestion")
		retval = jesse_s1.create_question(jesse.email, 0, -1, "MatrixChoiceQuestion")
		retval = jesse_s1.create_question(jesse.email, 0, -1, "SortQuestion")

		retval = jesse_s1.create_question(jesse.email, 1, -1, "BlankQuestion")
		retval = jesse_s1.create_question(jesse.email, 1, -1, "MatrixBlankQuestion")
		retval = jesse_s1.create_question(jesse.email, 1, -1, "RankQuestion")

		retval = jesse_s1.create_question(jesse.email, 2, -1, "ConstSumQuestion")
		retval = jesse_s1.create_question(jesse.email, 2, -1, "Paragraph")
		retval = jesse_s1.create_question(jesse.email, 2, -1, "FileQuestion")

		questions = []
		questions << []
		questions << []
		questions << []
		questions[0] << Question.find_by_id(jesse_s1.pages[0][0])
		questions[0] << Question.find_by_id(jesse_s1.pages[0][1])
		questions[0] << Question.find_by_id(jesse_s1.pages[0][2])
		questions[1] << Question.find_by_id(jesse_s1.pages[1][0])
		questions[1] << Question.find_by_id(jesse_s1.pages[1][1])
		questions[1] << Question.find_by_id(jesse_s1.pages[1][2])
		questions[2] << Question.find_by_id(jesse_s1.pages[2][0])
		questions[2] << Question.find_by_id(jesse_s1.pages[2][1])
		questions[2] << Question.find_by_id(jesse_s1.pages[2][2])

		return [jesse, jesse_s1, questions]
	end

end
