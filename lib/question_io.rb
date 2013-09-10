# encoding: utf-8
require 'quill_common'
class QuestionIo
  attr_accessor :content, :issue, :question_type, :origin_id, :is_required

  def initialize(q)
    @retval = []
    @csv_header = []
    @spss_header = []
    @header_count = {}
    self.content = q.content
    self.issue = q.issue
    if self.issue["other_item"] && self.issue["other_item"]["has_other_item"]
          issue["items"] << {
            "id" => issue["other_item"]["id"],
            "content" => issue["other_item"]["content"],
            "is_exclusive" => issue["other_item"]["is_exclusive"]
          }
    end
    self.question_type = q.question_type
    self.origin_id = q.id
    self.is_required = q.is_required
  end

  INPUT = "_input"
  VALUE = "_value"
  UNKNOW = "_unkwon"
  SPSS_NUMERIC = "Numeric"
  SPSS_STRING = "String"
  SPSS_STRING_SHORT = "Short"
  SPSS_OPTED = "选中"
  SPSS_NOT_OPTED = "未选中"
  SPSS_ETC = "其它项(内容)"
  SPSS_UNKOWN = "不清楚"

  # csv_header
  # spss_header
  # csv_answer
  # spss_answer
  # load_csv_answer
  def csv_header(header_prefix)
    @csv_header << header_prefix
  end

  def spss_header(header_prefix)
    @spss_header << {"spss_name" => header_prefix,
                "spss_type" => SPSS_STRING,
                "spss_label" => content["text"].gsub(/<[^>]*>/, '').slice(0..120)}
    @header_count[header_prefix] ||= @spss_header.count
    @spss_header
  end

  def excel_header(header_prefix)
    # TODO "重写以提高效率"
    spss_header(header_prefix).map{|s| s['spss_label']}
  end

  def answer_content(v, header_prefix)
    clear_retval
    return Array.new(header_count(header_prefix)) if (v.nil? || v.try("blank?"))
    @retval << (v == {} ? nil : v)
  end

  def answer_import(row, header_prefix)
    blank? row["#{header_prefix}"]
    clear_retval
    @retval = row["#{header_prefix}"]
    return { "#{origin_id}" => @retval}
  end

  def header_count(header_prefix)
    @header_count[header_prefix] || spss_header(header_prefix).count
  end

  def clear_retval
    @retval = []
  end

  def ret
    @retval
  end

  def blank?(answer)
    raise "什么都不填是不可以的!" if is_required && answer.blank?
  end

  def get_item(id)
    self.issue["items"].each do |item|
      return item if item["id"] == id
    end
  end

  def get_item_index(id)
    self.issue["items"].each_with_index do |item, index|
      return index + 1 if item["id"].to_s == id.to_s
    end
    if self.issue["other_item"]["has_other_item"] && issue["other_item"]["id"].to_s == id.to_s
      return self.issue["items"].count + 1
    end
    return nil
  end

  def get_item_id(index)
    return nil if index.nil?
    index = index.to_i - 1
    if self.issue["other_item"]["has_other_item"] && self.issue["items"].count == index
      return self.issue["other_item"]["id"]
    else
      return nil if self.issue["items"].count < index
      self.issue["items"][index]["id"]
    end
  end

  def only_num?(item, options ={})
    item = item.to_s
    if item.nil?
      return true
    else
      if options[:dot]
        rep = /^[-0-9.]+$/
      elsif options[:negative]
        rep = /^[-0-9]+$/
      else
        rep = /^[0-9]+$/
      end
      if ((item =~ rep) == 0)
        if options[:range]
          return (options[:range].include? item.to_i)
        end
        return true
      else
        return false
      end
    end
  end

end

