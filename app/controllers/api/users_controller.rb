class Api::UsersController < ApplicationController
  def auth
    render_json params[:auth_key_remote].present? do
      User.auth_remote(params[:auth_key_remote].present?)
    end
  end
end
