# encoding: utf-8
FactoryGirl.define do
	factory :public_notice do |s|
	  s.title "恭喜 oli*****86@gmail.com 抽得爱国者平板电脑"
	  s.content "<div class=\"oneone\"><p>恭喜优数用户 oli*****86@gmail.com 参加《<a href=\"http://quillme.netinsight.cn/s/5111d517408c997fc1000001\" title=\"\" target=\"\">诺基亚Lumia 920/820/620手机广告效果评估问卷</a>》抽得<a href=\"http://quillme.netinsight.cn/lotteries/5119f2ff408c991b67000009\" title=\"\" target=\"\">爱国者M608超薄6英寸平板电脑</a>！</p><div><br></div><div>欢迎参加<a href=\"http://quillme.netinsight.cn/surveys\" title=\"\" target=\"\">优数调研</a>，兑换丰富礼品，抽万元大奖！</div><p></p></div>"
	  s.public_notice_type  1
	  s.user_id "51139228408c997fc10000e6"
	end
end