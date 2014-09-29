# encoding: utf-8
require File.expand_path("../../../../../app/models/vote_related/suffrage", __FILE__) 
require File.expand_path("../../../../../app/models/vote_related/vote_user", __FILE__) 
class Movie
  attr_accessor :voted,:want,:no_want,:seen,:total
  include Mongoid::Document
  Nlpir::Mongoid.included(self)

  field :status, :type => Integer, :default => 0

  field :nowplaying, :type => Boolean

  field :subject_id, :type => String
  field :subject_url, :type => String
  field :subject_img, :type => String

  field :weibo_id, :type => String

  # 
  field :title, :type => String
  field :rating_p, :type => Float
  field :rating_count, :type => Integer
  field :rating_percent, :type => Hash, :default => {}
  field :rating_played, :type => Boolean
  
  field :content, :type => String

  # info
  field :info_all, :type => String
  field :info_directors, :type => String
  field :info_screenwriters, :type => String
  field :info_actors, :type => String
  field :info_type, :type => String
  field :info_region, :type => String
  field :info_show_at, :type => Integer
  field :info_show_at_all, :type => String

  # 预告片
  field :trailer_url, :type => String
  field :trailer_count, :type => Integer
  field :trailer_on, :type => Integer
  field :last_trailer_crawl, :type => Integer, :default => 0
  # 短评
  field :comment_url, :type => String
  field :comment_count, :type => Integer
  field :comment_on, :type => Integer
  field :last_comment_crawl, :type => Integer, :default => 0
  # 影评
  field :review_url, :type => String
  field :review_count, :type => Integer
  field :review_on, :type => Integer
  field :last_review_crawl, :type => Integer, :default => 0
  # 讨论
  field :discussion_url, :type => String
  field :discussion_count, :type => Integer
  field :discussion_on, :type => Integer

  field :last_news_crawl, :type => Integer, :default => 0
  
  field :keywords, :type => Array, :default => []
  field :news_keywords, :type => Array, :default => []
  field :woms_keywords, :type => Hash, :default => {}
  field :trailers_keywords, :type => Array, :default => []
  field :tags, :type => Array, :default => []

  field :time_slice, :type => Integer, :default => 12

  field :for_artists, :type => Hash, :default => {:count => 0}

  field :on_crawl, :type => Boolean, :default => false
  field :weibo_crawl_status, :type => Hash, :default => {}
  field :weibo_day_count, :type => Hash, :default => {}

  field :need_reset_cache, :type => Boolean, :default => true
  field :approve_co, :type => Hash, :default => {}
  field :approve_com, :type => Hash, :default => {}
  field :approve_co_matrix, :type => Hash, :default => {}
  field :approve_com_matrix, :type => Hash, :default => {}

  field :is_idatage, :type => Boolean, :default => false
  field :is_deleted, :type => Boolean, :default => false
  field :is_ready, :type => Boolean, :default => false


  scope :nowplaying, ->{ where(:nowplaying => true) }
  scope :later, -> {where(:nowplaying => false)}
  validates :subject_id, uniqueness: true, presence: true

  def title_zh
    title.split(' ')[0]
  end

  def title_en
    title.gsub(title_zh, '')
  end

  def rating
    rating_p
  end

  has_many :comments
  has_many :reviews
  has_many :trailers
  has_many :baidu_news
  has_many :weibos
  has_and_belongs_to_many :weibo_users, class_name: "WeiboUser"
  has_and_belongs_to_many :weibo_artists, class_name: "WeiboArtist"
  has_and_belongs_to_many :brands
  has_many :photos
  has_many :boxes
  has_many :suffrages

  begin
    MovieIndex
  rescue
  end
  has_many :movie_indexes if eval("defined?(MovieIndex) && MovieIndex.is_a?(Class)") == true

  def self.clear_nowplaying
    self.nowplaying.each do |movie|
      movie.update_attribute(:nowplaying, false)
    end
  end

  # def self.rand(limit=false,user_id=nil)
  #   if limit
  #     n = self.nowplaying.desc(:info_show_at)[0..2]
  #     m = self.later.asc(:info_show_at)[0..2]
  #   else
  #     n = self.nowplaying.desc(:info_show_at)
  #     m = self.later.asc(:info_show_at)
  #   end

  #   result = n + m 
  #   if user_id.present?
  #     result = result.map do |e|
  #       e.write_attribute('voted',true) if e.suffrages.where(user_id:user_id).count > 0
  #       e
  #     end
  #   end
  #   result
  # end


  # def self.get_playing(user_id)
  #   result = self.nowplaying.desc(:info_show_at)
  #   if user_id.present?
  #     result = result.map do |e|
  #       total = e.suffrages.count
  #       want  = e.suffrages.where(vote_tpye:Suffrage::VOTE_TYPE_0).count
  #       no_want = e.suffrages.where(vote_tpye:Suffrage::VOTE_TYPE_1).count
  #       seen = e.suffrages.where(vote_tpye:Suffrage::VOTE_TYPE_2).count
  #       e.write_attribute('voted',true) if e.suffrages.where(user_id:user_id).count > 0
  #       e.write_attribute('total',total)
  #       e.write_attribute('want',want)
  #       e.write_attribute('no_want',no_want)
  #       e.write_attribute('seen',seen)
  #       e
  #     end
  #   end
  #   return result
  # end

  # def self.get_later(user_id)
  #   result = self.later.asc(:info_show_at)
  #   if user_id.present?
  #     result = result.map do |e|
  #       e.write_attribute('voted',true) if e.suffrages.where(user_id:user_id).count > 0
  #       e
  #     end
  #   end
  #   return result    
  # end


  def rating
    rating_p
  end

  def gender_info
    _wc = weibo_users.count
    _wmc = weibo_users.where(:gender => 'm').count
    _wfc = weibo_users.where(:gender => 'f').count
    {
      'm' => _wmc,
      'f' => _wfc,
      'n' => _wc - _wmc - _wmc
    }
  end

  def ages_info
    all_c = weibo_users.where(:birth => /年/).count
    ret = {}
    now = Time.now
    weibo_users.where(:birth => /年/).map(&:birth).map do |a| 
      begin
        age = (now - Time.parse(a.gsub(/年|月/, '-').gsub(/日/, ''))) / 1.years
        if age.round > 50
          ret['50'] ||= 0
          ret['50'] += 1
        elsif age > 40
          ret['41'] ||= 0
          ret['41'] += 1
        elsif age > 36
          ret['36'] ||= 0
          ret['36'] += 1
        elsif age > 31
          ret['31'] ||= 0
          ret['31'] += 1
        elsif age > 25
          ret['25'] ||= 0
          ret['25'] += 1
        elsif age > 0
          ret['0'] ||= 0
          ret['0'] += 1
        end
      rescue Exception => e
        ""
      end
    end
    ret.each{|k, v| ret[k] = (v * 100.0 / all_c).round}
    ret
  end

  def get_tags_info
    tags_info = {}
    weibo_users.each do |wu|
      next if wu.tags.blank?
      wu.tags.split(" ").each do |tag|
        next if tag.blank? or tag.length > 6
        tags_info[tag] ||= 0
        tags_info[tag] += 1
      end
    end
    tags_info.map { |k, v| {text: k, size: v} }
  end



  def reset_cache
    if need_reset_cache
      self.approve_co = {}
      self.approve_com = {}
      self.approve_co_matrix = {}
      self.approve_com_matrix = {}
      self.need_reset_cache = false
      save
    end
  end

  def get_approve_co_all(keyword, is_media = false)
    reset_cache
    # if is_media
    #   return approve_com if approve_com.present?
    # else
    #   return approve_co if approve_co.present?
    # end        
    apc = {}
    all_count = 0 
    fo_counts = {}
    weibo_users.each do |wu|
      _brands = wu.follows.where(:approve_co => true)
      if keyword.present?
        _brands = _brands.and(:identity_info => /#{keyword}/)
      end
      if is_media
        _brands = _brands.and(:identity_info => /电视|报|媒体|新闻/)
      else
        _brands = _brands.and(:identity_info => /行业/)
        _brands -= wu.follows.where(:approve_co => true).where(:identity_info => /电视|报|媒体|新闻/)
      end
      _brands.each do |fo|
        next if fo.name.blank?
        _fcount = wu.follow_count.to_i
        # _fcount = 0
        while true
          if _fcount <= 0
            _fcount = (7 * rand(10) + rand(20) * rand(30) / 3.14).ceil 
            wu.follow_count = _fcount
            wu.save
          else
            break
          end
        end
        apc[fo.name] ||= {"count" => 0}
        apc[fo.name]["count"] += _fcount
        fo_counts[wu.name] = _fcount
        next if apc[fo.name]["count"] > _fcount
        apc[fo.name]["name"] = fo.name
        apc[fo.name]["profile_image_url"] = fo.profile_image_url
        # apc[fo.name]["identity_info"] = fo.identity_info
        apc[fo.name]["fans_count"] = fo.fans_count.to_i
        apc[fo.name]["url"] = fo.get_url
      end
    end
    apc = apc.sort_by{|a| a[1]["count"]}.reverse.map { |e| e[1] }
    ret = {:nodes => apc, :fo_counts =>fo_counts}
    if is_media
      self.approve_com = ret
    else
      self.approve_co = ret
    end
    save
    ret
  end

  def get_approve_matrix(keyword, is_media = false)
    if is_media
      return approve_com_matrix if approve_com_matrix.present?
    else
      return approve_co_matrix if approve_co_matrix.present?
    end    
    package_names = get_approve_co_all(keyword, is_media = false).map{|e, v| e}
    matrix = []
    package_names.each do |i|
      matrix << package_names.map { |e| 0}
    end
    weibo_users.each do |wu|
      _apc = wu.follows.where(:approve_co => true)
      next if _apc.blank?
      package_names.each_with_index do |package_r, ir|
        next unless _apc.and(:name => package_r).present?
        package_names.each_with_index do |package_v, iv|
          next unless _apc.and(:name => package_v).present?
          matrix[ir][iv] += 1
        end
      end
    end
    apcm = {
      package_names: package_names,
      matrix: matrix
    }
    if is_media
      approve_com_matrix = apcm
    else
      approve_co_matrix = apcm
    end
    save 
    apcm   
  end

  def brands
    weibo_users.limit(500).map{|a| a.approve_co = true;a.save}
    weibo_users.where(:approve_co => true)
  end

  def get_weibo_crawl_status
    _latest = info_show_at
    weibo_crawl_status.each do |_k, _v|
      _latest = _k.to_i
      next if _v == "finished" || _v == "start"
      return "completed" if _latest >= info_show_at + 21.days or _latest >= Time.now.to_i
      weibo_crawl_status[_k] = "start"
      return _k
    end
    if _latest < info_show_at + 21.days && _latest < Time.now.to_i
      _latest += 4.hours
      weibo_crawl_status[_latest.to_s] = "start"
    else
      "completed"
    end 
    _latest.to_s
  end

  def all_trailer_comments
    tids = trailers.map { |_e| _e.trailer_id }
    TrailerComment.where(:trailer_id.in => tids)
  end

  def poster
    _p = photos.where(:title => /海报/)
    if (_p = photos.where(:title => /海报/).and(:title => /中国/).and(:title => /正式/)).present?
      _p = _p.map{|a| a}.max_by{|a| a.title.match(/(\d+)/).to_s.to_i}
    elsif (_p = photos.where(:title => /海报/).and(:title => /中国/)).present?
      _p = _p.map{|a| a}.max_by{|a| a.title.match(/(\d+)/).to_s.to_i}
    elsif (_p = photos.where(:title => /海报/)).present?
      _p = _p.map{|a| a}.max_by{|a| a.title.match(/(\d+)/).to_s.to_i}
    else
      _p = photos.first
    end

    if _p
      if !Dir.exist?(Rails.root + "public/images")
        Dir.mkdir(Rails.root + "public/images")
      end
      if !Dir.exist?(Rails.root + "public/images/movies")
        Dir.mkdir(Rails.root + "public/images/movies")
      end
      if !File.exist?(Rails.root + "public/images/movies")
        Dir.mkdir(Rails.root + "public/images/movies")
      end
      _pic = Rails.root + "public/images/movies" + "#{subject_id}.jpg"
      if !File.exist? _pic
        `curl -o #{_pic} #{_p.url}` #unless _p.saved
      end
      _p.update_attribute(:saved, true)
      "/images/movies/#{subject_id}.jpg"
    end
  end

  def brands
    weibo_users.where(:approve_co => true)
  end

  def proc_keywords(is_force = false, count = 100)
    Movie.init_nlpir
    return if self.woms_keywords.present? && !is_force
    self.woms_keywords = {}
    str = ""
    str << self.comments.map(&:content).limit(3000).join
    str << self.weibos.map(&:content).limit(3000).join
    str << self.reviews.map(&:content).limit(50).map(&:content).join
    # str << self.weibos.map(&:content).join
    p "proc #{title}"
    _wk = Movie.text_keywords(str, count, Nlpir::Ictclas::NLPIR_TRUE).split('#')
    self.woms_keywords[title_zh.split(/[：:]/)[0]] = _wk.select{|a| a =~ /\/[na]\w*/ }
    p "save #{title}"      
    p "start #{title}"
      save
    weibo_artists.each do |wa|
      str = ""
      _comments = self.comments.where(:content => /#{wa.name}/).limit(3000)
      _reviews = self.reviews.where(:content => /#{wa.name}/).limit(50)
      _weibos = self.weibos.where(:content => /#{wa.name}/).limit(3000)
      str << _comments.map(&:content).join
      str << _reviews.map(&:content).join
      str << _weibos.map(&:content).join
      # str << self.weibos.map(&:content).join
      p "proc #{title} #{wa.name}"
      _wk = Movie.text_keywords(str, count, Nlpir::Ictclas::NLPIR_TRUE).split('#')
      self.woms_keywords[wa.name] = _wk.select{|a| a =~ /\/[na]\w*/ }
      p "save #{title} #{wa.name}"  
      save
    end

    # return if self.trailers_keywords.present? && !is_force
    # str = ""
    # str << self.trailers.map{|e| e.comments.map{|c| c.content}.join }.join
    # self.trailers_keywords = Movie.text_keywords(str, count, Nlpir::Ictclas::NLPIR_TRUE).split('#')
    # self.trailers_keywords = trailers_keywords.select{|a| a =~ /\/[na]\w*/ }
    # return if self.news_keywords.present? && !is_force
    # str = ""
    # str << self.baidu_news.map(&:content).join
    # self.news_keywords = Movie.text_keywords(str, count, Nlpir::Ictclas::NLPIR_TRUE).split('#')
    # self.news_keywords = news_keywords.select{|a| a =~ /\/[na]\w*/ }
  end
end
