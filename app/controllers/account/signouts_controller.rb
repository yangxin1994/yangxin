class Account::SignoutsController < ApplicationController
  
  # PAGE
  def show
  	_sign_out params[:ref]
  end

end
