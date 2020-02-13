class ProjectSerializer < ActiveModel::Serializer
  attributes :slug, :keywords, :active_stream, :locales, :es_index_name, :lang, :storage_mode, :image_storage_mode, :model_endpoints, :compile_trending_tweets
end