class ChoiceQuestionIo < QuestionIo

  def csv_header(header_prefix)
    if issue["max_choice"].to_i > 1
      issue["items"].each_index do |i|
        @csv_header << header_prefix + "_c#{i + 1}"
      end
    else
      @csv_header << header_prefix
    end
    if issue["other_item"]["has_other_item"]
      @csv_header << header_prefix + INPUT
    end
    return @csv_header
  end

  def spss_header(header_prefix)
   if issue["max_choice"].to_i > 1
      issue["items"].each_index do |i|
        @spss_header << {"spss_name" => header_prefix + "_c#{i + 1}",
                    "spss_type" => SPSS_NUMERIC,
                    "spss_label" => issue["items"][i]["content"]["text"].gsub(/<[^>]*>/, '').slice(0..120),
                    "spss_value_labels" => {1 => SPSS_OPTED,
                                            0 => SPSS_NOT_OPTED}}
      end
    else
      choices = {}
      issue["items"].each_index do |i|
        choices[i+1] = issue["items"][i]["content"]["text"]
      end
      @spss_header << {"spss_name" => header_prefix,
                  "spss_type" => SPSS_NUMERIC,
                  "spss_label" => content["text"].gsub(/<[^>]*>/, '').slice(0..120),
                  "spss_value_labels" => choices }
    end
    if issue["other_item"]["has_other_item"]
      @spss_header << {"spss_name" => header_prefix + INPUT,
                  "spss_type" => SPSS_STRING,
                  "spss_label" => SPSS_ETC}
    end
    @header_count[header_prefix] ||= @spss_header.count
    @spss_header
  end

  def answer_content(v, header_prefix)
    clear_retval
    return Array.new(header_count(header_prefix)) if v.nil?
    if issue["max_choice"].to_i > 1
      issue["items"].each do |item|
        if v["selection"].try("include?", item["id"])
          @retval << 1
        else
          @retval << 0
        end
      end
    else
      @retval <<  get_item_index(v["selection"].try('[]',0))
    end
    if issue["other_item"]["has_other_item"]
      @retval << v["text_input"]
    end
    return @retval
  end

  def answer_import(row, header_prefix)
    @retval = {"text_input" => "",
               "selection" => []}
    choiced = 0
    if issue["max_choice"].to_i > 1
      issue["items"].each_index do |i|
        # blank? row["#{header_prefix}_c#{i+1}"] if row["#{header_prefix}_input"].blank?
        row["#{header_prefix}_c#{i+1}"] = "0" if row["#{header_prefix}_c#{i+1}"].blank?
	blank? row["#{header_prefix}_c#{i+1}"] if row["#{header_prefix}_input"].blank?
	if row["#{header_prefix}_c#{i+1}"] == "1"
          @retval["selection"] << get_item_id(i + 1)
          choiced += 1
        end
      end
      if issue["other_item"]["has_other_item"]
        if !row["#{header_prefix}_input"].blank?
          @retval["text_input"] = row["#{header_prefix}_input"]
          choiced += 1
        end
      end
    else
      blank? row["#{header_prefix}"]
      # 如果空就直接抛出异常了
      choiced += 1
      @retval["selection"] << get_item_id(row[header_prefix])
      if issue["other_item"]["has_other_item"]
        if issue["other_item"]["id"].to_s == get_item_id(row[header_prefix]).to_s
          if row["#{header_prefix}_input"].blank?
            raise "您选了其他项,但是其他项却没有填写呢>.<"
          else
            @retval["text_input"] = row["#{header_prefix}_input"]
          end
        end
      end
    end
    # if issue["other_item"]["has_other_item"]
    #   if !row["#{header_prefix}_input"].blank?
    #     @retval["text_input"] = row["#{header_prefix}_input"]
    #     choiced += 1 if issue["max_choice"].to_i > 1
    #   end
    # end
    if choiced < issue["min_choice"]
      raise "您选择的有点少啊?至少#{issue["min_choice"]}个才可以."
    elsif choiced > issue["max_choice"]
      raise "您选择的稍微多了点,只需要#{issue["max_choice"]}个就可以了~"
    end
    return { "#{origin_id}" => @retval}
  end

  def get_item_id(index)
    return nil if index.nil?
    raise "您确定有这个选项吗?" unless only_num?(index)
    index = index.to_i - 1
    if self.issue["other_item"]["has_other_item"] && self.issue["items"].count == index
      return self.issue["other_item"]["id"]
    else
      raise "您确定有这个选项吗?" unless (0..self.issue["items"].count).include? index
      self.issue["items"][index]["id"]
    end
  end
end

