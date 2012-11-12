# encoding: utf-8
require 'error_enum'
class AnswerAuditor::SurveysController < AnswerAuditor::ApplicationController

	def index
		render_json_auto auto_paginate(@current_user.answer_auditor_allocated_surveys)
	end
end
