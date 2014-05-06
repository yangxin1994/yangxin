class Api::UsersController < ApplicationController
  def qauth
    render_json params[:akr].present? do
      success_true User.auth_remote(params[:akr], params[:notoken])
    end
  end
end
