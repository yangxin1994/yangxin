# coding: utf-8

class Admin::FaqsController < Admin::ApplicationController

	def maping(faq)
		faq['user_email'] = User.find(faq['user_id'].to_s).email
		faq
	end
 
	# GET /admin/faqs
	# GET /admin/faqs.json
	def index
		if !params[:faq_type].nil? then
			if !params[:value].nil? then
				@faqs = Faq.list_by_type_and_value(params[:faq_type], params[:value])
			else
				@faqs = Faq.list_by_type(params[:faq_type])
			end

			@faqs = slice((@faqs || []), page, per_page)
		else
			@faqs = Faq.all.desc(:updated_at).page(page).per(per_page)
		end		

		respond_to do |format|
			format.html # index.html.erb
			format.json { render_json_auto @faqs}
		end
	end

	def count
		render_json_auto Faq.count
	end

	def list_by_type_count
		@public_notices = PublicNotice.list_by_type(params[:public_notice_type]) 
		render_json_auto @public_notices.count
	end

	def list_by_type_and_value_count
		@public_notices = PublicNotice.list_by_type_and_value(params[:public_notice_type], params[:value])
		render_json_auto @public_notices.count
	end
	
	# GET /admin/faqs/1 
	# GET /admin/faqs/1.json
	def show
		@faq = Faq.find_by_id(params[:id])
		@faq = maping(@faq) if @faq.is_a? Faq

		respond_to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @faq }
		end
	end

	# GET /admin/faqs/new
	# GET /admin/faqs/new.json
	def new
		@faq = Faq.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render_json_auto @faq }
		end
	end

	# GET /admin/faqs/1/edit
	def edit
		@faq = Faq.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @faq }
		end
	end
	
	# POST /admin/faqs
	# POST /admin/faqs.json
	def create
		@faq = Faq.create_faq(params[:faq], @current_user)	
			
		respond_to do |format|
			format.html  if @faq.instance_of?(Faq)
			format.html { render action: "new" } if !@faq.instance_of?(Faq)
			format.json { render_json_auto @faq}
		end
	end

	# PUT /admin/faqs/1
	# PUT /admin/faqs/1.json
	def update
		@faq = Faq.update_faq(params[:id], params[:faq], @current_user)

		respond_to do |format|
			format.html { redirect_to @faq} if @faq.instance_of?(Faq)
			format.html { render action: "edit" } if !@faq.instance_of?(Faq)
			format.json { render_json_auto @faq}
		end
	end

	# DELETE /admin/faqs/1
	# DELETE /admin/faqs/1.json
	def destroy
		@faq = Faq.destroy_by_id(params[:id])

		respond_to do |format|
			format.html { redirect_to faqs_url }
			format.json { render_json_auto @faq}
		end
	end
	
end
