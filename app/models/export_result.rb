#encoding: utf-8

class ExportResult < Result
  include Mongoid::Document
  include Mongoid::Timestamps

  GRANULARITY = 5

  field :answer_content, :type => Hash, :default => []
  field :filter_index, :type => Integer
  field :include_screened_answer, :type => Boolean
  field :last_updated_time, :type => Hash
  field :export_process, :type => Hash, :default => { :answers => 0,
                                                      :post => 0,
                                                      :convert => 0}
                                                      
  def filtered_answers
  	Result.answers(self.survey, filter_index, include_screened_answer)
  end

  def answer_content
    answers = filtered_answers
    @retval = []
    q = survey.all_questions_type
    p "========= 准备完毕 ========="
    n = 0
    answers_count = answers.size
    answers.each do |a|
      line_answer = []
      i = -1
      #begin
        #TODO 异常处理
        a.answer_content.each do |k, v|
          line_answer += q[i += 1].answer_content(v)
        end
      #end
      n += 1
      export_process[:answers] += GRANULARITY if (n % (answers_count / 100 * GRANULARITY) == 0 )
      
      p "========= 转出 #{n} 条 进度 #{get_export_process} =========" if n%GRANULARITY == 0
      @retval << line_answer
    end
    answer_content = @retval
    self.save
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
    begin
      Net::HTTP.start(url.host, url.port) do |http| 
        r = Net::HTTP::Post.new(post_to)
        p "===== 开始转换 ====="
        a = Time.now
        r.set_form_data(yield)
        p Time.now - a
        http.read_timeout = 120
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
      {'spss_data' => {"spss_header" => survey.spss_header,
                       "answer_contents" => answer_content,
                       "header_name" => survey.csv_header,
                       "result_key" => result_key}.to_yaml}
    end
  end

  def get_export_process
    ep = export_process[:answers] * 0.5 +
         export_process[:post] * 0.1 +
         export_process[:convert] * 0.4 
    if ep >= 100
      return "某链接"
    else
      return ep
    end
  end
   
end