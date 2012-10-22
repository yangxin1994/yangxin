# encoding: utf-8
require 'error_enum'
require 'array'
require 'tool'
require 'digest/md5'
class DataListResult < Result
	include Mongoid::Document
	include Mongoid::Timestamps

	field :answer_info, :type => Array

	belongs_to :survey

end
