# encoding: utf-8
require 'error_enum'
require 'array'
require 'tool'
require 'digest/md5'
class ReportResult < Result
	include Mongoid::Document
	include Mongoid::Timestamps

	field :file_uri, :type => String

	belongs_to :survey

end
