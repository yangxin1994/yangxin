class Utility::MaterialsController < ApplicationController
    layout false

    before_filter :require_sign_in, :only => [:index, :video_upload_path, :create, :create_image, :update, :destroy]

    # Ajax: get materials list
    def index
        materials = current_user.materials.find_by_type(params[:material_type].to_i)
        render_json_auto materials and return
        # render :json => @ws_client.index(params[:material_type])
    end

    # AJAX get video upload path
    def video_upload_path
        render json: TudouClient.video_upload_path
    end

    # AJAX
    def create
        # image = ImageUploader.new
        # image.store!(params[:imagesrc])
        if params[:material_type].to_i == 1
            params[:material] = {}
            image = ImageUploader.new
            image.store!(params[:imagesrc])
            params[:material][:value] = image.url
            params[:material][:type] = 1
            params[:material][:title] = params[:material_title]
            session_info.auth_key = params[:auth_key]
            # @ws_client = Utility::MaterialClient.new(session_info)
        end

        material = Material.check_and_create_new(current_user, params[:material])
        render_json_auto material
    end

    # AJAX. upload image
    def create_image
        if true
            image = ImageUploader.new
            image.store!(params[:image_src])
            render :json => image.url
        else
            render :json => false
        end
    end

    # AJAX
    def destroy
        material = current_user.materials.find_by_id(params[:id])
        material.destroy if !material.nil?
        render_json_s and return

        # render :json => @ws_client.destroy(params[:id])
    end

    # Page or Ajax
    # Html: show the html page for the material
    # Json: show the data of the material
    def show
        @material = Material.find_by_id(params[:id])
        respond_to do |format|
            format.html { 
                if @material.material_type == 1
                    url = @material.picture_url
                    redirect_to(url.blank? ? '/assets/materials/no-image.png' : URI.encode(url.strip)) and return
                end
                return 
            }
            format.json { render_json_auto @material and return }
        end
    end

    # AJAX
    def update
        material = current_user.materials.find_by_id(params[:id])
        render_json_e ErrorEnum::MATERIAL_NOT_EXIST and return if material.nil?
        retval = material.update_material(params[:material])
        render_json_e material and return
    end

    # PAGE
    def preview
        url = nil
        material = Material.find_by_id(params[:id])
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