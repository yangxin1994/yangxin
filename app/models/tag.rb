# encoding: utf-8
# already tidied up
require 'error_enum'
require 'securerandom'
class Tag
    include Mongoid::Document
    include Mongoid::Timestamps
    field :content, :type => String
    
    has_and_belongs_to_many :surveys, validate: false

    index({ content: 1 }, { background: true } )

    validates_uniqueness_of :content
end
