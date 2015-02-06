# encoding: utf-8
class Travel::TravelController < ApplicationController
	before_filter :require_travel_sign_in,:except => [:login]
	before_filter :require_supervisor,:except => [:login]	
	layout "travel"
end
