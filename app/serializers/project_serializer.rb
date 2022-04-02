class ProjectSerializer < ActiveModel::Serializer
  attributes :covid, :slug, :keywords, :active_stream, :locales, :es_index_name, :lang,
             :storage_mode, :image_storage_mode, :model_endpoints, :auto_mturking,
             :compile_trending_tweets, :compile_trending_topics, :compile_data_dump_ids
end
