module Admin
  class ProjectsController < BaseController
    load_and_authorize_resource param_method: :sanitized_projects_params, find_by: :slug

    def new
      @names = Project.distinct.pluck(:name)
    end

    def show
    end

    def index
      @projects = Project.grouped_by_name(projects: @projects)
    end

    def create
      if params[:question_sequence]
        @project = generate_question_sequence_project(@project)
      end
      if @project.save
        respond_to do |format|
          format.html { redirect_to(admin_projects_path, notice: 'Project successfully created')}
        end
      else
        respond_to do |format|
          format.html { render :new }
        end
      end
    end

    def edit
    end

    def update
      if @project.update_attributes(sanitized_projects_params)
        flash[:notice] = 'Project successfully updated!'
        redirect_to admin_projects_path
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
      params.require(:project).permit({title_translations: Crowdbreaks::Locales}, {description_translations: Crowdbreaks::Locales}, :name, :keywords, :es_index_name, :image, :public, :active_stream, :lang, :storage_mode, :image_storage_mode, :locales, :accessible_by_email_pattern)
    end

    def generate_question_sequence_project(project)
      main_project = Project.find_by(name: project.name)
      project.title_translations = main_project.title_translations
      project.description_translations = main_project.description_translations
      project
    end

    def sanitized_projects_params
      sanitized_params = project_params
      sanitized_params[:keywords] = array_from_string(project_params[:keywords])
      sanitized_params[:lang] = array_from_string(project_params[:lang])
      sanitized_params[:locales] = array_from_string(project_params[:locales])
      sanitized_params[:accessible_by_email_pattern] = array_from_string(project_params[:accessible_by_email_pattern])
      sanitized_params[:storage_mode] = sanitized_params[:storage_mode].to_i
      sanitized_params[:image_storage_mode] = sanitized_params[:image_storage_mode].to_i
      sanitized_params
    end

    def array_from_string(str)
      return nil if str.nil?
      arr = []
      str.split(',').each do |k|
        _k = k.strip.downcase
        arr.push(_k) if _k.length > 0
      end
      arr
    end
  end
end
