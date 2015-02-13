class QuilluController < ApplicationController
  # before_filter :require_sign_in, :only => [:list_tasks, :show_survey]

  def login
    user = User.find_by_email(params[:user]["email_username"].to_s)
    render_json_e ErrorEnum::USER_NOT_EXIST and return if user.nil?
    render_json_e ErrorEnum::WRONG_PASSWORD and return if user.password != Encryption.encrypt_password(params[:user]["password"].to_s)
    user.update_attributes({auth_key: Encryption.encrypt_auth_key("#{user._id}&#{Time.now.to_i.to_s}"),
      auth_key_expire_time: params[:keep_signed_in] ? -1 : Time.now.to_i + OOPSDATA["login_keep_time"].to_i})
    retval = {
      status: 4,
      user_id: user._id.to_s,
      auth_key: user.auth_key}
    render_json_auto retval and return
  end

  def list_tasks
    retval = current_user.interviewer_tasks.map { |e| e.info_for_interviewer }
    render_json_auto retval and return
  end

  def show_survey
    survey = Survey.find_by_id(params[:survey_id])
    render_json_auto survey and return
  end

  def show_page
    survey = Survey.find_by_id(params[:survey_id])
    render_json_auto survey.show_page(params[:page_id].to_i) and return
  end

  def find_provinces
    provinces = QuillCommon::AddressUtility.find_provinces
    render_json_s provinces and return
  end

  def find_cities_by_province
    cities = QuillCommon::AddressUtility.find_cities_by_province(params[:province_code].to_i)
    render_json_s cities and return
  end

  def find_towns_by_city
    counties = QuillCommon::AddressUtility.find_towns_by_city(params[:city_code].to_i)
    render_json_s counties and return
  end

  def find_address_text_by_code
    text = QuillCommon::AddressUtility.find_province_city_town_by_code(params[:code])
    render_json_s text and return
  end

  def submit_answers
    interviewer_task = InterviewerTask.find_by_id(params[:interviewer_task_id])
    render_json_auto(ErrorEnum::INTERVIEWER_TASK_NOT_EXIST) and return if interviewer_task.nil?
    Rails.logger.info "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    Rails.logger.info interviewer_task.id.to_s
    Rails.logger.info interviewer_task.user.try(:email)
    Rails.logger.info params[:answers].length
    Rails.logger.info "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    retval = interviewer_task.submit_answers(params[:answers])
    render_json_auto(retval) and return
  end

  def submit_material
    material_type = params[:material_type].to_i
    render_json_e(ErrorEnum::WRONG_MATERIAL_TYPE) and return if ![8,16,32].include?(material_type)
    path = "uploads/"
    Dir.mkdir('public/uploads') if !File.directory?('public/uploads')
    case params[:material_type].to_i
    when 8
      path += "images/"
      Dir.mkdir('public/uploads/images') if !File.directory?('public/uploads/images')
    when 16
      path += "videos/"
      Dir.mkdir('public/uploads/videos') if !File.directory?('public/uploads/videos')
    when 32
      path += "audios/"
      Dir.mkdir('public/uploads/audios') if !File.directory?('public/uploads/audios')
    end
    path += SecureRandom.uuid
    File.open("public/#{path}", "wb") { |f| f.write(params[:file].read) }
    material = {"material_type" => params[:material_type],
          "title" => params[:file].original_filename,
          "value" => path}
    material_inst = Material.check_and_create_new(nil, material)
    render_json_auto(material_inst._id.to_s) and return
  end

  def show_material
      @material = Material.find_by_id(params[:material_id])
      respond_to do |format|
          format.html { 
              url = @material.picture_url
              redirect_to(url.blank? ? '/assets/materials/no-image.png' : URI.encode(url.strip)) and return
          }
          format.json { render_json_auto @material and return }
      end
  end

  def preview_material
      url = nil
      material = Material.find_by_id(params[:material_id])
      if material.present?
          case material.material_type
          when 1 # image
              url = material.picture_url
              url = '/assets/materials/no-image.png' if url.blank?
          when 2 # audio
              url = '/assets/materials/music.png'
          when 4 # video
              url = material.picture_url
              if url.blank?
                  url = TudouClient.video_pic_url(material.value)
                  # update the preview page
                  if url.present?
                      material.picture_url = url
                      material.save
                      # @ws_client.update(material['_id'], material)
                  end
              end
              url = '/assets/materials/no-video.png' if url.blank?
          else
          end
      end
      redirect_to(url.blank? ? '/assets/materials/no-image.png' : URI.encode(url.strip))
  end
end
