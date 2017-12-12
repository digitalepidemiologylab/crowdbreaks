class ProjectSerializer < ActiveModel::Serializer
  attributes :keywords, :active_stream, :es_index_name, :lang
end
