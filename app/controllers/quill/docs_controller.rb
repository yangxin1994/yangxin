class Quill::DocsController < ApplicationController

  layout 'quillhome'

  before_filter :activate_menu

  def activate_menu
    @activate_menu = 1
  end

  def design
  end
  def result
  end
  def share
  end
  
end