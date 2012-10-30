# coding: utf-8
class GiftsController < ApplicationController
  #TO DO before_filter
  # gifts.json?page=1

  #*method*: get
  #
  #*url*: /gifts
  #
  #*description*: list all gifts can be rewarded
  #
  #*params*:
  #* page: page number
  #
  #*retval*:
  #* the Survey object: when meta data is successfully saved.
  #* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
  #* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
  def index
    respond_and_render_json { Gift.can_be_rewarded.page(page) }
  end


  def_each :virtualgoods, :cash, :realgoods, :stockout, :expired do |method_name|
    @gifts = Gift.send(method_name).can_be_rewarded.page(page)
    respond_and_render_json { @gifts}
  end

  def show
    # TO DO is owners request?
      retval = Gift.find_by_id(params[:id])
    respond_to do |format|
      format.json { render json: retval }
    end
  end
end
