module Admin
  class ProjectsController < BaseController
    load_and_authorize_resource param_method: :sanitized_projects_params, find_by: :slug

    def new
    end

    def show
    end

    def index
      @projects = Project.primary
    end

    def create
      if @project.primary?
        # create new primary project
        if @project.save
          if @project.job_file.present?
            CreatePublicTweetsJob.perform_later(@project.id, current_user.id, @project.retrieve_tweet_rows)
            redirect_to admin_projects_path, notice: "Project #{@project.name} is being created..."
          else
            redirect_to admin_projects_path, notice: "Project #{@project.name} successfully created!"
          end
        else
          flash[:alert] = 'Creating project was unsuccessful'
          render :new
        end
      else
        # add new question sequence
        @project = copy_fields_from_primary_project(@project)
        if @project.save
          redirect_to admin_question_sequences_path, notice: "Question sequence for #{@project.name} successfully created!"
        else
          redirect_to admin_question_sequences_path, alert: "Question sequence for #{@project.name} could not be successfully created!"
        end
      end
    end

    def edit
    end

    def update
      if @project.update_attributes(sanitized_projects_params)
        if @project.job_file.present?
          CreatePublicTweetsJob.perform_later(@project.id, current_user.id, @project.retrieve_tweet_rows, destroy_first: true)
          redirect_to admin_projects_path, notice: "Project #{@project.name} is being updated..."
        else
          redirect_to admin_projects_path, notice: "Project #{@project.name} successfully updated!"
        end
      else
        flash[:alert] = 'Editing project was unsuccessful'
        render :edit
      end
    end

    def destroy
      if @project.results.count > 0
        redirect_to(admin_projects_path, alert: 'Cannot delete a project with existing answers to questions (results). Delete results or define a new project.')
      else
        if @project.destroy
          flash[:notice] = 'Project successfully destroyed!'
        else
          flash[:alert] = 'Project could not be destroyed'
        end
        redirect_to admin_projects_path
      end
    end

    private

    def project_params
      params.require(:project).permit({title_translations: Crowdbreaks::Locales}, {description_translations: Crowdbreaks::Locales},
                                      :name, :keywords, :es_index_name, :image, :public, :active_stream, :lang, :storage_mode, :image_storage_mode,
                                      :locales, :accessible_by_email_pattern, :annotation_mode, :job_file, :active_question_sequence_id, :primary, :question_sequence_name,
                                      :compile_trending_tweets, :compile_trending_topics, :compile_data_dump_ids)
    end

    def copy_fields_from_primary_project(project)
      main_project = Project.primary_project_by_name(project.name)
      project.title_translations = main_project.title_translations
      project.description_translations = main_project.description_translations
      project
    end

    def sanitized_projects_params
      sanitized_params = project_params
      [:keywords, :lang, :locales, :accessible_by_email_pattern].each do |item|
        sanitized_params[item] = array_from_string(project_params[item], downcase: true)
      end
      [:image_storage_mode, :annotation_mode, :storage_mode].each do |item|
        sanitized_params[item] = sanitized_params[item].to_i
      end
      sanitized_params
    end

    def array_from_string(str, downcase: false, make_unique: true)
      return nil if str.nil?
      arr = []
      str.split(',').each do |k|
        _k = k.strip
        _k = _k.downcase if downcase
        arr.push(_k) if _k.length > 0
      end
      arr = arr.uniq if make_unique
      arr
    end
  end
end
