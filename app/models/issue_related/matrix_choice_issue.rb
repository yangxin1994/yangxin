# encoding: utf-8
require 'error_enum'
require 'tool'
require 'securerandom'
#Besides the fields that all types questions have, matrix choice questions also have:
# {
#    "choices" : array of choice items(array),
#    "min_choice" : number of choices that user at least selects(integer),
#    "max_choice" : number of choices that user at most selects(integer),
#    "is_rand" : whether randomly show choices(bool),
#    "row_name" : array of row names(array),
#    "" : array of row id(array),
#    "is_row_rand" : whether randomly show rows(bool),
#    "row_num_per_group" : number of rows in each group(integer)
#   }
#The element in the "choice" array has the following structure
# {
#  "choice_id": the id of this choice input
#  "content": the content of the choice(string),
#  "has_input": whether there is a input field(bool),
#  "is_exclusive": whether this choice item is exclusive(bool)
# }
class MatrixChoiceIssue < Issue

    attr_reader :items, :min_choice, :max_choice, :option_type, :show_style, :is_rand, :rows, :is_row_rand, :row_num_per_group
    attr_writer :items, :min_choice, :max_choice, :option_type, :show_style, :is_rand, :rows, :is_row_rand, :row_num_per_group

    ATTR_NAME_ARY = %w[items min_choice max_choice option_type show_style is_rand rows is_row_rand row_num_per_group]
    CHOICE_ATTR_ARY = %w[id content is_exclusive]
    ROW_ATTR_ARY = %w[id content]

    ANSWER_TIME = 2

    def initialize
        @min_choice = 1
        @max_choice = 1
        @option_type = 0
        @show_style = 0
        @is_rand = false    
        @is_row_rand = false    
        @row_num_per_group = -1 
        @items = []
        @rows = []
        1.upto(4) do |id|
            row = {}
            row["id"] = Tool.rand_id
            row["content"] = {"text" => "子题目#{Tool.convert_digit(id)}",
                                                        "image" => [], "audio" => [], "video" => []}
            @rows << row
        end
        1.upto(4) do |input_index|
            choice = {}
            choice["id"] = Tool.rand_id
            choice["content"] = {"text" => "选项#{Tool.convert_digit(input_index)}",
                                                        "image" => [], "audio" => [], "video" => []}
            choice["is_exclusive"] = false
            @items << choice
        end
    end

    def update_issue(issue_obj)
        issue_obj["items"] ||= []
        issue_obj["items"].each do |choice_obj|
            choice_obj.delete_if { |k, v| !CHOICE_ATTR_ARY.include?(k) }
            choice_obj["is_exclusive"] = choice_obj["is_exclusive"].to_s == "true"
        end
        issue_obj["rows"].each do |row_obj|
            row_obj.delete_if { |k, v| !ROW_ATTR_ARY.include?(k) }
        end
        issue_obj["min_choice"] = issue_obj["min_choice"].to_i
        issue_obj["max_choice"] = issue_obj["max_choice"].to_i
        issue_obj["option_type"] = issue_obj["option_type"].to_i
        issue_obj["row_num_per_group"] = issue_obj["row_num_per_group"].to_i
        issue_obj["show_style"] = issue_obj["show_style"].to_i
        issue_obj["is_rand"] = issue_obj["is_rand"].to_s == "true"
        issue_obj["is_row_rand"] = issue_obj["is_row_rand"].to_s == "true"
        super(ATTR_NAME_ARY, issue_obj)
    end

    def remove_hidden_items(items)
        return if items.blank?
        self.items.delete_if { |choice| items["items"].include?(choice["id"]) } if !items["items"].blank?
        self.rows.delete_if { |row| items["sub_questions"].include?(row["id"]) } if !items["sub_questions"].blank?
    end

    def estimate_answer_time
        text_length = 0
        self.items.each do |item|
            text_length = text_length + item["content"]["text"].length
        end
        self.rows.each do |row|
            text_length = text_length + row["content"]["text"].length
        end
        return text_length / OOPSDATA[Rails.env]["words_per_second"].to_i + ANSWER_TIME * self.rows.length
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
