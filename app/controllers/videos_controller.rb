require 'net/http'
require 'uri'

class VideosController < ApplicationController

	# GET /videos
	# GET /videos.json
	# def index
	# 	# Get video upload path
	# 	username = "gaoyang0130@163.com"
	# 	password = "000000"
	# 	url = "http://api.tudou.com/v3/gw?method=item.upload&title=gouguo&tags=tg&channelId=1&ipAddr=192.168.1.101&appKey=fa2c499b3f33370e";
	# 	uri = URI.parse(url)
	# 	http = Net::HTTP.new(uri.host, uri.port)
	# 	http.read_timeout = 120
	# 	request = Net::HTTP::Get.new(uri.request_uri)
	# 	request.basic_auth username,password
	# 	@responseBody = http.request(request).body
		
	# 	respond_to do |format|
	# 		format.html # index.html.erb
	# 		format.json { render json: @responseBody }
	# 	end
	# end


	# def videos_info
	# 	url = "http://api.tudou.com/v3/gw?method=item.info.get&appKey=fa2c499b3f33370e&format=json&itemCodes=#{params[:item_codes]}"
	# 	uri = URI.parse(url)
	# 	http = Net::HTTP.new(uri.host, uri.port)
	# 	http.read_timeout = 120
	# 	request = Net::HTTP::Get.new(uri.request_uri)
	# 	@responseBody = http.request(request).body

	# 	respond_to do |format|
	# 		format.json { render json: @responseBody }
	# 	end
	# end

	# def all_videos
	# 	url = "http://api.tudou.com/v3/gw?method=user.item.get&appKey=fa2c499b3f33370e&format=json&user=gaoyang0130@163.com&pageNo=#{params[:page_no]}&pageSize=#{params[:page_size]}";
	# 	uri = URI.parse(url)
	# 	http = Net::HTTP.new(uri.host, uri.port)
	# 	http.read_timeout = 120
	# 	request = Net::HTTP::Get.new(uri.request_uri)
	# 	@responseBody = http.request(request).body

	# 	respond_to do |format|
	# 		format.json { render json: @responseBody }
	# 	end
	# end
end