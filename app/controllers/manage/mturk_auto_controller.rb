module Manage
  class MturkAutoController < BaseController
    include Response
    include MturkAutoHelper

    before_action :api_init, only: %i[index update_cron update_primary_jobs]
    before_action :set_primary_jobs, only: %i[index update_primary_jobs]

    RULE_NAME = 'crowdbreaks-auto-mturking-new-batch-cron'.freeze

    def index
      authorize! :read, :mturk_auto
      if Setting.new_batch_each.nil?
        aws_cron = get_value_and_flash_now(@api.load_new_batch_cron(RULE_NAME))
        Setting.new_batch_each = validate_cron(aws_cron).to_i
      end
      @new_batch_each = Setting.new_batch_each
      @mturk_auto_batches = MturkAutoBatch.all.order('created_at DESC').page(params[:page]).per(10)
    end

    def update_cron
      authorize! :update, :mturk_auto
      mturk_auto_params = params.require(:mturk_auto).permit(:new_batch_each)
      unless mturk_auto_params[:new_batch_each].to_i != Setting.new_batch_each
        respond_with_flash(Helpers::ApiResponse.new(status: :fail, message: "Cron didn't change."), mturk_auto_path)
        return
      end

      if Time.now.day > 25
        respond_with_flash(
          Helpers::ApiResponse.new(
            status: :error,
            message: 'Cannot update the rule from the website after the 15th of each month. ' \
                     'To update the rule, write to olesia.altunina@epfl.ch'
          ),
          mturk_auto_path
        )
      else
        new_batch_each = mturk_auto_params[:new_batch_each]
        unless new_batch_each.number?
          respond_with_flash(
            Helpers::ApiResponse.new(
              status: :error, message: 'Cannot update the cron rule. Please enter a number of months.'
            ),
            mturk_auto_path
          )
        end

        response = @api.create_update_cron_event(name: RULE_NAME, cron: cron(new_batch_each))
        Setting.new_batch_each = new_batch_each.to_i if response.status == :success
        respond_with_flash(response, mturk_auto_path)
      end
    end

    def evaluate_batch
      authorize! :evaluate_batch, :mturk_auto
      evaluate_params = params.permit(:mturk_auto_batch_id)
      @mturk_auto_batch = MturkAutoBatch.find(evaluate_params[:mturk_auto_batch_id])
      @mturk_batch_job = @mturk_auto_batch.mturk_batch_job
      @local_batch_job = @mturk_auto_batch.local_batch_job
      unless @mturk_batch_job.percentage_completed > 98
        respond_with_flash_now(
          Helpers::ApiResponse.new(
            status: :error,
            message: "MTurk batch job '#{@mturk_batch_job.name}' has not been completed yet. Evaluate at your own risk."
          )
        )
      end
      if @local_batch_job.nil?
        respond_with_flash_now(
          Helpers::ApiResponse.new(
            status: :error,
            message: 'Local batch job has not been created yet. Evaluate at your own risk.'
          )
        )
        return
      end
      @local_batch_job.users.each do |user|
        next if @local_batch_job.progress_by_user(user) > 98

        respond_with_flash_now(
          Helpers::ApiResponse.new(
            status: :error,
            message: "Local batch job '#{@local_batch_job.name}' has not been completed yet. Evaluate at your own risk."
          )
        )
        break
      end
      # unless @mturk_batch_job.percentage_completed > 98
      #   respond_with_flash(
      #     Helpers::ApiResponse.new(
      #       status: :error, message: "MTurk batch job '#{@mturk_batch_job.name}' has not been completed yet. Cannot evaluate."
      #     ),
      #     mturk_auto_path
      #   )
      #   return
      # end
      # @local_batch_job.users.each do |user|
      #   unless @local_batch_job.progress_by_user(user) > 98
      #     respond_with_flash(
      #       Helpers::ApiResponse.new(
      #         status: :error, message: "Local batch job '#{@local_batch_job.name}' has not been completed yet. Cannot evaluate."
      #       ),
      #       mturk_auto_path
      #     )
      #     return
      #   end
      # end
      # if @mturk_auto_batch.evaluated?
      #   respond_with_flash(
      #     Helpers::ApiResponse.new(
      #       status: :error, message: "This auto MTurk batch '#{@mturk_batch_job.name}' has already been evaluated."
      #     ),
      #     mturk_auto_path
      #   )
      # end
    end

    private

    def primary_jobs_params
      params.require(:mturk_auto).permit(primary_jobs: {}, max_tasks_per_worker: {}, copy_qualification_list: {})
    end

    def api_init
      @api = AwsApi.new
    end

    def set_primary_jobs
      @primary_jobs = PrimaryMturkBatchJob.includes(:project).where(projects: { primary: true, auto_mturking: true }).order('projects.name')
    end
  end
end
