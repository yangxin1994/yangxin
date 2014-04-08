# already tidied up
class Client::CitiesController < Client::ApplicationController
  before_filter :require_client

  def index
    # @cities = current_client.cities
    @cities = City.all
  end

  def show
    @city = City.find(params[:id])
    @location = @city.records.map { |e| e.join(',') } .join('-')
  end

  def edit
    @city = City.find(params[:id])
  end

  def update
    @city = City.find(params[:id])
    @city.name = params[:city]["name"]
    @city.amount = params[:city]["amount"].to_i
    @city.save
    @city.refresh_records
    redirect_to action: :index and return
  end

  def records
    @city = City.find(params[:id])
  end

  def set_location
    @city = City.find(params[:id])
    @record_index = params[:index]
    @location = @city.records[@record_index.to_i].join(',')
  end

  def batch_set_location
    @city = City.find(params[:id])
    @record_index = params[:index]
  end

  def update_location
    render_json City.find(params[:id]) do |city|
      city.records[params[:record_index].to_i] = [params[:lat], params[:lng]]
      city.save
    end
  end

  def batch_update_location
    render_json City.find(params[:id]) do |city|
      record_index_ary = params[:record_index].split(',').map { |e| e.to_i }
      record_index_ary.each do |i|
        city.records[i] = [(params[:lat].to_f + rand / 1000).to_s, (params[:lng].to_f + rand / 1000).to_s]
      end
      city.save
    end
  end

  def create
    city = City.create(name: params[:city]["name"], amount: params[:city]["amount"].to_i)
    city.refresh_records
    redirect_to action: :index and return
  end

  def destroy
    city = City.find(params[:id])
    city.destroy
    redirect_to action: :index and return
  end
end