class MatrixChoiceQuestionIo < QuestionIo
  #TODO 矩阵选择题好多悲剧!!! 看清了 答案的格式是二维数组
  def csv_header(header_prefix)
    if issue["max_choice"].to_i > 1
      issue["rows"].each_index do |r|
        issue["items"].each_index do |c|
          @csv_header << header_prefix  + "_r#{r + 1}" + "_c#{c + 1}"
        end
      end
    else
      issue["rows"].each_index do |r|
        @csv_header << header_prefix  + "_r#{r + 1}"
      end
    end
    return @csv_header
  end

  def spss_header(header_prefix)
    if issue["max_choice"].to_i > 1
      issue["rows"].each_index do |r|
        issue["items"].each_index do |c|
          @spss_header << {"spss_name" => header_prefix  + "_r#{r + 1}" + "_c#{c + 1}",
                      "spss_type" => SPSS_NUMERIC,
                      "spss_label" => issue["items"][c]["content"]["text"].gsub(/<[^>]*>/, '').slice(0..120),
                      "spss_value_labels" => {1 => SPSS_OPTED,
                                              0 => SPSS_NOT_OPTED}}
        end
      end
    else
      choices = {}
      issue["items"].each_index do |i|
        choices[i+1] = issue["items"][i]["content"]["text"]
      end
      issue["rows"].each_with_index do |r, i|
        @spss_header << {"spss_name" => header_prefix + "_r#{i + 1}",
                    "spss_type" => SPSS_NUMERIC,
                    "spss_label" => r["content"]["text"].gsub(/<[^>]*>/, '').slice(0..120),
                    "spss_value_labels" => choices }
      end
    end
    @header_count[header_prefix] ||= @spss_header.count
    @spss_header
  end

  def answer_content(v, header_prefix)
    clear_retval
    return Array.new(header_count(header_prefix)) if (v.nil? || v.try("blank?"))
    if issue["max_choice"].to_i > 1
      issue["rows"].each do |item|
        issue["items"].each_index do |c|
          if v[item["id"].to_s] && v[item["id"].to_s].include?( get_item_id(c + 1))
            @retval << 1
          else
            @retval << 0
          end
        end
      end
    else
      issue["rows"].each do |item|
        @retval << (v[item["id"].to_s] && v[item["id"].to_s].blank? ? nil : get_item_index(v[item["id"].to_s][0]))
      end
    end
    return @retval
  end

  def answer_content_2(v, header_prefix)
    clear_retval
    return Array.new(header_count(header_prefix)) if (v.nil? || v.try("blank?"))
    if issue["max_choice"].to_i > 1
      issue["rows"].each do |item|
        issue["items"].each_index do |c|
          if v[item["id"].to_s] && v[item["id"].to_s].include?( get_item_id(c + 1))
            @retval << 1
          else
            @retval << 0
          end
        end
      end
    else
      issue["rows"].each do |item|
        p (v[item["id"].to_s] && v[item["id"].to_s].blank? ? nil : get_item_index(v[item["id"].to_s][0]))
        p get_item_index(v[item["id"].to_s][0])
        @retval << (v[item["id"].to_s] && v[item["id"].to_s].blank? ? nil : get_item_index(v[item["id"].to_s][0]))
      end
    end
    p @retval
    return @retval
  end

  def answer_import(row, header_prefix)
    @retval = {}
    if issue["max_choice"].to_i > 1
      issue["rows"].each_index do |r|
        row_choices = []
        choiced = 0
        issue["items"].each_with_index do |item, c|
          blank? row["#{header_prefix}_r#{r + 1}_c#{c + 1}"]
          if row["#{header_prefix}_r#{r + 1}_c#{c + 1}"] == "1"
            row_choices << get_item_id(c + 1)
            choiced += 1
          end
        end
        if choiced < issue["min_choice"]
          raise "您选择的有点少啊?至少#{issue["min_choice"]}个才可以."
        elsif choiced > issue["max_choice"]
          raise "您选择的稍微多了点,只需要#{issue["max_choice"]}就可以了~"
        end
        @retval[item["id"].to_s] = row_choices
      end

    else
      issue["rows"].each_with_index do |item, r|
        # 单选为啥也要用数组? 不解
        blank? row["#{header_prefix}_r#{r + 1}"]
        @retval[item["id"].to_s] = [get_item_id(row["#{header_prefix}_r#{r + 1}"])]
      end
    end

    return { "#{origin_id}" => @retval }
  end

  # def get_item_id(index)
  #   return nil if index.nil?
  #   index = index.to_i - 1
  #   self.issue["items"][index]["id"]
  # end
  def get_item_id(index)
    return nil if index.nil?
    raise "您填写的内容不像是个数字啊!" unless only_num?(index)
    index = index.to_i - 1
    raise "您确定有这个选项吗?" unless (0..(self.issue["items"].count)).include? index
    self.issue["items"][index]["id"]
  end
  def get_item_index(id)
    self.issue["items"].each_with_index do |item, index|
      return index + 1 if item["id"].to_s == id.to_s
    end
    return nil
  end
end

class TextBlankQuestionIo < QuestionIo
  def answer_import(row, header_prefix)
    blank? row["#{header_prefix}"]
    # if issue["max_length"] > 0 && row["#{header_prefix}"].to_s.length > issue["max_length"]
    #   raise "您输入的文本有些太长了哦,重新检查一下吧!(#{row["#{header_prefix}"].to_s.length}/#{issue["max_length"]})"
    # elsif issue["min_length"] > 0 && row["#{header_prefix}"].to_s.length < issue["min_length"]
    #   raise "您输入的文本长度未免太短了些,重新检查一下吧!(#{row["#{header_prefix}"].to_s.length}/#{issue["min_length"]})"
    # else
    #   @retval = row["#{header_prefix}"]
    # end
    @retval = row["#{header_prefix}"]
    return { "#{origin_id}" => @retval}
  end
end

class NumberBlankQuestionIo < QuestionIo
  def spss_header(header_prefix)
    @spss_header << {"spss_name" => header_prefix,
                "spss_type" => SPSS_NUMERIC,
                "spss_label" => content["text"].gsub(/<[^>]*>/, '').slice(0..120)}
    @header_count[header_prefix] ||= @spss_header.count
    @spss_header
  end
  def answer_import(row, header_prefix)
    blank? row["#{header_prefix}"]
    clear_retval
    raise "这个看起来不像是一个数字啊?" unless only_num?(row["#{header_prefix}"],dot: true, negative: true)
    # todo 精度控制
    if row["#{header_prefix}"].to_f < issue["min_value"].to_f
      raise "这个数字是不是太小了啊"
    elsif row["#{header_prefix}"].to_f > issue["max_value"].to_f
      raise "这个数字是不是太大了啊"
    end
    @retval = row["#{header_prefix}"]
    return { "#{origin_id}" => @retval}
  end
