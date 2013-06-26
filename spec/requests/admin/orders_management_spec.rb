require 'spec_helper'

describe "order management" do

	before(:all) do
		@auth_key = admin_signin
		@samples = FactoryGirl.create_list(:sample, 2)
	end

	describe "visit /index" do
		before(:all) do
			@orders = FactoryGirl.create_list(:order, 20)
			@orders[0..9].each { |o| @samples[0].orders << o}
			@orders[10..19].each { |o| @samples[1].orders << o}
			@order_list = []
			@orders.each { |o| @order_list << [o.type, o.code, o.status, o.source, o.sample.email, o.sample.mobile] }
		end

		it "should return all orders" do
			get "/admin/orders",
			    page: 1,
			    per_page: 20,
			    auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(20)
		end

		it "search type should return right message" do
			get "/admin/orders",
			    page: 1,
			    per_page: 20,
			    type: 2,
			    auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@order_list.each { |o| count += 1 if o[0] == 2}
			expect(retval.length).to eq(count)
		end

		it "search code should return right message" do
			code = @orders[6].code
			get "/admin/orders",
			    page: 1,
			    per_page: 20,
			    code: code,
			    auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(1)
		end

		it "search status should return right message" do
			get "/admin/orders",
			    page: 1,
			    per_page: 20,
			    status: 4,
			    auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@order_list.each { |o| count += 1 if o[2] == 4}
			expect(retval.length).to eq(count)
		end

		it "search source should return right message" do
			get "/admin/orders",
			    page: 1,
			    per_page: 20,
			    source: 2,
			    auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@order_list.each { |o| count += 1 if o[3] == 2}
			expect(retval.length).to eq(count)
		end

		it "search email should return right message" do
			email = @orders[8].sample.email
			get "/admin/orders",
			    page: 1,
			    per_page: 20,
			    email: email,
			    auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(10)
		end

		it "search mobile should return right message" do
			mobile = @orders[10].sample.mobile
			get "/admin/orders",
			    page: 1,
			    per_page: 20,
			    mobile: mobile,
			    auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(10)
		end

		it "search status|type should return right message" do
			get "/admin/orders",
			    page: 1,
			    per_page: 20,
			    status: 2,
			    type: 4,
			    auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@order_list.each { |o| count += 1 if o[0] == 4 and o[2] == 2}
			expect(retval.length).to eq(count)
		end

		it "search status|mobile should return right message" do
			mobile = @orders[10].sample.mobile
			status = @orders[10].status
			get "/admin/orders",
			    page: 1,
			    per_page: 20,
			    status: status,
			    mobile: mobile,
			    auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@order_list.each { |o| count += 1 if o[2] == status and o[5] == mobile}
			expect(retval.length).to eq(count)
		end

		after(:all) do
			clear(:Order)
		end
	end

	describe "visit /update" do
		before(:all) do
			# @order = FactoryGirl.create
		end
	end

	after(:all) do
		clear(:User)
	end

end
