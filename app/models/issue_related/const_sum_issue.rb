# encoding: utf-8
require 'error_enum'
require 'tool'
require 'securerandom'
#Besides the fields that all types questions have, const sum questions also have:
# {
#    "items" : array of items(array),
#    "is_rand" : whether randomly show blanks(bool)
#    "sum" : sum value(int)
#   }
#The element in the "item" array has the following structure
# {
#    "item_id": id of the input
#  "content": content of the item(string),
#  "has_input": whether there is a input text field(bool)
# }
class ConstSumIssue < Issue

    attr_reader :items, :other_item, :is_rand, :sum, :show_style
    attr_writer :items, :other_item, :is_rand, :sum, :show_style

    ATTR_NAME_ARY = %w[items other_item is_rand sum show_style]
    ITEM_ATTR_ARY = %w[id content]
    OTHER_ITEM_ATTR_ARY = %w[has_other_item id content]

    ANSWER_TIME = 4

    def initialize
        @items = []
        @is_rand = false
        @sum = 100
        @show_style = 0

        input_number = 4
        1.upto(input_number) do |item_index|
            item = {}
            item["id"] = Tool.rand_id
            item["content"] = {"text" => "选项#{Tool.convert_digit(item_index)}",
                                                        "image" => [], "audio" => [], "video" => []}
            @items << item
        end
        @other_item = {"has_other_item" => false, "id" => Tool.rand_id, "content" => {"text" => "其他（请填写）：", "image" => [], "video" => [], "audio" => []}}
    end

    def update_issue(issue_obj)
        issue_obj ||= []
        issue_obj["items"].each do |item_obj|
            item_obj.delete_if { |k, v| !ITEM_ATTR_ARY.include?(k) }
        end
        issue_obj["sum"] = issue_obj["sum"].to_i
        issue_obj["other_item"] ||= {}
        issue_obj["other_item"].delete_if { |k, v|  !OTHER_ITEM_ATTR_ARY.include?(k)}
        issue_obj["other_item"]["has_other_item"] = issue_obj["other_item"]["has_other_item"].to_s == "true"
        super(ATTR_NAME_ARY, issue_obj)
    end

    def remove_hidden_items(items)
        return if items.blank?
        if !items["items"].blank?
            self.items.delete_if { |item| items["items"].include?(item["id"]) }
            if self.other_item["has_other_item"] == true && items["items"].include?(self.other_item["id"])
                self.other_item = {"has_other_item" => false}
            end
        end
    end

    def estimate_answer_time
        text_length = 0
        self.items.each do |item|
            text_length = text_length + item["content"]["text"].length
        end
        text_length = text_length + self.other_item["content"]["text"].length if !self.other_item.nil? && self.other_item["has_other_item"] == true
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
