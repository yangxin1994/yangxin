class Vrcode::VrcodeController < ApplicationController
  layout "app"
  before_filter :require_sign_in
end