end

class EmailBlankQuesionIo < QuestionIo
  def answer_import(row, header_prefix)
    blank? row["#{header_prefix}"]
    clear_retval
    raise "这个看起来不像是一个邮箱啊?重来一个试试?" unless( (row["#{header_prefix}"] =~ /^[-\w\.]+@([-\w]+\.)+[-\w]{2,4}$/) == 0)
    @retval = row["#{header_prefix}"]
    return { "#{origin_id}" => @retval}
  end
end

class UrlBlankQuestionIo < QuestionIo
end

class PhoneBlankQuestionIo < QuestionIo
  def answer_import(row, header_prefix)
    blank? row["#{header_prefix}"]
    clear_retval
    case issue["phone_type"]
    when 1
      if row["#{header_prefix}"] =~ /^((\d{11})|(\d{3}-\d{8})|(\d{4}-\d{7})|(\d{3}-\d{4}-\d{4}))$/
        @retval = row["#{header_prefix}"]
      elsif row["#{header_prefix}"].blank?
        @retval = row["#{header_prefix}"]
      else
        raise "您填写的这个...不太像是电话号码啊?"
      end
    when 2
      if row["#{header_prefix}"] =~ /^0?(13\d|15[012356789]|18[0236789]|14[57])-?\d{3}-?\d{1}-?\d{4}$/
        @retval = row["#{header_prefix}"]
      elsif row["#{header_prefix}"].blank?
        @retval = row["#{header_prefix}"]
      else
        raise "您填写的这个...不太像是手机号码啊?"
      end
    when 3
      if row["#{header_prefix}"] =~ /^0?(13\d|15[012356789]|18[0236789]|14[57])-?\d{3}-?\d{1}-?\d{4}$/ ||
        row["#{header_prefix}"] =~ /^((\d{11})|(\d{3}-\d{8})|(\d{4}-\d{7})|(\d{3}-\d{4}-\d{4}))$/
        @retval = row["#{header_prefix}"]
      elsif row["#{header_prefix}"].blank?
        @retval = row["#{header_prefix}"]
      else
        raise "您填写的这个...不太像是手机或者电话号码啊?"
      end
    end
    return { "#{origin_id}" => @retval}
  end
end

class TimeBlankQuestionIo < QuestionIo
  @time_unit = ["年", "月", "周", "天", "时", "分", "秒"]
  # @time_unit = ["Y", "M", "W", "D", "H", "M", "S"]
  def answer_content(v, header_prefix)
    clear_retval
    return Array.new(header_count(header_prefix)) if (v.nil? || v.try("blank?"))
    return nil if v == {}
    # @time_unit.each_with_index do |e, i|
    #   @retval << "#{v[i]}#{e}" if v[i] != 0
    # end
    # return @retval
    # raise "这个看起来不太像是时间吧?" unless only_num?(v)
    time = Time.at(v/1000)
    case issue["format"]
    when 0
      @retval << "#{time.year}年"
    when 1
      @retval << "#{time.year}年#{time.month}月"
    when 2
      @retval << "#{time.year}年#{time.month}月#{time.day}日"
    when 3
      @retval << "#{time.year}年#{time.month}月#{time.day}日#{time.hour}时#{time.min}分"
    when 4
      @retval << "#{time.month}月#{time.day}日"
    when 5
      @retval << "#{time.hour}时#{time.min}分"
    when 6
      @retval << "#{time.hour}时#{time.min}分#{time.sec}秒"
    end
    @retval
  end


  def answer_import(row, header_prefix)
    blank? row["#{header_prefix}"]
    clear_retval
    # @time_unit.each_with_index do |e, i|
    #   t = row["#{header_prefix}"][2 * i + 1] == e ? row["#{header_prefix}"][2 * i] : 0
    #   @retval << "#{t}#{e}"
    # end
    time = row["#{header_prefix}"].split(";").map do |t|
      raise "您填写的这个不太像是一个时间啊?" unless only_num?(t)
      t
    end
    time_now = Time.now
    case issue["format"]
    when 0
      @retval = Time.new(time[0]).to_i
    when 1
      @retval = Time.new(time[0], time[1]).to_i
    when 2
      @retval = Time.new(time[0], time[1], time[2]).to_i
    when 3
      @retval = Time.new(time[0], time[1], time[2], time[3]).to_i
    when 4
      @retval = Time.new(time_now.year, time[0], time[0]).to_i
    when 5
      @retval = Time.new(time_now.year, time_now.month, time_now.day, time[0], time[1]).to_i
    when 6
      @retval = Time.new(time_now.year, time_now.month, time_now.day,time[0], time[1], time[2].to_i).to_i
    end

    # TODO
    # if time < issue["min_time"]
    #   raise "这个时间是不是太早了点?"
    # elsif time > issue["max_time"]
    #   raise "这个时间是不是有些晚了?"
    # end


    # pa=/[^\u0030-\u0040]/
    # @retval = row["#{header_prefix}"].gsub(pa, ',').split(",").collect{|s| s.to_i}
    # if row["#{header_prefix}"]
    #   @retval = row["#{header_prefix}"].to_i
    # else
    #   @retval = nil
    # end
    return { "#{origin_id}" => @retval * 1000}
  end
