# coding: utf-8
require 'test_helper'

class IpInfoTest < ActiveSupport::TestCase
	
	test "should create ip info to db" do 
		clear(IpInfo, Postcode)

		#assert_equal IpInfo.get_postcode_from_baidu("桂林"), "541000"
		#assert_equal IpInfo.get_postcode_from_baidu("北京"), "100000"
		#assert_equal IpInfo.get_postcode_from_baidu("上海"), "200000"
		#assert_equal IpInfo.get_postcode_from_baidu("贵阳"), "550000"
		#assert_equal IpInfo.get_postcode_from_baidu("广州"), "510000"

		assert_equal IpInfo.all.count, 0
		assert_equal Postcode.all.count, 0

		#
		# find and create
		#
		retval = IpInfo.find_by_ip("218.192.3.42")
		assert_equal IpInfo.all.count, 1
		assert_equal Postcode.all.count, 1

		assert_equal retval, Postcode.first
		assert_equal retval["city"], "广州"

		# diff ip.
		retval = IpInfo.find_by_ip("218.192.3.45")
		assert_equal IpInfo.all.count, 2
		assert_equal Postcode.all.count, 1

		assert_equal retval, Postcode.first
		assert_equal retval["city"], "广州"

		#
		# just find
		#
		retval = IpInfo.find_by_ip("218.192.3.45")
		assert_equal IpInfo.all.count, 2
		assert_equal Postcode.all.count, 1

		assert_equal retval, Postcode.first
		assert_equal retval["city"], "广州"

		clear(IpInfo, Postcode)
	end

end

__END__

ip: 218.192.3.42

{"ret":1,
"start":"218.192.0.0",
"end":"218.192.7.255",
"country":"\u4e2d\u56fd",
"province":"\u5e7f\u4e1c",
"city":"\u5e7f\u5dde",
"district":"",
"isp":"\u6559\u80b2\u7f51",
"type":"\u5b66\u6821",
"desc":"\u5e7f\u5dde\u5927\u5b66\u7eba\u7ec7\u670d\u88c5\u5b66\u9662"
};