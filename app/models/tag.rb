# encoding: utf-8
require 'error_enum'
require 'securerandom'
class Tag
	include Mongoid::Document
	include Mongoid::Timestamps
	field :content, :type => String
	
	has_and_belongs_to_many :surveys, validate: false

	validates_uniqueness_of :content


	def self.find_by_content(content)
		return Tag.where(:content => content)[0]
	end

	def self.get_or_create_new(content)
		tag = self.find_by_content(content)
		return tag if !tag.nil?
		tag = Tag.new(:content => content)
		tag.save
		return tag
	end
end
