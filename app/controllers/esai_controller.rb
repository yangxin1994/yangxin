class EsaiController < ApplicationController

  def callback

    # params[:UserNumber]
    # params[:InOrderNumber]
    # params[:OutOrderNumber]
    # 4 for success, 5 for fail
    # params[:PayResult]

    EsaiApi.callback(params[:InOrderNumber], params[:PayResult])

    render xml: "<?xml version=\"1.0\" encoding=\"GB2312\"?>\n<root>\n<result> success</result>\n</root>"
  end
end