end

class AddressBlankQuestionIo < QuestionIo
  def csv_header(header_prefix)
    @csv_header << "#{header_prefix}"+"_address"
    if issue["format"] == 15
      @csv_header << "#{header_prefix}"+"_detail"
    end
    if issue["has_postcode"]
      @csv_header << "#{header_prefix}"+"_postcode"
    end
    @csv_header
  end

  def spss_header(header_prefix)
    fom = []
    case issue["format"]
    when 8
      fom = ['省']
      fom_pre = ['province']
    when 12
      fom = ['省', '市']
      fom_pre = ['province', 'city']
    when 14
      fom = ['省', '市', '县/区']
      fom_pre = ['province', 'city', 'county']
    when 15
      fom = ['省', '市', '县/区', '详细']
      fom_pre = ['province', 'city', 'county', 'detail']
    end
    fom.each_with_index do |f, index|
      @spss_header << {"spss_name" => "#{header_prefix}_#{fom_pre[index]}",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => f}
    end
    if issue["has_postcode"]
      @spss_header << {"spss_name" => "#{header_prefix}_postcode",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => "邮编"}
    end
    @header_count[header_prefix] ||= @spss_header.count
    @spss_header
  end

  def answer_content(v, header_prefix)
    clear_retval
    return Array.new(header_count(header_prefix)) if (v.nil? || v.try("blank?")) || v == {}
    add = QuillCommon::AddressUtility.find_province_city_town_by_code(v["address"]).strip.split('-')
    case issue["format"]
    when 1 , 2
      @retval << add[0]
    when 3 , 4
      @retval << add[0]
      @retval << add[1]
    when 7 , 8 , 14
      @retval << add[0]
      @retval << add[1]
      @retval << add[2]
    when 15
      @retval << add[0]
      @retval << add[1]
      @retval << add[2]
      @retval << v["detail"]
    end
    if issue["has_postcode"]
      @retval << v["postcode"]
    end
    @retval
    # @retval << "地址:#{Address.find_province_city_town_by_code(v["address"])},详细:#{v["detail"]},邮编:#{v["postcode"]}"
    # @retval << v.join(';')
  end
  def answer_import(row, header_prefix)

    @retval = {}
    blank? row["#{header_prefix}"+"_address"]
    @retval["address"] = row["#{header_prefix}"+"_address"]
    if issue["has_postcode"]
      blank? row["#{header_prefix}"+"_postcode"]
      raise "您填写的不像是个邮编啊" unless only_num?(row["#{header_prefix}"+"_postcode"])
      @retval["postcode"] = row["#{header_prefix}"+"_postcode"]
    end
    if issue["format"] == 15
      blank? row["#{header_prefix}"+"_detail"]
      @retval["detail"] = row["#{header_prefix}"+"_detail"]
    end
    return { "#{origin_id}" => @retval}
  end
end

class BlankQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["items"].each_index do |c|
      @csv_header << header_prefix  + "_c#{c + 1}"
    end
    return @csv_header
  end

  def spss_header(header_prefix)
    issue["items"].each_index do |i|
      @spss_header << {"spss_name" => header_prefix + "_c#{i + 1}",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => issue["items"][i]["content"]["text"].gsub(/<[^>]*>/, '').slice(0..120)}
    end
    @header_count[header_prefix] ||= @spss_header.count
    @spss_header
  end

  def answer_content(v, header_prefix)
    clear_retval
    return Array.new(header_count(header_prefix)) if (v.nil? || v.try("blank?"))
    issue["items"].each_index do |i|
      q = Question.new(:content => issue["items"][i]["content"],
                       :issue => issue["items"][i]["properties"],
                       :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["items"][i]["data_type"]}"])
      qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
      @retval += qi.answer_content(v[i])
    end
    return @retval
  end

  def answer_import(row, header_prefix)
    blank? row["#{header_prefix}"]
    clear_retval
     issue["items"].each_index do |i|
      q = Question.new(:content => issue["items"][i]["content"],
                       :issue => issue["items"][i]["properties"],
                       :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["items"][i]["data_type"]}"])
      qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
      @retval << qi.answer_import(row, "#{header_prefix}_c#{i + 1 }").values[0]
    end
    return { "#{origin_id}" => @retval}
  end
