class ProjectSerializer < ActiveModel::Serializer
  attributes :slug, :keywords, :active_stream, :es_index_name, :lang
end
