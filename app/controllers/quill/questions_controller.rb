# finish migrating
class Quill::QuestionsController < Quill::QuillController
    
    before_filter :ensure_survey
        
    def create
        retval = @survey.create_question(params[:page_index].to_i, params[:after_question_id], params[:question_type].to_i)
        render_json_auto retval and return
    end

    def show
        question = Question.find(params[:id])
        render_json_auto question and return
    end

    def update
        question = @survey.update_question(params[:question]['_id'], params[:question])
        render_json_auto question and return
    end

    def destroy
        retval = @survey.delete_question(params[:id])
        render_json_auto retval and return
    end

    def move
        retval = @survey.move_question(params[:id], params[:page_index].to_i, params[:after_question_id])
        render_json_auto retval and return
    end
end