end

class MatrixBlankQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["row_id"].each_index do |r|
      issue["items"].each_index do |c|
        @csv_header << header_prefix  + "_r#{r + 1}" + "_c#{c + 1}"
      end
    end
    return @csv_header
  end

  def spss_header(header_prefix)
    issue["row_id"].each_index do |r|
      issue["items"].each_index do |i|
        @spss_header << {"spss_name" => header_prefix  + "_r#{r + 1}" + "_c#{i + 1}",
                    "spss_type" => SPSS_STRING,
                    "spss_label" => issue["items"][i]["content"]["text"].gsub(/<[^>]*>/, '').slice(0..120)}
      end
    end
    @header_count[header_prefix] ||= @spss_header.count
    @spss_header
  end

  def answer_content(v, header_prefix)
    clear_retval
    return Array.new(header_count(header_prefix)) if (v.nil? || v.try("blank?"))
    issue["row_id"].each_index do |r|
      issue["items"].each_index do |i|
        q = Question.new(:content => issue["items"][i]["content"],
                         :issue => issue["items"][i]["properties"],
                         :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["items"][i]["data_type"]}"])
        qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
        # p "#{r}*#{i}= #{qi}"
        @retval += qi.answer_content(v[r][i])
      end
    end
    return @retval
  end
  def answer_import(row, header_prefix)
    clear_retval
    issue["row_id"].each_index do |r|
      row_content = []
      issue["items"].each_index do |i|
        q = Question.new(:content => issue["items"][i]["content"],
                         :issue => issue["items"][i]["properties"],
                         :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["items"][i]["data_type"]}"])
        qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
        row_content << qi.answer_import(row, "#{header_prefix}_r#{r + 1}_c#{i + 1 }").values[0]
      end
      @retval << row_content
    end
    return { "#{origin_id}" => @retval}
  end
end

class ConstSumQuestionIo < QuestionIo

  def csv_header(header_prefix)
    issue["items"].each_index do |i|
      @csv_header << header_prefix + "_c#{i + 1}"
    end
    if issue["other_item"]["has_other_item"]
      @csv_header << header_prefix + INPUT
      @csv_header << header_prefix + INPUT + VALUE
    end
    return @csv_header
  end

  def spss_header(header_prefix)
    issue["items"].each_index do |i|
      @spss_header << {"spss_name" => header_prefix + "_c#{i + 1}",
                  "spss_type" => SPSS_NUMERIC,
                  "spss_label" => issue["items"][i]["content"]["text"].gsub(/<[^>]*>/, '').slice(0..120)}
    end
    if issue["other_item"]["has_other_item"]
      @spss_header << {"spss_name" => header_prefix + INPUT,
                  "spss_type" => SPSS_STRING,
                  "spss_label" => SPSS_ETC}
      @spss_header << {"spss_name" => header_prefix + INPUT + VALUE,
                  "spss_type" => SPSS_NUMERIC,
                  "spss_label" => issue["other_item"]["content"]["text"].gsub(/<[^>]*>/, '').slice(0..120)}
    end
    @header_count[header_prefix] ||= @spss_header.count
    @spss_header
  end

  def answer_content(v, header_prefix)
    clear_retval
    return Array.new(header_count(header_prefix)) if (v.nil? || v.try("blank?"))
    v.each do |k, c|
      unless k == "text_input" || k == issue["other_item"]["input_id"]
        @retval << c
      end
    end
    if issue["other_item"]["has_other_item"]
      @retval << v["text_input"]
      @retval << v[issue["other_item"]["input_id"]]
    end
    return @retval
  end

  def answer_import(row, header_prefix)
    @retval = {}
    sum = 0.0
    issue["items"].each_with_index do |e, i|
      blank? row["#{header_prefix}_c#{i + 1}"]
      raise "这样的输入是不可以的,换成数字试试?" unless only_num? row["#{header_prefix}_c#{i + 1}"] ,dot: true
      sum += row["#{header_prefix}_c#{i + 1}"].to_f
      @retval[e["id"].to_s] = row["#{header_prefix}_c#{i + 1}"]
    end
    if issue["other_item"]["has_other_item"]
      @retval["text_input"] = row["#{header_prefix + INPUT}"]
      if @retval["text_input"]
        raise "这样的输入是不可以的,换成数字试试?" unless only_num? row["#{header_prefix + INPUT + VALUE}"], dot: true
        @retval["#{issue["other_item"]["input_id"]}"] = row["#{header_prefix + INPUT + VALUE}"]
        sum += row["#{header_prefix + INPUT + VALUE}"].to_f
      end
    end
    if sum > issue["sum"].to_f
      raise "比重的总和超出了#{issue["sum"]}哦,重新检查一下吧!"
    elsif sum < issue["sum"].to_f
      raise "比重的总和不足#{issue["sum"]}哦,重新检查一下吧!"
    end
    return { "#{origin_id}" => @retval}
  end
