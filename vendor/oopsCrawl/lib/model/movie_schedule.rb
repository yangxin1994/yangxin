# encoding: utf-8
require 'rtesseract' 
require 'mini_magick'
require 'csv'

class MovieSchedule

  include Mongoid::Document

  field :title, :type => String
  field :box, :type => Integer
  field :schedule, :type => Integer
  field :show_at, :type => Integer
  field :show_days, :type => Integer
  field :baidu_count, :type => Integer
  field :weibo_count, :type => Integer
  field :id_58921, :type => String
  field :url_58921, :type => String
  field :directors, :type => Array, :default => []
  field :actors, :type => Array, :default => []
  field :is_needed, :type => Boolean, :default => false
  field :crawled_staff, :type => Boolean, :default => false
  # field :directors
  scope :needed, ->{ where(:is_needed => true) }
  validates :id_58921, uniqueness: true, presence: true

  def self.add_movie(info)
    m = MovieSchedule.new
    m.title = info[:title]
    m.schedule = info[:schedule].to_f * 10_000
    m.save
  end

  def self.to_csv
    CSV.open("tmp/csv/电影票房-#{Time.now.strftime('%F')}.csv", "wb") do |csv|
        csv << ["电影", "上映时间", "国内票房", "排片量", "百度新闻量", "微博提及量"]
      needed.each do |m|
        csv << [m.title, Time.at(m.show_at).strftime('%F'), m.box, m.schedule, m.baidu_count, m.weibo_count]
      end
    end
  end

  def self.artists_box(dtype = 2)
    result = {}
    needed.each do |movie|
      ats = []
      query_field = nil
      if dtype == 2
        ats = (movie.directors + movie.actors)
        query_field = :directors
      elsif dtype == 1
        ats = movie.directors
        query_field = :directors
      elsif dtype == 0
        ats =  movie.actors
        query_field = :actors 
      end
      ats.each do |dr|
        MovieSchedule.where(query_field => /#{dr}/).each do |mv|
          result[dr] ||= []
          result[dr] << {
            :title => mv.title,
            :box => mv.box,
            :show_at => mv.show_at ? Time.at(mv.show_at).strftime("%F") : "不明"
          }
          result[dr].uniq!
        end
      end
    end
    result
  end

  def self.artists_box_csv(dtype = 2)
    result = artists_box(dtype)
    CSV.open("tmp/csv/导演演员票房-#{Time.now.strftime('%F')}-#{rand(10)}.csv", "wb") do |csv|
      csv << %w(导演/演员 电影1 上映1 票房1 电影2 上映2 票房2 电影3 上映3 票房3 电影4 上映4 票房4 电影5 上映5 票房5 电影6 上映6 票房6 )
      result.each do |_actor, _movies|
        _line = [_actor]
        _movies.sort_by{|dd| dd[:box].to_i}.reverse_each do |_info|
          _line += [_info[:title], _info[:show_at], _info[:box]]
        end
        begin
          csv << _line
        rescue Exception => e
          next
        end
      end
    end
  end

  def self.directors_box_csv
    artists_box_csv(1)
  end

  def self.actors_box_csv
    artists_box_csv(0)
  end

  def ocr(url)
    img = MiniMagick::Image.new("tmp/ocr/3.png") 
    # img.white_threshold(245)
    binding.pry
    # img.crop("#{img[:width] - 18}x#{img[:height]}+0+0")
    img.colorspace("GRAY")
    img.monochrome 
    # image = RTesseract.new(img.path, :processor => "mini_magick", options: [:digits])
    image = RTesseract.new(img.path, :processor => "mini_magick")
  end

  MOVIES = %W{
  了不起的盖茨比
  逃出生天
  扫毒
  无人区
  暴力街区
  闺蜜
  厨子戏子痞子
  一代宗师
  青木时代
  小时代
  刺金时代
  归来
  沉睡魔咒
  窃听风云3
  极品飞车
  澳门风云
  后会无期
  速度与激情6
  中国合伙人
  爸爸去哪儿
  反贪风暴
  救火英雄
  等风来
  庞贝末日
  大明猩
  快乐大本营之快乐到家
  不二神探
  老男孩之猛龙过江
  私人订制
  分手大师
  六福喜事
  整容日记
  笑功震武林
  百星酒店
  摩登年代
  独行侠
  临时同居
  笔仙Ⅱ
  盲探
  京城81号
  一触即发
  极速蜗牛
  喜羊羊与灰太狼之喜气羊羊过蛇年
  蓝精灵2
  怪兽大学
  喜羊羊与灰太狼之飞马奇遇记
  熊出没之夺宝熊兵
  里约大冒险2
  冰雪奇缘
  驯龙高手2
  疯狂原始人
  神偷奶爸2
  天才眼镜狗
  秦时明月之龙腾万里
  洛克王国  圣龙的心愿
  我爱灰太狼2 
  精灵旅社
  赛尔号大电影3之战神联盟
  我想和你好好的
  天台爱情
  非常幸运
  被偷走的那五年
  一夜惊喜
  分手合约
  前任攻略
  北京遇上西雅图
  同桌的你
  北京爱情故事
  致我们终将逝去的青春
  101次求婚
  悲惨世界
  斯大林格勒
  侠探杰克
  惊天魔盗团
  毒战
  云图
  全民目击
  催眠大师
  狄仁杰之神都龙王
  白日焰火
  激战
  特殊身份
  惊天危机
  饥饿游戏2：星火燎原
  金蝉脱壳
  重生之门
  一触即发
  天机—富春山居图
  风暴
  全面反击
  大破天幕杀机
  警察故事2013
  西游记之大闹天宫
  魔警
  惩罚
  遗落战境
  极乐空间
  魔境仙踪
  重返地球
  金刚狼2
  安德的游戏
  史矛革之战
  意外之旅
  黑暗世界
  侏罗纪公园
  暗黑无界
  机械战警
  明日边缘
  超凡蜘蛛侠2
  绝迹重生
  环太平洋
  钢铁侠3
  地心引力
  逆转未来
  哥斯拉
  西游降魔篇
  钢铁之躯
  美国队长2
  雪国列车
  安德的游戏
  超验骇客
  逆世界
  四大名捕2
  四大名捕大结局
  白发魔女传之明月天国
  绣春刀
  忠烈杨家将
  }

end