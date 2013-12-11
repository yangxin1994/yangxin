require 'error_enum'
class Express::SharesController < Express::ExpressController
  include QRCoder
  before_filter :current_step
  before_filter :ensure_survey

  def show
    @survey = Survey.find(params[:questionaire_id])
    render_404 unless @survey
    reward_scheme_id = @survey.scheme_id
    @share_link = "#{Rails.application.config.quillme_host}#{show_s_path(reward_scheme_id)}"
    @share_link = "#{Rails.application.config.quillme_host}/#{MongoidShortener.generate(@share_link)}"
    @output_file = Rails.root + "/public/qrcode/#{@survey.id}.png"
    unless File.exist?(@output_file)
      QRCode.image("#{@share_link}", "#{Rails.root}" + '/public/qrcode', { :format => :png , :filename => "#{@survey.id}" })
    end
    @output_file = Rails.root + "/qrcode/#{@survey.id}.png"    
  end

  def current_step
    @current_step = 2
  end
end