end

class SortQuestionIo < QuestionIo
  def csv_header(header_prefix)
    if issue["max"] == -1
      item_count = issue["items"].count
    else
      item_count = issue["max"]
    end
    item_count.times do |i|
      @csv_header << header_prefix + "_s#{i + 1}"
    end
    if issue["other_item"]["has_other_item"]
      @csv_header << header_prefix + INPUT
    end
    return @csv_header
  end
  def spss_header(header_prefix)
    if issue["max"] == -1
      item_count = issue["items"].count
    else
      item_count = issue["max"]
    end
    value_labels = {}
    issue["items"].each_with_index do |item, index|
      value_labels[index + 1] = item["content"]["text"]
    end
    item_count.times do |i|
      @spss_header << {"spss_name" => header_prefix + "_s#{i + 1}",
                       "spss_type" => SPSS_NUMERIC,
                       "spss_label" => "第#{i+1}位",
                       "spss_value_labels" => value_labels
                      }
    end
    if issue["other_item"]["has_other_item"]
      @spss_header << {"spss_name" => header_prefix + INPUT,
                       "spss_type" => SPSS_STRING,
                       "spss_label" => SPSS_ETC}
    end
    @header_count[header_prefix] ||= @spss_header.count
    @spss_header
  end

  def answer_content(v, header_prefix)
    clear_retval
    return Array.new(header_count(header_prefix)) if (v.nil? || v.try("blank?"))
    if issue["max"] == -1
      item_count = issue["items"].count
    else
      item_count = issue["max"]
    end
    item_count.times do |i|
      @retval << (v["sort_result"] ? get_item_index(v["sort_result"][i]) : nil)
    end
    if issue["other_item"]["has_other_item"]
      @retval << v["text_input"]
    end
    @retval
  end

  def answer_import(row, header_prefix)
    @retval = {"sort_result" => []}
    if issue["max"] == -1
      item_count = issue["items"].count
    else
      item_count = issue["max"]
    end
    item_count.times do |i|
      blank? row["#{header_prefix}_s#{i + 1}"]
      @retval["sort_result"] << get_item_id(row["#{header_prefix}_s#{i + 1}"]).to_s
    end
    # issue["items"].each_index do |i|
    #   blank? row["#{header_prefix}_c#{i + 1}"]
    #   @retval["sort_result"] << get_item_id(row["#{header_prefix}_c#{i + 1}"]).to_s
    # end
    if issue["other_item"]["has_other_item"]
      @retval["text_input"] = row["#{header_prefix}#{INPUT}"]
      # @retval["sort_result"] << get_item_id(row["#{header_prefix}#{INPUT+VALUE}"]).to_s
    end
    rc = 0
    @retval.each do |a|
      rc += 1 unless a.nil?
    end
    raise "至少要排#{issue["min"]}项才可以哦" if rc < issue["min"]
    return { "#{origin_id}" => @retval}
  end
end

class RankQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["items"].each_index do |i|
      @csv_header << header_prefix + "_c#{i + 1}"
      if issue["items"][i]["has_unknow"]
        @csv_header << header_prefix + "_c#{i + 1}" + UNKNOW
      end
    end
    if issue["other_item"]["has_other_item"]
      @csv_header << header_prefix + INPUT
      @csv_header << header_prefix + INPUT + VALUE
    end
    return @csv_header
  end
  #TODO spss_value_labels
  def spss_header(header_prefix)
    issue["items"].each_index do |i|
      @spss_header << {"spss_name" => header_prefix + "_c#{i + 1}",
                  "spss_type" => SPSS_NUMERIC,
                  "spss_label" => issue["items"][i]["content"]["text"].gsub(/<[^>]*>/, '').slice(0..120)}
      if issue["items"][i]["has_unknow"]
        @spss_header << {"spss_name" => header_prefix + "_c#{i + 1}" + UNKNOW,
                    "spss_type" => SPSS_STRING,
                    "spss_label" => SPSS_UNKOWN
                    }
      end
    end
    if issue["other_item"]["has_other_item"]
      @spss_header << {"spss_name" => header_prefix + INPUT,
                  "spss_type" => SPSS_STRING,
                  "spss_label" => SPSS_ETC}
      @spss_header << {"spss_name" => header_prefix + INPUT + VALUE,
                  "spss_type" => SPSS_NUMERIC,
                  "spss_label" => issue["other_item"]["content"]["text"].gsub(/<[^>]*>/, '').slice(0..120)}
    end
    @header_count[header_prefix] ||= @spss_header.count
    @spss_header
  end
  def answer_content(v, header_prefix)
    clear_retval
    return Array.new(header_count(header_prefix)) if (v.nil? || v.try("blank?"))
    issue["items"].each do |e|
      @retval << v[e["input_id"]]
      (@retval << v[e["input_id"]] == -1 ? 1 : 0) if e["has_unknow"]
    end
    if issue["other_item"]["has_other_item"]
      @retval << v["text_input"]
      @retval << v[issue["other_item"]["input_id"]]
    end
    return @retval
  end
  def answer_import(row, header_prefix)
    @retval = {}
    issue["items"].each_with_index do |e, i|
      @retval["#{e["input_id"]}"] = row["#{header_prefix}_c#{i + 1}"]
    end
    if issue["other_item"]["has_other_item"]
      @retval["text_input"] = row["#{header_prefix + INPUT}"]
      @retval["#{issue["other_item"]["input_id"]}"] = row["#{header_prefix + INPUT + VALUE}"]
    end
    return { "#{origin_id}" => @retval}
  end
