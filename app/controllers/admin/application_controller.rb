class Admin::ApplicationController < ApplicationController
	before_filter :require_admin
end