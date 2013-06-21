# encoding: utf-8
require 'yomu'
require 'tool'
class ParseWord
#######################################
#path待解析文件的路径
#paragr_arr 是一个将解析出来的字符串以3个\n作为分隔符而出现的数组，数组的每个元素代表文档内容的一段文字
#######################################
  def parse_word_file(path)
    return if !File.exist?(path)
    yomu = Yomu.new(path)
    text = yomu.text
    if text.match(/\t/)  #含表格的问卷
      #paragr_arr = text.split(/([\n]{2}[\s]*[\n][\t]*|[\n]{2}[\s]*[\t]*)/)
    else # 不含表格的问卷
      paragr_arr = text.split(/[\n]{3,}/)  
    end
    

    survey = Survey.new
    survey.user = @current_user
    if @current_user && (@current_user.is_admin || @current_user.is_super_admin)
      survey.publish_status = QuillCommon::PublishStatusEnum::PUBLISHED
    else
      survey.style_setting["has_advertisement"] = false
    end
    survey.save

    package_question_obj(survey,paragr_arr)        
  end

  def package_question_obj(survey,arr)
    return if arr.size <= 0
    arr.each do |para|
      question_obj = {}     
      if para.match(/\n/) #首先判断每个段落是否为一个没有换行的段，如果有\n则表示该段为一个多段的内容
        if para.match(/\t/) #判断是否该文件具有表格，如果有的话，单独做处理
          question_relative = excute_tab_data(para)
        else #如果该文件为没有表格的文件，执行以下内容
          question_relative = excute_pure_text_data(para)
        end
        question_type = question_relative.first
        question_obj  = question_relative.last
      else #如果没有\n则表示该段为一个文本段类型的问题
        question_type = 'Paragraph'
        question_obj["content"] = {"text" => "#{para}", "image" => [], "audio" => [], "video" => []}
      end
             
      Issue::ISSUE_TYPE.each_with_index do |ele,index|
       question_type = index if ele == "#{question_type}"
      end
      question = survey.create_question(0,-1,question_type)
      question.update_question(question_obj)
    end
  end

############################
#para为具体的某个分割出来的段落，并且该段落中含有\t字符串
#该函数用来处理含有表格的文档
############################ 
  def excute_tab_data(para)
    #para.delete_if{|ele| ele.match(/[\n]{2,}[\s]*(\t|\n)/)}
    
      
  end


############################
#para为具体的某个分割出来的段落，并且该段落中不含有\t字符串
#该函数用来处理不含有表格的文档
############################ 
  def excute_pure_text_data(para)
    other_item = {}
    items_arr = []
    question_type = 'ChoiceIssue' #这里默认为选择题，如果发现新的题型，则更改该值
    question_obj = {}
    option_type = 0
    question_index = nil
    para.split(/[\n]+/).each_with_index do |sub_p,index|
      sub_p.gsub!('？','?') if sub_p.match('？')
      sub_p.gsub!('：',':') if sub_p.match('：')
      
      if sub_p.match(/\?/) || sub_p.match(/:/) || sub_p.match('选') #如果当前内容以问号结尾或者冒号结尾或者含有'选'等字样，则当前内容为问题
        question_obj["content"] = {"text" => "#{sub_p}", "image" => [], "audio" => [], "video" => []}
        question_index = index # 如果已经找到问题，那么将当前内容的index值赋值给question_index,用来标识已经找到问题
        option_type = sub_p.match('多选') ?  2 : option_type
        option_type = sub_p.match('最多') ?  4 : option_type
        option_type = sub_p.match('最少') ?  5 : option_type        
      else 
        if question_index.present? #如果已经找到问题，则以下内容为问题后的选项
          if sub_p.match('其他') #将"其他"项放入到other_item 中
            other_item = {
              "id" => Tool.rand_id,
              "has_other_item" => false,
              "is_exclusive" => false,
              "content" => {"text" => "#{sub_p}", "image" => [], "audio" => [], "video" => []}
            }
          else
            sub_item =  {
              "id" => Tool.rand_id,
              "content" => {"text" => "#{sub_p}", "image" => [], "audio" => [], "video" => []},
              "is_exclusive" => false
            }
            items_arr << sub_item #将每个选项的内容放到issue的items中  
          end  
        else #这里处理的是，如果在题干的前面还有段落，那么忽略该内容，一般该内容为文字描述信息
          #nothing to do          
        end
      end
    end
    
    case question_type
      when 'ChoiceIssue'
        question_obj["issue"] = {"items" => items_arr,
                                 "choice_num_per_row" => -1,
                                 "min_choice" => 1, 
                                 "max_choice" => 1,
                                 "option_type" => option_type,
                                 "is_list_style" => false,
                                 "is_rand" => false,
                                 "other_item" => other_item              
                                }

      #when .....                     
      #when .....
      #when .....
      end    
    return [question_type,question_obj]
  end

end


