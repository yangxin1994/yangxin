class Interviewer::ApplicationController < ApplicationController
	before_filter :require_interviewer

end