
class SuperAdmin::UsersController < SuperAdmin::ApplicationController
	
	before_filter :check_user_existence

	def check_user_existence
		@user = User.find_by_id_including_deleted(params[:id])
		render_json_auto(ErrorEnum::USER_NOT_EXIST) and return if @user.nil?
	end

	def set_admin
		retval = @user.set_admin(params[:admin])
		render_json_auto(retval) and return
	end
end