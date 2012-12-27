class Admin::AdvertisementsController < Admin::ApplicationController

	def maping(advertisement)
		advertisement['user_email'] = User.find(advertisement['user_id'].to_s).email
		advertisement
	end

	# GET /admin/advertisements
	# GET /admin/advertisements.json
	def index
		@advertisements = Advertisement.all 
		if params[:advertisement_type]
			types = []
			Advertisement::MAX_TYPE.downto(0).each { |element| 
				if params[:advertisement_type].to_i / (2**element) == 1 then
					types << 2**element
				end
			}
			@advertisements = @advertisements.where(:advertisement_type.in => types)
		end
		@advertisements = @advertisements.where(:title => Regexp.new(params[:title].to_s)) if params[:title]
		@advertisements =  @advertisements.where(:activate => params[:activate].to_s == 'true') if params[:activate]
			
		render_json_auto auto_paginate(@advertisements.desc(:created_at))

	end
	
	# GET /admin/advertisements/1 
	# GET /admin/advertisements/1.json
	def show
		@advertisement = Advertisement.find_by_id(params[:id])
		@advertisement = maping(@advertisement) if @advertisement.is_a? Advertisement

		respond_to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @advertisement }
		end
	end

	# GET /admin/advertisements/new
	# GET /admin/advertisements/new.json
	def new
		@advertisement = Advertisement.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render_json_auto @advertisement }
		end
	end

	# GET /admin/advertisements/1/edit
	def edit
		@advertisement = Advertisement.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @advertisement }
		end
	end
	
	# POST /admin/advertisements
	# POST /admin/advertisements.json
	def create
		render_json_auto Advertisement.create_advertisement(params[:advertisement], @current_user)	
	end

	# PUT /admin/advertisements/1
	# PUT /admin/advertisements/1.json
	def update
		render_json_auto Advertisement.update_advertisement(params[:id], params[:advertisement], @current_user)
	end

	# DELETE /admin/advertisements/1
	# DELETE /admin/advertisements/1.json
	def destroy
		render_json_auto Advertisement.destroy_by_id(params[:id])
	end

end
