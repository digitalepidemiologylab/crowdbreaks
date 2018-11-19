module Admin
  class ResultsController < BaseController
    load_and_authorize_resource

    def show
      @group_by_qs = param_is_truthy?(:group_by_qs)
      if @group_by_qs
        @qs_results = get_qs
        if get_qs.first.mturk_res_type?
          @tweet_text = MturkTweet.find_by(tweet_id: params[:tweet_id])&.tweet_text
        elsif get_qs.first.local_res_type?
          @tweet_text = LocalTweet.find_by(tweet_id: params[:tweet_id])&.tweet_text
        else
          @tweet_text = ""
        end
        @log = Hashie::Mash.new @qs_results&.first&.question_sequence_log&.log
      end
      @options = get_filter_options
    end

    def index
      @group_by_qs = param_is_truthy?(:group_by_qs, default: true)
      @project_id_filter = params[:project_id_filter]
      @res_type_filter = params[:res_type_filter]
      query = Result.all
      # project filter
      if @project_id_filter.present?
        query = query.where(project_id: @project_id_filter)
      end
      # res_type filter
      if @res_type_filter.present?
        query = query.where(res_type: @res_type_filter)
      end
      # group by qs
      if @group_by_qs
        query = query
          .left_outer_joins(:task)
          .select('MAX(results.id) as id', 'MAX(results.created_at) as created_at', 'count(*) as num_results',
        'tasks.mturk_worker_id as mturk_worker_id', :res_type, :project_id, :tweet_id, :user_id, 'tasks.mturk_batch_job_id as mturk_batch_job_id')
          .group(:res_type, :project_id, :tweet_id, :user_id, 'tasks.mturk_worker_id', 'tasks.mturk_batch_job_id')
          .order(Arel.sql('max(results.created_at) DESC'))
      else
        query = query.order(created_at: :desc)
      end
      @results = query.page params[:page]
      @options = get_filter_options
    end

    def destroy
      if param_is_truthy?(:group_by_qs)
        qs_results = get_qs
        expected_num_deleted = qs_results.count
        destroyed = qs_results.destroy_all
        if destroyed.length == expected_num_deleted
          message = {notice: "#{expected_num_deleted} results successfully destroyed."}
        else
          message = {alert: 'Something went wrong when trying to destroy question sequence.'}
        end
      else
        if @result.destroy
          message = {notice: "Result successfully destroyed."}
        else
          message = {alert: 'Something went wrong when destroying result.'}
        end
      end
      redirect_to(admin_results_path(project_id_filter: params[:project_id_filter], res_type_filter: params[:res_type_filter], group_by_qs: params[:group_by_qs]), **message)
    end


    private

    def get_filter_options
      {
        project_id_filter: params[:project_id_filter],
        res_type_filter: params[:res_type_id_filter],
        group_by_qs: params[:group_by_qs]
      }
    end

    def get_qs
      if params[:res_type] == 'mturk'
        query = Result.joins(:task).where(tweet_id: params[:tweet_id], user_id: params[:user_id], project_id: params[:project_id],
                                          'tasks.mturk_worker_id': params[:mturk_worker_id], 'tasks.mturk_batch_job_id': params[:mturk_batch_job_id])
      else
        query = Result.where(tweet_id: params[:tweet_id], user_id: params[:user_id], project_id: params[:project_id])
      end
      query.order(created_at: :asc)
    end

    def param_is_truthy?(param, default: false)
      if params[param].present?
        params[param] == 'true' ? true : false
      else
        default
      end
    end
  end
end
