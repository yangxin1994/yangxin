class Admin::SampleAttributesController< Admin::AdminController
  include SampleAttributesHelper
  layout "layouts/admin_new"

	before_filter :require_sign_in
	before_filter :require_admin
  before_filter :get_client
  before_filter :params_convert, only: [:create, :update]

  def index
    params[:page] ||= 1
    resp = @client.get_attributes(params)
    @attributes = resp.value["data"]
    @paginate = resp.value
  end

  def create
    @client.create_attribute(params[:attribute])
    redirect_to :back
  end

  def update
    @client.update_attribute(params[:id], params[:attribute])
    redirect_to :back
  end

  def destroy
    @client.delete_attribute(params[:id])
    redirect_to :back
  end

  def bind_question
    if request.get?
      @question_client = Admin::QuestionClient.new(session_info)
      @question = @question_client.get_question(params[:id]).value
      @attrs = @client.get_all_attributes(params).value["data"]

      case @question['question_type']
      when 0 # choice
        if @question['issue']['max_choice'] == 1
          @attrs = @attrs.select {|attr| attr['type'] != 7} # except array
        else
          @attrs = @attrs.select {|attr| attr['type'] == 7} # only array
        end
      when 2 # text_blank
        @attrs = @attrs.select {|attr| attr['type'] == 0}
      when 3 # number_blank
        @attrs = @attrs.select {|attr| [2, 4].include? attr['type']}
      when 7 # time_blank
        @attrs = @attrs.select {|attr| [3, 5].include? attr['type']}
      when 8 # addr
        @attrs = @attrs.select {|attr| attr['type'] == 6}
      end
      @addr_precision = 0
      if @question['sample_attribute_id']
        @attr = @attrs.select {|attr| attr['_id'] == @question['sample_attribute_id']}[0]
        if @attr['type'] == 6
          @question['sample_attribute_relation'].each do |key, value|
            addr = QuillCommon::AddressUtility.find_province_city_town_by_code(value)
            next if addr.blank?
            @addr_precision = addr.split(/\s+\-\s+/).length - 1
            break
          end
        end
      end
    elsif request.put?
      params[:relation] = JSON.parse params[:relation]
      @client.bind_attribute(params[:id], params[:attribute_id], params[:relation])
      render json: {}
    elsif request.delete?
      @question_client = Admin::QuestionClient.new(session_info)
      @question_client.remove_attribute_bind(params[:id])
      redirect_to :back
    end
  end

  private
  def get_client
    @client = Admin::SampleAttributeClient.new(session_info)
  end

  def params_convert
    params[:attribute][:type] = params[:attribute][:type].to_i
    params[:attribute][:element_type] = params[:attribute][:element_type].to_i if params[:attribute][:element_type]
    params[:attribute][:date_type] = params[:attribute][:date_type].to_i if params[:attribute][:date_type]
    if params[:attribute][:analyze_requirement] && params[:attribute][:analyze_requirement][:segmentation]
      params[:attribute][:analyze_requirement][:segmentation].map! { |val| val.to_i }
    end
  end
end
