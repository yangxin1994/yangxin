class Admin::SampleAttributesController < Admin::ApplicationController
	before_filter :check_sample_attribute_existence, :only => [:update, :destroy, :bind_question]

	def check_sample_attribute_existence
		@sample_attribute = SampleAttribute.normal.find_by_id(params[:sample_attribute_id])
		if @sample_attribute.nil?
			render_json_e(ErrorEnum::SAMPLE_ATTRIBUTE_NOT_EXIST) and return
		end
	end

	def index
		@sample_attributes = SampleAttribute.search(params[:name])
		render_json_auto (auto_paginate(@sample_attributes)) and return
	end

	def create
		@sample_attribute = SampleAttribute.create_sample_attribute(params[:sample_attribute])
		render_json_auto (@sample_attribute) and return
	end

	def update
		render_json_auto (@sample_attribute.update_sample_attribute(params[:sample_attribute])) and return
	end

	def destroy
		render_json_auto (@sample_attribute.delete) and return
	end

	def bind_question
		render_json_auto (@sample_attribute.bind_question(params[:question_id], params[:relation])) and return
	end
end