# encoding: utf-8
require 'error_enum'
require 'tool'
require 'securerandom'

class ScaleIssue < Issue
  attr_reader :items, :is_rand, :item_num_per_group, :labels, :show_unknown, :show_style
  attr_writer :items, :is_rand, :item_num_per_group, :labels, :show_unknown, :show_style

  ATTR_NAME_ARY = %w[items is_rand item_num_per_group labels show_unknown show_style]
  ITEM_ATTR_ARY = %w[id content]

  ANSWER_TIME = 4

  def initialize
    @items = []
    @is_rand = false
    @show_unknown = false
    @labels = ["很不满意", "不太满意", "一般", "比较满意", "很满意"]
    @show_style = 0

    input_number = 4
    1.upto(input_number) do |item_index|
      item = {}
      item["id"] = Tool.rand_id
      item["content"] = {"text" => "选项#{Tool.convert_digit(item_index)}",
                                                  "image" => [], "audio" => [], "video" => []}
      @items << item
    end
  end

  def update_issue(issue_obj)
    issue_obj["show_style"] = issue_obj["show_style"].to_i
    issue_obj["items"] ||= []
    issue_obj["items"].each do |item_obj|
      item_obj.delete_if { |k, v| !ITEM_ATTR_ARY.include?(k) }
    end
    super(ATTR_NAME_ARY, issue_obj)
  end

  def remove_hidden_items(items)
    return if items.blank?
    if !items["items"].blank?
      self.items.delete_if { |item| items["items"].include?(item["id"]) }
    end
  end

  def estimate_answer_time
    text_length = 0
    self.items.each do |item|
      text_length = text_length + item["content"]["text"].length
    end
    return text_length / OOPSDATA[Rails.env]["words_per_second"].to_i + ANSWER_TIME
  end

  #*description*: serialize the current instance into a question object
  #
  #*params*:
  #
  #*retval*:
  #* the question object
  def serialize
    super(ATTR_NAME_ARY)
  end
end
