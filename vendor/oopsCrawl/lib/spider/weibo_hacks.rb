# encoding: utf-8
module WeiboHacks
  def get_attr(node, attr_name)
    logger.info "> 开始解析: #{attr_name}"
    begin
      ret = node.attr(attr_name).to_s
    rescue Exception => err
      logger.fatal(">提取出错: `#{attr_name}`")
      logger.fatal(err)
      logger.fatal(err.backtrace.slice(0,5).join("\n"))
    end
    if block_given?
      begin
        ret = yield(ret)
      rescue Exception => err
        logger.fatal(">执行出错:")
        logger.fatal(err)
        logger.fatal(err.backtrace.slice(0,5).join("\n"))
      end
    end
    ret.present? ? ret : ""
  end

  def get_field(node, selector, attr_name = nil)
    ret = nil
    ret = node.search(selector).first
    ret = attr_name ? get_attr(ret, attr_name) : ret
    ret = yield(ret) if block_given?
  rescue Exception => err
    logger.fatal(">执行出错:")
    logger.fatal(err)
    logger.fatal(err.backtrace.slice(0,5).join("\n")) 
  ensure   
    return ret.present? ? ret : ""
  end

  def get_fields(node, selector, attr_name = nil)
    ret = nil
    ret = node.search(selector)
    ret = attr_name ? ret.map{ |e| get_attr(e, attr_name)} : ret
    ret = ret.map{|_f| yield(_f)} if block_given?
  rescue Exception => err
    logger.fatal(">执行出错:")
    logger.fatal(err)
    logger.fatal(err.backtrace.slice(0,5).join("\n")) 
  ensure   
    return ret.present? ? ret.select{|e| e.present? } : []
  end

  def find_fields(node, selector)
    logger.info "> 开始解析: #{selector}"
    ret = node.search("selector")
  rescue Exception => err
    logger.fatal(">解析出错: `#{selector}`")
    logger.fatal(err)
    logger.fatal(err.backtrace.slice(0,5).join("\n")) 
  ensure
    return ret
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def login(rel = false)
    @login_count ||= 0
    @login_count += 1
    @weibos_spider ||= Mechanize.new
    @weibos_spider.user_agent_alias = 'Mac Safari'
    load_cookies
    # if @weibo_proxy = self.get_proxy 
    #   @weibos_spider.set_proxy(@weibo_proxy.ip, @weibo_proxy.port)
    # end
    if load_cookies && !rel
      # tmp_page = @weibos_spider.get('http://login.sina.com.cn/member/my.php?entry=sso')
      tmp_page = @weibos_spider.get("http://s.weibo.com/weibo")

      if tmp_page.search('a.adv_settiong')[0] && tmp_page.search('a.adv_settiong')[0].text == "帮助"
        p "> 登录成功: 通过cookies登录"
        save_cookies
        return @is_login = true
      else
        begin
          wlr = tmp_page.search('script').to_s.match(/.replace\([\"\']([\w\W]*)[\"\']\)/)[1]
          tmp_page = @weibos_spider.get(wlr)
          tmp_page.search('a.adv_settiong')[0].text == "帮助"
          p "> 登录成功: 通过cookies登录"
          save_cookies
          return @is_login = true
        rescue
          ""
        end

      end
    end
    tmp_page = @weibos_spider.post("http://login.sina.com.cn/sso/login.php?client=ssologin.js(v1.4.15)", login_data)
    wlr = tmp_page.search('script').to_s.match(/.replace\([\"\']([\w\W]*)[\"\']\)/)[1]
    after_login_page = @weibos_spider.get(wlr)
    # TODO 判断是否登陆成功
    # parse可能出现异常!!!
    result_json = JSON.try 'parse', (after_login_page.body.match(/\{[\w\W]*\}/).to_s)
    if result_json && result_json["result"]
      save_cookies
      @login_count = 0
      p "> 登录成功: 通过账号密码登陆 #{self.username}"
      @is_login = true
    else
      result_json ||= {}
      @errno = result_json["errno"]
      # self.update_attribute :is_deleted, true
      delete_cookies
      case @errno
      when "4040"
        self.get_proxy true
        if @login_count <= 5
          return login 
        end
      when "6202"
        self.get_proxy true
        if @login_count <= 5
          return login 
        end
      when "2070"
      when "2092"
      else
      end
      p ">登录失败: #{result_json["errno"]}--#{result_json["reason"]}"
      @is_login = false
      return false
    end
  end

  def cookies
    @weibos_spider.cookie_jar
  end
  
  def get_script_html(page, ns)
    joos = page.search("script")

    joos = joos.map{|joo| begin JSON.parse(joo.child.to_s.match(/\{[\w\W]*\}/).to_s) rescue "" end}
    joo = joos.select{|joo| joo["ns"] == ns}.first
    if joo.blank?
      joo = joos.select{|joo| joo["pid"] == ns}.first
    end
    if joo.blank?
      joo = joos.select{|joo| joo["domid"] == ns}.first
    end
    return Nokogiri.HTML(joo["html"]) if joo
  end

  def get_json_html(page)
    joo = JSON::parse(page.body)['data']
    Nokogiri.HTML(joo["html"]) if joo
  end

  def get_config(page, attr_name = "")
    joos = page.search("script")
    joo = joos.select{|joo| joo.to_s.include?("var $CONFIG = {};")}.first.to_s
    if attr_name.present?
      return joo.match(/\$CONFIG\[\'#{attr_name}\'\][\s=]*\'([\S]*)\'/).try("[]", 1)
    else
      joo
    end
  end

  def filtered(source, filter_sources)
    fs_flag = true
    filter_sources.each do |fs|
      fs_flag = false if source.match(fs)
    end
    fs_flag
  end

  def biuld_params(options)
    options.each do |k, v|
      options.delete(k) if v.nil? || v.to_s.empty?
    end
    options_buffer = ""
    if options[:msgtype]
      options_buffer += "scope="
      case options[:msgtype]
      when 1
        options_buffer += "ori=custom::"
      end
    end
    if options[:xsort]
      options_buffer += "&xsort=hot"
    end
    if options[:starttime]
      options_buffer += "&timescope=custom:#{options[:starttime]}:#{options[:endtime]}"
    end      
    # if options[:searchtype]
    #   case options[:searchtype]
    #   when 0

    #   when 1

    #   when 8
    #     options_buffer += "timescope=custom:#{options[:starttime]}:#{options[:endtime]}"
    #   end
    # end
    unless options[:province].nil? || options[:province].empty?
      options_buffer += "&region=custom:#{options[:province]}:#{options[:city] || 1000}"
    end
    options_buffer
  end

  def encode_password
    login_data if @login_info.empty?
    # rsa2
    # if RbConfig::CONFIG['host_os'] == "mingw32"
    #   pw = get_with_login('http://flowy.oopsdata.net/s/get_pass', {:pubkey => @login_info["pubkey"],:servertime => @login_info["servertime"], :nonce => @login_info["nonce"],:password => password})
    #   @encode_password = pw.body
    # end
    @encode_password ||= `node lib/spider/weibo.js #{@login_info["pubkey"]} #{@login_info["servertime"]} #{@login_info["nonce"]} #{password}`
    # wsse
    # weibo_login unless @servertime
    # pwd1 = Digest::SHA1.hexdigest password
    # pwd2 = Digest::SHA1.hexdigest pwd1
    # Digest::SHA1.hexdigest "#{pwd2}+#{@servertime}#{@nonce}"
  end

  def encode_username
    Base64.strict_encode64(username.sub("@","%40"))
  end

  def login_data
    @login_info = {}
    @weibos_spider.get("http://login.sina.com.cn/sso/prelogin.php?entry=weibo&callback=sinaSSOController.preloginCallBack&su=&rsakt=mod&client=ssologin.js(v1.4.15)&_=#{Time.now.to_i.to_s}") do |page|
      wl = JSON.parse(page.content.match(/\{[\w\W]*\}/).to_s)
      @login_info["servertime"] = wl["servertime"]
      @login_info["pcid"] = wl["pcid"]
      @login_info["nonce"] = wl["nonce"]
      @login_info["pubkey"] = wl["pubkey"]
      @login_info["rsakv"] = wl["rsakv"]
    end
    ret = { 'entry'=>'weibo', 'gateway'=>'1',
      'from'=>'', 'savestate'=>'7', 'userticket'=>'1',
      'ssosimplelogin'=>'1', 'vsnf'=>'1', 'su'=>encode_username,
      'service'=>'miniblog', 'servertime'=>@login_info["servertime"], 'nonce'=>@login_info["nonce"],
      'pwencode'=>'rsa2', 'rsakv'=>@login_info["rsakv"] , 'sp'=>encode_password,
      'encoding'=>'UTF-8', 'prelt'=>'115',
      'returntype'=>'META',
      'url'=>"http://weibo.com/ajaxlogin.php?framelogin=1&callback=parent.sinaSSOController.feedBackUrlCallBack"
    }
    if @login_info["pcid"].present?
      pcurl = "http://login.sina.com.cn/cgi/pin.php?r=#{(rand * 100000000).floor}&s=0&p=#{@login_info["pcid"]}"
      file_name = username.split('@')[0]
      File.delete("./tmp/captchas/#{file_name}.png") if File.exist?("./tmp/captchas/#{file_name}.png")
      File.delete("./tmp/captchas/#{file_name}.txt") if File.exist?("./tmp/captchas/#{file_name}.txt")
      File.new("tmp/captchas/#{file_name}.txt", "w")
      @weibos_spider.get(pcurl).save_as("./tmp/captchas/#{file_name}.png")
      _to = 0
      while true
        puts "> 正在登陆: 请输入 #{file_name} 的验证码"
        f = File.open("tmp/captchas/#{file_name}.txt")
        door = f.read
        break if door.present?
        break if (_to += 10) > 300
        sleep(10)
      end
      File.delete("./tmp/captchas/#{file_name}.png") if File.exist?("./tmp/captchas/#{file_name}.png")
      File.delete("./tmp/captchas/#{file_name}.txt") if File.exist?("./tmp/captchas/#{file_name}.txt")
      ret['door'] = door.gsub("\n", '')
    end
    ret
  end

  def str_62_to_10(str62)
    i10 = 0
    i = 1
    str62.each_char do |c|
      n = str62.length - i
      i += 1
      i10 += str62keys.index(c) * (62 ** n)
    end
    i10
  end

  def str_10_to_62(int10)
    s62 = ''
    r = 0
    while int10 != 0
      s62 = str62keys[int10 % 62] + s62
      int10 = int10 / 62
    end
    s62
  end

  def mid_to_str(mid) 
    str = ''
    mid = mid.to_s.dup
    (mid.length / 7 + 1).times do |i|
      if mid.length >= 7
        num = str_10_to_62(mid.slice!(-7, 7).to_i)
      else
        num = str_10_to_62(mid.to_i)
      end
      str = num + str
    end
    str
  end

  def str_to_mid(str)
    mid = ""
    str = str.dup
    (str.length / 4 + 1).times do |i|
      offset = i < 0 ? 0 : i
      if str.length >= 4
        num = str_62_to_10(str.slice!(-4, 4))
      else
        num = str_62_to_10(str)
      end
      mid = mid.ljust(7, '0') if (offset > 0) 
      mid = num.to_s + mid
    end
    mid 
  end

  def rnd
    rand(10000000000000)
  end

  def save_cookies
    File.open("tmp/cookies/#{encode_username}.cookie", "w") do |file|
      @weibos_spider.cookie_jar.dump_cookiestxt(file)
    end
  end

  def load_cookies
    return false unless File.exist?("tmp/cookies/#{encode_username}.cookie")
    File.open("tmp/cookies/#{encode_username}.cookie", "r") do |file|
      @weibos_spider.cookie_jar.load_cookiestxt(file)
    end
  end

  def delete_cookies
    return false unless File.exist?("tmp/cookies/#{encode_username}.cookie")
    File.delete("tmp/cookies/#{encode_username}.cookie") 
  end

  def str62keys
  [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
  ]
  end
end
