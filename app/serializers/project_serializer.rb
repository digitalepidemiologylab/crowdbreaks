class ProjectSerializer < ActiveModel::Serializer
  attributes :slug, :keywords, :active_stream, :es_index_name, :lang, :storage_mode
end
