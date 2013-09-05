class Admin::EjournalsController < Admin::AdminController

  layout :resolve_layout

  before_filter :require_sign_in

  before_filter :get_ejournals_client

  def get_ejournals_client
    @ejournals_client = Admin::EjournalClient.new(session_info)
  end

  def index
    result = @ejournals_client.index(params[:page],
                                     params[:per_page],
                                     params[:scope] || 'all')

    if result.success
      @ejournals = result.value
      if params[:partial]
        render :partial => "ejournals"
      end
    end
  end

  def new
  end

  def show
    @ejournal = @ejournals_client.show(params[:id])
    @ejournal.success ? @ejournal = @ejournal.value : @ejournal = nil
  end

  def test
    render :json  => @ejournals_client.test(params[:id], params[:email] ,params[:content])
  end

  def create
    # @ejournal  = @ejournals_client.create(
    #   :subject => params[:subject],
    #   :status  => params[:status],
    #   :subject => params[:subject],
    #   :content => params[:content],
    #   )
    @ejournal = @ejournals_client.create(params[:ejournal])
    render :json => @ejournal
  end

  def update
    @ejournal = @ejournals_client.update(params[:id], params[:ejournal])
    render :json => @ejournal
  end

  def destroy
    render :json => @ejournals_client.destroy(params[:id])
  end

  def deliver
    render :json => @ejournals_client.deliver(params[:id], params[:content])
  end

  def cancel
    render :json => @ejournals_client.cancel(params[:id])
  end

  private

  def resolve_layout
    case action_name
    when "new", "show"
      "layouts/ejournal"
    else
      "layouts/admin_new"
    end
  end


end