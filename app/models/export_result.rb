#encoding: utf-8

class ExportResult < Result
  include Mongoid::Document
  include Mongoid::Timestamps

  GRANULARITY = 5

  #field :answer_contents, :type => Array, :default => []
  field :filter_index, :type => Integer
  field :include_screened_answer, :type => Boolean
  field :last_updated_time, :type => Hash
  field :answers_count, :type => Integer
  field :export_process, :type => Hash, :default => { :answers => 0,
                                                      :post => 0,
                                                      :excel_convert => 0,
                                                      :spss_convert => 0}
                                                      
  def filtered_answers
  	Result.answers(self.survey, filter_index, include_screened_answer)
  end

  def answer_contents
    answers = filtered_answers
    @retval = []
    q = survey.all_questions_type
    p "========= 准备完毕 ========="
    n = 0
    self.answers_count = answers.size
    self.save
    answers.each do |a|
      line_answer = []
      i = -1
      #begin
        #TODO 异常处理
        a.answer_content.each do |k, v|
          line_answer += q[i += 1].answer_content(v)
        end
      #end
      #n += 1
      export_process[:answers] += GRANULARITY if ((n += 1) % (answers_count / 100 * GRANULARITY) == 0 )
      
      p "========= 转出 #{n} 条 进度 #{excel_export_process} =========" if n%GRANULARITY == 0
      @retval << line_answer
    end
    #answer_contents = @retval
    #self.save
    @retval
  end

  def csv_header
    headers = []
    survey.all_questions.each_with_index do |e, i|
      headers += e.csv_header("q#{i+1}")
    end
    headers
  end

  def spss_header
    headers =[]
    survey.all_questions.each_with_index do |e, i|
      headers += e.spss_header("q#{i+1}")
    end
    headers
  end

  def excel_header
    headers =[]
    survey.all_questions.each_with_index do |e, i|
      headers += e.excel_header("q#{i+1}")
    end
    headers
  end

  def send_data(post_to)
    
    url = URI.parse('http://192.168.1.129:9292')
    p url
    begin
      Net::HTTP.start(url.host, url.port) do |http| 
        r = Net::HTTP::Post.new(post_to)
        a = Time.now
        r.set_form_data(yield)
        p Time.now - a
        http.read_timeout = 120
        p "===== 准备连接 ====="
        http.request(r)
      end
    rescue Errno::ECONNREFUSED
      p "连接失败"
    rescue Timeout::Error
      p "超时"
    ensure
      export_process[:post] = 100
      self.save
      p "连接结束"
    end
  end

  def to_spss
    send_data '/to_spss' do
      p "===== 准备转换 ====="
      {'spss_data' => {"spss_header" => survey.spss_header,
                       "answer_contents" => self.answer_contents,
                       "header_name" => survey.csv_header,
                       "result_key" => result_key,
                       "answers_count" => answers_count,
                       "granularity" =>GRANULARITY}.to_yaml}
    end
  end

  def excel_export_process
    ep = export_process[:answers] * 0.5 +
         export_process[:post] * 0.1 +
         export_process[:excel_convert] * 0.4 
    if ep >= 100
      return "某链接"
    else
      return ep
    end
  end

  def to_excel
    send_data '/to_excel' do
      {'excel_data' => {"excel_header" => excel_header,
                        "answer_contents" => answer_contents,
                        "header_name" => csv_header,
                        "result_key" => result_key,
                        "answers_count" => answers_count,
                        "granularity" =>GRANULARITY}.to_yaml}
    end
  end

  def spss_export_process
    ep = export_process[:answers] * 0.5 +
         export_process[:post] * 0.1 +
         export_process[:spss_convert] * 0.4 
    if ep >= 100
      return "某链接"
    else
      return ep
    end
  end

end