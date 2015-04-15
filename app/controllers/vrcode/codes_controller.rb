# encoding: utf-8
require 'error_enum'
class Vrcode::CodesController < Vrcode::VrcodeController
  def index
    redirect_to login_account_url unless current_user.present?
    @code = current_user.get_verify_code
  end

  def create
    render_json_e ErrorEnum::REQUIRE_LOGIN  and return unless current_user.present?
    current_user.add_verify_code_reward
    render_json_s current_user.get_verify_code
  end
end