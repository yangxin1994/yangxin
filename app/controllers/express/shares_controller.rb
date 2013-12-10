require 'error_enum'
class Express::SharesController < Express::ExpressController
  
  before_filter :current_step
  before_filter :ensure_survey

  def show
    @share_link = 'http://www.baidu.com'
  end


  def current_step
    @current_step = 2
  end
end