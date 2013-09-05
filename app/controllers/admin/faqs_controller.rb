class Admin::FaqsController < Admin::AdminController

	layout 'admin_new'

	before_filter :get_client

	def get_client
		@client = BaseClient.new(session_info, "/admin/faqs")
	end

	def index
		@faqs = @client._get({:page => page,:per_page => per_page})	
		_sign_out and return if @faqs.require_admin?

		respond_to do |format|
			format.html
			format.json { render json: @faqs}
		end
	end

	def show
		@faq = @client._get({}, "/#{params[:id]}")
		_sign_out and return if @faq.require_admin?

		respond_to do |format|
			format.html
			format.json { render json: @faq}
		end
	end

	def create
		@result = @client._post(
			{
				:faq => {question: params[:question], answer: params[:answer]}
			})
		render_result
	end

	def update
		@result = @client._put(
			{
				:faq => {question: params[:question], answer: params[:answer]}
			}, 
			"/#{params[:id]}")
		render_result
	end

	def destroy
		@result = @client._delete({}, "/#{params[:id]}")
		render_result
	end

end