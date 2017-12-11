module Admin
  class ProjectsController < BaseController
    def new
      @project = Project.new
    end

    def create
      @project = Project.new(sanitized_projects_params)
      if @project.save
        respond_to do |format|
          format.html { redirect_to(dashboard_path, notice: 'Project successfully created')}
        end
      else
        respond_to do |format|
          format.html { render :new }
        end
      end
    end

    def edit
      @project = Project.friendly.find(params[:id])
    end

    def update
      @project = Project.friendly.find(params[:id])
      if @project.update_attributes(sanitized_projects_params)
        flash[:notice] = 'Project successfully updated!'
        redirect_to streaming_path
      else
        flash[:alert] = 'Editing project was unsuccessful'
        render :edit
      end
    end

    def destroy
      @project = Project.friendly.find(params[:id])
      if @project.destroy
        flash[:notice] = 'Project successfully destroyed!'
      else
        flash[:alert] = 'Project could not be destroyed'
      end
      redirect_to streaming_path

    end

    private

    def project_params
      params.require(:project).permit({title_translations: Crowdbreaks::Locales}, {description_translations: Crowdbreaks::Locales}, :keywords, :es_index_name, :image, :public, :activate_stream)
    end

    def sanitized_projects_params
      keywords_sanitized = []
      sanitized_params = project_params
      project_params[:keywords].split(',').each do |k|
        _k = k.strip.downcase
        keywords_sanitized.push(_k) if _k.length > 0
      end
      sanitized_params[:keywords] = keywords_sanitized
      sanitized_params
    end
  end
end
