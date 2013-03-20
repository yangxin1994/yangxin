#encoding: utf-8
require 'csv'
class MailgunLog
	include Mongoid::Document
	field :message_id, :type => String, default: false

end
