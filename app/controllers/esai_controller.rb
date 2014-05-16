class EsaiController < ApplicationController

  def callback

    # params[:UserNumber]
    # params[:InOrderNumber]
    # params[:OutOrderNumber]
    # 4 for success, 5 for fail
    # params[:PayResult]

    EsaiApi.callback(params[:InOrderNumber], params[:PayResult])
    render xml: "<?xml version=\"1.0\" encoding=\"GB2312\"?><root><result>success</result></root>"
  end
end
