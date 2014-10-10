require 'mongoid'
require File.expand_path('../nlpir', __FILE__)
dir = File.dirname(__FILE__) 
Dir[File.expand_path("#{dir}/model/*.rb")].uniq.each do |file| require file end
Mongoid.load!("config/mongoid.yml", :development)
