# encoding: utf-8
require 'error_enum'
class AnswerAuditor::SurveysController < AnswerAuditor::ApplicationController

	def index
		if @current_user.is_admin
			@surveys = Survey.where(
					user_attr_survey: false, 
					:new_survey => false, 
					:publish_status.gt => 2
				)
		else
			@surveys = @current_user.answer_auditor_allocated_surveys
		end

		@show_surveys = @surveys.page(page).per(per_page)
		@show_surveys = @show_surveys.to_a.map{|elem| 
			elem['not_review_answer_num']= elem.answers.where(status: 2, finish_type: 0).count
			elem
		}

		render_json_auto (auto_paginate(@show_surveys, @surveys.count){@show_surveys}) and return
	end
end
