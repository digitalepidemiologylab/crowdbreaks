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
      params.require(:project).permit({title_translations: Crowdbreaks::Locales}, {description_translations: Crowdbreaks::Locales}, :keywords, :es_index_name, :image, :public, :active_stream, :lang)
    end

    def sanitized_projects_params
      sanitized_params = project_params
      sanitized_params[:keywords] = array_from_string(project_params[:keywords])
      sanitized_params[:lang] = array_from_string(project_params[:lang])
      sanitized_params
    end

    def array_from_string(str)
      arr = []
      str.split(',').each do |k|
        _k = k.strip.downcase
        arr.push(_k) if _k.length > 0
      end
      arr
    end
  end
end