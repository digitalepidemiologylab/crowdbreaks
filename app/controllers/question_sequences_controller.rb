class QuestionSequencesController < ApplicationController

  def show
    authorize! :show, :question_sequence
    @project = Project.friendly.find(params[:project_id])

    # Collect question sequence info
    @question_sequence = QuestionSequence.new(@project).create
    
    # Other
    @user_id = current_or_guest_user.id
    @translations = I18n.backend.send(:translations)[I18n.locale][:question_sequences]

    # Fetch new tweet ID
    @tweet_id = FlaskApi.new.get_tweet(@project.es_index_name, user_id: @user_id)

    # @tweet_id = '564984221203431000'  # invalid tweet
    # @tweet_id = '955454023519391744'  # invalid tweet
  end

  def create
    authorize! :create, Result
    result = Result.new(results_params)

    # if captcha is verified save data
    if params.has_key?(:recaptcha_response)
      resp = RecaptchaVerification.new.verify(params[:recaptcha_response])
      if not resp['success']
        render json: { errors: resp['error-codes'].to_a, captcha_verified: false }, status: 400
      else
        if result.save
          render json: { captcha_verified: true }, status: 200
        else
          render json: { errors: ['internal error'], captcha_verified: true }, status: 400
        end
      end
    else
      if result.save
        head :ok
      else
        head :bad_request
      end
    end
  end

  private

  def results_params
    params.require(:result).permit(:answer_id, :tweet_id, :question_id, :user_id, :project_id)
  end
end
