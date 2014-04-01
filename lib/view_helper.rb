# encoding: utf-8
module ViewHelper
  class View
      extend ActionView::Helpers::DateHelper
    def self.user_behavor(news)
      #username = %Q{<a href="#{user_path(news['user_id'])}">#{news['username']}</a>}.html_safe
      username = %Q{<span class="u">#{news['username']}</span>}.html_safe
      behavor  = ''
      result   = ''
      case news.type.to_i
      when 2
        if(news.result)
          #抽得了<a href="#{survey_path(news['prize_id'])}">#{news['prize_name']}</a>
          behavor = %Q{
            抽得了<a href="javascript:void(0);">#{news.prize_name}</a>
          }.html_safe        
        else
          behavor = %Q{
            参与了一次抽奖  
          }.html_safe
        end
      when 8
        case news.reason.to_i
        when 1
          if news.scheme_id.to_i > 0 
            behavor = %Q{
              回答了<a href="/s/#{(news.scheme_id)}">#{news.survey_title}</a>获得了<b>#{news.amount}</b>积分 
            }.html_safe 
          else
            behavor = %Q{
              回答了<a href="javascript:void(0);">#{news.survey_title}</a>获得了<b>#{news.amount}</b>积分   
            }.html_safe 
          end
        when 2
          ref = news.scheme_id.to_i > 0 ? "/s/#{news.scheme_id}" : "javascript:void(0);"
          if news.amount.to_i > 0
            behavor = %Q{
              推广了<a href="#{ref}">#{news.survey_title}</a>获得了<b>#{news.amount}</b>积分    
            }.html_safe
          else
            behavor = %Q{
              推广了<a href="#{ref}">#{news.survey_title}</a> 
            }.html_safe
          end
        when 4
          if news.gift_type.to_i == Gift::REAL.to_i
            behavor = %Q{
              使用<b>#{news.amount.abs}</b>积分兑换了<a href="/gifts/#{news.gift_id}">#{news.gift_name}</a>
            }.html_safe 
          else
            behavor = %Q{
              使用<b>#{news.amount.abs}</b>积分兑换了<span class="u">#{news.gift_name}</span>
            }.html_safe
          end           
        when 16
          behavor = %Q{
            违规操作,处罚了<b>#{news.amount.abs}</b>积分
          }.html_safe          
        when 32
          behavor = %Q{
            邀请样本答题,获得了<b>#{news.amount.abs}</b>积分
          }.html_safe  
        when 256
          behavor = %Q{
            从清研通导入<b>#{news.amount.abs}</b>积分
          }.html_safe             
        end
      when 16
        behavor = %Q{
          加入了问卷吧
        }.html_safe     
      end
      return username + behavor
    end

    def self.ch_time(from_time)  
      time = time_ago_in_words(from_time,include_seconds = true)  
      time = time.sub(/about /,"")  
      time = time.sub(/over /,"")   
      if time.to_i == 0                 
        case time.to_s  
        when 'half a minute'   then '半分钟前'  
        when 'less than a minute' then '刚刚'  
        when 'less than 5 seconds'   then '5秒前'  
        when 'less than 10 seconds' then '10秒前'  
        when 'less than 20 seconds' then '20秒前'  
        else time
        end  
      else  
        mun = time.to_i   
        case time[-3,3]  
        when 'nds'   then mun.to_s+'秒前'  
        when 'ute'   then mun.to_s+'分前'  
        when 'tes' then mun.to_s+'分钟前'  
        when 'urs','our' then mun.to_s+'小时前'  
        when 'day','ays' then mun.to_s+'天前'  
        when 'nth','ths' then mun.to_s+'个月前'  
        when 'ear','ars' then mun.to_s+'年前'  
        else time
        end  
      end 
    end

  end
end