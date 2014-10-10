$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__),'..', 'lib'))
require 'pry'
require 'mongoid'
require 'micro_spider'
require "nlpir"
require 'logger'
require "spider/proxies"
require "spider/common"
require "spider/comments"
require "spider/movies"
require "spider/reviews"
require "spider/trailers"
require "spider/news"
require "spider/weibos_new"
require "spider/weibo_apis"
require "spider/boxes"
require "spider/photos"
require "spider/movie_schedules"

Mongoid.load!("config/mongoid.yml", :development)

class OopSpider
  include Spider::Common
  include Spider::Comments
  include Spider::Movies
  include Spider::Reviews
  include Spider::Trailers
  include Spider::News
  include Spider::Weibos
  include Spider::WeiboApis
  include Spider::Proxies
  include Spider::Boxes
  include Spider::Photos
  include Spider::MovieSchedules

  def initialize(subject_id = nil)
    super()
    if subject_id
      @movie = Movie.find_by(:subject_id => subject_id)
      @movie.update_attribute :on_crawl, true
    end
    
  end

end

