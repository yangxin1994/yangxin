class Admin::QualityQuestionsController < Admin::AdminController
  layout 'admin-todc'
  # *****************************
  def index
    @quality_questions = auto_paginate QualityControlQuestion.find_by_type(params[:type])
  end


  def objective
    @quality_questions = auto_paginate QualityControlQuestion.objective_questions.desc(:created_at)
  end

  def matching
    @quality_questions = auto_paginate QualityControlQuestion.matching_questions.desc(:created_at)
  end

  def new
    @quality_question = {}
  end

  def show
    @question = QualityControlQuestion.find(params[:id])
    @quality_question = @question.show_quality_control_question
    @question_objects = @quality_question[0, @quality_question.length-1]
    @quality_control_question_answer = @quality_question[@quality_question.length-1]
  end

  def edit
    @question = QualityControlQuestion.find(params[:id])
    @quality_question = @question.show_quality_control_question
    @question_objects = @quality_question[0, @quality_question.length-1]
    @quality_control_question_answer = @quality_question[@quality_question.length-1]
  end

  def create
    quality_question = QualityControlQuestion.create_quality_control_question(
      params[:quality_control_type].to_i, 
      params[:question_type].to_i, 
      params[:question_number].to_i, 
      current_user)
    if quality_question[0].present?
      redirect_to admin_quality_question_path(quality_question[0]._id)
    else
      render :new
    end
  end

  def update
    params[:questions].each do |qid, options|
      question = QualityControlQuestion.find(qid)
      _question = {
        'content' => {'text' => options['content'], 'audio' => "", 'image' => "", 'video' => ""}, 
        'note'=>  "",
        'issue' => {
          'max_choice' => options['max_choice'].to_i,
          'min_choice' => options['min_choice'].to_i,
          'items' => [],
          'option_type' => (options['min_choice'].to_i == 1 && options['max_choice'].to_i == 1) ? 0 : 6
        }
      }
      options['items'].each do |k, v|
        _question['issue']['items'] << {
          'content' => {
            'text' => v,
            'video' => "",
            'image' => "",
            'audio' => ""
          }, 
          'id' => k
        }
        _question['issue']['rows'] = _question['issue']['items']
      end if options['items'].present?

      question.update_question(_question, current_user)
      case params[:quality_control_type].to_i
      when 1
        answer_content = {
          :fuzzy => true,
          :items => params[:answers].split(',').select{|a| a.present?}
        }
      when 2 
        answer_content = {
          :matching_items => params[:answers].split(';').map{ |a| a.split(',')}.select{|a| a.present?}
        }
      end
      QualityControlQuestionAnswer.update_answer(qid, params[:quality_control_type].to_i, answer_content)     
    end
    redirect_to admin_quality_question_path(params[:id])
  end

  def update_answer
    retval = QualityControlQuestionAnswer.update_answer(params[:id], params[:quality_control_type].to_i, params[:answer])
    #reconstruct params[:answer_content], because of matching_items's item contains js object,not normal string.
    if params[:answer_content][:matching_items] then
      matching_items = params[:answer_content][:matching_items];
      params[:answer_content][:matching_items] = []
      matching_items.each do |k,v|
        params[:answer_content][:matching_items] << v
      end
    end
    @result = @client._put({
        :quality_control_type => params[:quality_control_type],
        :answer => params[:answer_content]
      }, "/#{params[:id]}/update_answer")
    render_result
  end

  def destroy
    render_json QualityControlQuestion.where(:_id => params[:id]).first do |question|
      question.destroy
    end
  end

end