end

class ParagraphIo < QuestionIo
  def csv_header(header_prefix)
    @csv_header = []
  end

  def answer_content(v, header_prefix)
    clear_retval
    @retval = []
  end

  def answer_import(row, header_prefix)
    @retval = []
  end

  def spss_header(header_prefix)
    @spss_header = []
    @header_count[header_prefix] ||= @spss_header.count
    @spss_header
  end
end

class FileQuestionIo < QuestionIo

end

class TableQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["items"].each_index do |i|
      @csv_header << header_prefix  + "_c#{i + 1}"
    end
    return @csv_header
  end
  def spss_header(header_prefix)
    issue["items"].each_index do |i|
      @spss_header << {"spss_name" => header_prefix + "_c#{i + 1}",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => issue["items"][i]["content"]["text"].gsub(/<[^>]*>/, '').slice(0..120)}
    end
    @header_count[header_prefix] ||= @spss_header.count
    @retval
  end
  def answer_content(v, header_prefix)
    clear_retval
    return Array.new(header_count(header_prefix)) if (v.nil? || v.try("blank?"))
    issue["items"].each_index do |i|
      q = Question.new(:content => issue["items"][i]["content"],
                       :issue => issue["items"][i]["properties"],
                       :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["items"][i]["data_type"]}"])
      qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
      @retval += qi.answer_content(v[i])
    end
    return @retval
  end
  def answer_import(row, header_prefix)
    clear_retval
    issue["items"].each_index do |i|
      q = Question.new(:content => issue["items"][i]["content"],
                       :issue => issue["items"][i]["properties"],
                       :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["items"][i]["data_type"]}"])
      qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
      @retval << qi.answer_import(row, "#{header_prefix}_c#{i + 1 }").values[0]
    end
    return {"#{origin_id}" => @retval}
  end
end

class ScaleQuestionIo < QuestionIo

  def csv_header(header_prefix)
    issue["items"].each_index do |i|
      @csv_header << header_prefix + "_c#{i + 1}"
      # if issue["show_unknown"]
      #   @csv_header << header_prefix + "_c#{i + 1}" + UNKNOW
      # end
    end
    return @retval
  end
  #TODO spss_value_labels
  def spss_header(header_prefix)
    value_labels = {}
    issue["labels"].each_with_index do |label, index|
      value_labels[index + 1] = label
    end
    value_labels[0] = "不清楚"
    issue["items"].each_index do |i|
      @spss_header << {"spss_name" => header_prefix + "_c#{i + 1}",
                  "spss_type" => SPSS_NUMERIC,
                  "spss_label" => issue["items"][i]["content"]["text"].gsub(/<[^>]*>/, '').slice(0..120),
                  "spss_value_labels" => value_labels}
      # if issue["show_unknown"]
      #   @retval << {"spss_name" => header_prefix + "_c#{i + 1}" + UNKNOW,
      #               "spss_type" => SPSS_STRING,
      #               "spss_label" => SPSS_UNKOWN
      #               }
      # end
    end
    @header_count[header_prefix] ||= @spss_header.count
    @spss_header
  end

  def answer_content(v, header_prefix)
    clear_retval
    return Array.new(header_count(header_prefix)) if (v.nil? || v.try("blank?"))
    issue["items"].each do |e|
      @retval << (v[e["id"].to_s] ? v[e["id"].to_s] + 1 : nil)
      # @retval << (v[e["id"].to_s] == -1 ? 1 : 0 ) if e["show_unknow"]
    end
    return @retval
  end

  def answer_import(row, header_prefix)
    @retval = {}
    issue["items"].each_with_index do |item, index|
      blank? row["#{header_prefix}_c#{index + 1}"]
      if only_num?(row["#{header_prefix}_c#{index + 1}"], range: 1..(issue["labels"].try('length') || 1))
        @retval[get_item_id(index).to_s] = (row["#{header_prefix}_c#{index + 1}"].nil? ? nil : (row["#{header_prefix}_c#{index + 1}"].to_i) - 1)
      else
        raise "您输入的范围好像不太对吧?"
      end
    end
    binding.pry
    return { "#{origin_id}" => @retval}
  end

  def get_item_id(index)
    self.issue["items"][index]["id"]
  end
end
