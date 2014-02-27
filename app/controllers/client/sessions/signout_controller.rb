# already tidied up
class Client::Sessions::SignoutController < Client::ApplicationController

  # PAGE: show sign in
  def index
    Client.logout(current_client._id)
    session[:auth_key] = ""
    redirect_to "/client/signin"
  end

  # AJAX: sign in
end
