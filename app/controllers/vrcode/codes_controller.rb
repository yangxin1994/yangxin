# encoding: utf-8
require 'error_enum'
class Vrcode::CodesController < Vrcode::VrcodeController
  def start
  	img_ata = current_user.get_verify_code
  	@img    = img_ata[:url1]
  	@cid    = img_ata[:id]
  	@ip     = img_ata[:ip]
  end
  def create
    current_user.add_verify_code_reward(params)
    render_json_s current_user.get_verify_code
  end
end