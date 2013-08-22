# coding: utf-8
require 'array'
require 'error_enum'
require 'quill_common'
class Admin::AnswersController < Admin::ApplicationController

	before_filter :check_answer_existence

	def check_answer_existence
		@answer = Answer.find_by_id(params[:id])
		render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return if @answer.nil?
	end

	def show
		respond_to do |format|
			format.json	{ render_json_auto(@answer) and return }
		end
	end

	def destroy
		retval = @answer.delete
		render_json_auto(retval) and return 
	end
end
