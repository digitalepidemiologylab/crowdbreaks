module Admin
  class ProjectsController < BaseController
    def new
      @project = Project.new
    end

    def create
      @project = Project.new(sanitized_projects_params)
      p @project
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
