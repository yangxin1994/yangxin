class Vrcode::VrcodeController < ApplicationController
  layout 'sample'
  before_filter :require_sign_in
end
