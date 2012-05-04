require 'error_enum'
require 'node'
class Document
  include Mongoid::Document
	field :owner_email, :type => String
	field :doc_type, :type => String
	field :doc_id, :type => String
	field :attr, :type => Hash
	field :doc_tree, :type => Tree::Serializer
	field :created_at, :type => Integer, default: -> { Time.now.to_i }
	field :updated_at, :type => Integer
# 0 not destroyed
# -1 destroyed
	field :status, :type => Integer, default: 0

	before_save :set_updated_at
	before_update :set_updated_at

	private
	def set_updated_at
		self.updated_at = Time.now.to_i
	end

	public

	# obtain document instance given its id
	def self.find_by_id(document_id)
		return Document.where(:doc_id => document_id, :status.gt => -1)[0]
	end

	# create document given meta data
	def self.create_document(owner_email, doc_type, attr)
		document = new(:owner_email => owner_email, :doc_type => doc_type, :attr=> attr)
#document.save
		return document
	end

	# destroy a document given its id
	def remove_document
		self.status = -1
		self.save
		return self
	end

	def self.remove_document(document_id)
		document = find_by_id(document_id)
		return ErrorEnum::DOCUMENT_NOT_EXIST if document == nil
		return document.remove_document
	end

	# update a document's attr
	def update_document(attr)
		self.update_attributes(:attr => attr)
		return self
	end

	def self.update_document(document_id, attr)
		document = find_by_id(document_id)
		return ErrorEnum::DOCUMENT_NOT_EXIST if document == nil
		return document.updat_document
	end

end
