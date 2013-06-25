require 'tool'
class Prize
	include Mongoid::Document
	include Mongoid::Timestamps

	NORMAL = 1
	DELETED = 2
	REAL = 1
	VIRTUAL = 2

	# 1 normal, 2 deleted
	field :status, :type => Integer, default: NORMAL
	# 1 for real prize, 2 for virtual prize
	field :type, :type => Integer, default: REAL
	field :title, :type => String, default: ""
	field :description, :type => String, default: ""
	field :quantity, :type => Integer, default: 0

	has_one :photo, :class_name => "Material", :inverse_of => 'prize'

	default_scope order_by(:created_at.desc)

	scope :normal, where(:status => NORMAL)
	scope :real, normal.where(:type => REAL)
	scope :virtual, normal.where(:type => VIRTUAL)

	index({ type: 1, status: 1 }, { background: true } )

	def self.find_by_id(prize_id)
		return self.normal.where(:_id => prize_id).first
	end

	def self.create_prize(prize)
		material_id = prize.delete("material_id")
		material = Material.find_by_id(material_id)
		return ErrorEnum::MATERIAL_NOT_EXIST if material.nil?
		prize = Prize.new(prize)
		prize.photo = material
		return prize.save
	end

	def update_prize(prize)
		material_id = prize.delete("material_id")
		material = Material.find_by_id(material_id)
		return ErrorEnum::MATERIAL_NOT_EXIST if material.nil?
		self.update_attributes(prize)
		self.photo = material
		return self.save
	end

	def self.search_prize(title, type)
		prizes = Prize.normal
		prizes = prizes.where(:title => /#{title}/) if !title.blank?
		prizes = prizes.where(:type.in => Tool.convert_int_to_base_arr(type)) if !type.blank? && type != 0
		return prizes
	end

	def delete_prize
		self.status = DELETED
		return self.save
	end

	def self.check_params(prize)
		material_id = prize["material_id"]
		material = Material.find_by_id(material_id)
		return ErrorEnum::MATERIAL_NOT_EXIST if material.nil?
		return Errorenum::WRONG_PRIZE_TYPE if ![1,2,4].include?(prize["type"].to_i)
		return true
	end
end
