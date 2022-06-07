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
      # nil.zero?
    end

    def update_primary_jobs
      authorize! :update, :mturk_auto
      primary_jobs = @primary_jobs.map(&:project_id).zip(@primary_jobs.map(&:mturk_batch_job))
      primary_jobs = primary_jobs.map { |k, v| [k.to_s, v&.id&.to_s] }.to_h
      primary_jobs = primary_jobs.sort_by { |k, _| k }.to_h
      primary_jobs_updated = params.require(:mturk_auto).permit(primary_jobs: {})['primary_jobs'].to_h
      primary_jobs_updated = primary_jobs_updated.sort_by { |k, _| k }.to_h
      if primary_jobs != primary_jobs_updated
        # Update primary jobs locally
        primary_jobs_updated.each_pair do |project_id, mturk_batch_job_id|
          Rails.logger.info "[DEV] Project id: #{project_id}, mturk batch job id: #{mturk_batch_job_id}"

          # One cannot make a primary job blank once it's not
          next if mturk_batch_job_id.nil?

          Rails.logger.info '[DEV] Being updated'

          primary_job = PrimaryMturkBatchJob.find_by(project_id: project_id.to_i)
          mturk_batch_job = MturkBatchJob.find(mturk_batch_job_id.to_i)
          primary_job.update_attributes!(mturk_batch_job: mturk_batch_job)
          primary_job.save!
        end
        # respond_with_flash(@api.upload_primary_jobs(primary_jobs.to_json), mturk_auto_path)
        respond_with_flash(
          Helpers::ApiResponse.new(status: :success, message: 'Successfully updated primary jobs.'), mturk_auto_path
        )
      else
        respond_with_flash(
          Helpers::ApiResponse.new(status: :fail, message: "Primary jobs didn't change."), mturk_auto_path
        )
      end
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
        respond_with_flash(
          Helpers::ApiResponse.new(
            status: :error, message: "MTurk batch job '#{@mturk_batch_job.name}' has not been completed yet. Cannot evaluate."
          ),
          mturk_auto_path
        )
        return
      end
      @local_batch_job.users.each do |user|
        unless @local_batch_job.progress_by_user(user) > 98
          respond_with_flash(
            Helpers::ApiResponse.new(
              status: :error, message: "Local batch job '#{@local_batch_job.name}' has not been completed yet. Cannot evaluate."
            ),
            mturk_auto_path
          )
          return
        end
      end
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

    def api_init
      @api = AwsApi.new
    end

    def set_primary_jobs
      @primary_jobs = PrimaryMturkBatchJob.includes(:project).where(projects: { primary: true, auto_mturking: true }).order('projects.name')
    end
  end
end
