# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_12_23_111614) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answers", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "key"
    t.string "color"
    t.string "label"
    t.string "answer"
    t.string "tag", default: ""
    t.integer "answer_type", default: 0, null: false
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "local_batch_jobs", force: :cascade do |t|
    t.string "name"
    t.bigint "project_id"
    t.text "instructions", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "processing", default: false
    t.boolean "deleting", default: false
    t.string "slug"
    t.integer "processing_mode", default: 0, null: false
    t.integer "check_availability", default: 0, null: false
    t.integer "tweet_display_mode", default: 0, null: false
    t.integer "delay_start", default: 2000, null: false
    t.integer "delay_next_question", default: 1000, null: false
    t.integer "annotation_display_mode", default: 0, null: false
    t.index ["check_availability"], name: "index_local_batch_jobs_on_check_availability"
    t.index ["project_id"], name: "index_local_batch_jobs_on_project_id"
    t.index ["slug"], name: "index_local_batch_jobs_on_slug"
    t.index ["tweet_display_mode"], name: "index_local_batch_jobs_on_tweet_display_mode"
  end

  create_table "local_batch_jobs_users", id: false, force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "local_batch_job_id", null: false
    t.index ["local_batch_job_id"], name: "index_local_batch_jobs_users_on_local_batch_job_id"
    t.index ["user_id"], name: "index_local_batch_jobs_users_on_user_id"
  end

  create_table "local_tweets", force: :cascade do |t|
    t.bigint "tweet_id"
    t.bigint "local_batch_job_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "tweet_text", default: ""
    t.integer "availability", default: 0
    t.index ["local_batch_job_id"], name: "index_local_tweets_on_local_batch_job_id"
  end

  create_table "mturk_batch_jobs", force: :cascade do |t|
    t.string "name"
    t.boolean "sandbox", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "project_id"
    t.text "description"
    t.string "title"
    t.string "keywords"
    t.decimal "reward", precision: 8, scale: 2
    t.integer "lifetime_in_seconds"
    t.integer "auto_approval_delay_in_seconds"
    t.integer "assignment_duration_in_seconds"
    t.text "instructions", default: ""
    t.string "hittype_id"
    t.boolean "marked_for_deletion", default: false
    t.boolean "processing", default: false
    t.integer "number_of_assignments", default: 1
    t.integer "minimal_approval_rate"
    t.string "qualification_type_id"
    t.integer "max_tasks_per_worker"
    t.integer "check_availability", default: 0
    t.boolean "exclude_blacklisted", default: true, null: false
    t.integer "min_num_hits_approved"
    t.integer "delay_start", default: 2000, null: false
    t.integer "delay_next_question", default: 1000, null: false
    t.string "existing_qualification_type_id", default: "", null: false
    t.index ["project_id"], name: "index_mturk_batch_jobs_on_project_id"
  end

  create_table "mturk_cached_hits", force: :cascade do |t|
    t.string "hit_id"
    t.string "hit_type_id"
    t.string "hit_group_id"
    t.string "hit_layout_id"
    t.text "title"
    t.text "description"
    t.text "question"
    t.text "keywords"
    t.string "requester_annotation"
    t.string "hit_status"
    t.string "hit_review_status"
    t.integer "max_assignments"
    t.integer "number_of_assignments_pending"
    t.integer "number_of_assignments_available"
    t.integer "number_of_assignments_completed"
    t.decimal "reward", precision: 8, scale: 2
    t.integer "auto_approval_delay_in_seconds"
    t.integer "assignment_duration_in_seconds"
    t.jsonb "qualification_requirements"
    t.datetime "creation_time"
    t.datetime "expiration"
    t.boolean "sandbox", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mturk_tweets", force: :cascade do |t|
    t.bigint "tweet_id"
    t.bigint "mturk_batch_job_id"
    t.text "tweet_text", default: ""
    t.integer "availability", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mturk_batch_job_id"], name: "index_mturk_tweets_on_mturk_batch_job_id"
  end

  create_table "mturk_worker_qualification_lists", force: :cascade do |t|
    t.string "name"
    t.string "qualification_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mturk_worker_qualification_lists_workers", id: false, force: :cascade do |t|
    t.bigint "mturk_worker_id", null: false
    t.bigint "mturk_worker_qualification_list_id", null: false
  end

  create_table "mturk_workers", force: :cascade do |t|
    t.string "worker_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.boolean "manually_reviewed", default: false, null: false
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "title_translations"
    t.jsonb "description_translations"
    t.string "es_index_name"
    t.string "slug"
    t.string "image_file_name"
    t.string "image_content_type"
    t.integer "image_file_size"
    t.datetime "image_updated_at"
    t.string "keywords", array: true
    t.boolean "public", default: false, null: false
    t.boolean "active_stream", default: false, null: false
    t.string "lang", default: [], array: true
    t.integer "question_sequences_count", default: 0, null: false
    t.integer "results_count", default: 0, null: false
    t.integer "storage_mode", default: 0
    t.string "locales", default: ["en"], array: true
    t.string "name", default: "", null: false
    t.integer "image_storage_mode", default: 0, null: false
    t.string "accessible_by_email_pattern", default: [], array: true
    t.integer "annotation_mode", default: 0, null: false
    t.integer "active_question_sequence_id", default: 0
    t.boolean "compile_trending_tweets", default: false
    t.boolean "compile_trending_topics", default: false, null: false
    t.jsonb "model_endpoints", default: {}, null: false
    t.boolean "compile_data_dump_ids", default: false, null: false
    t.index ["es_index_name"], name: "index_projects_on_es_index_name", unique: true
    t.index ["slug"], name: "index_projects_on_slug"
  end

  create_table "public_tweets", force: :cascade do |t|
    t.bigint "tweet_id"
    t.text "tweet_text"
    t.bigint "project_id"
    t.integer "availability", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["availability"], name: "index_public_tweets_on_availability"
    t.index ["project_id"], name: "index_public_tweets_on_project_id"
    t.index ["tweet_id"], name: "index_public_tweets_on_tweet_id"
  end

  create_table "question_answers", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "question_id"
    t.bigint "answer_id"
    t.integer "order", default: 0, null: false
    t.index ["answer_id"], name: "index_question_answers_on_answer_id"
    t.index ["question_id"], name: "index_question_answers_on_question_id"
  end

  create_table "question_sequence_logs", force: :cascade do |t|
    t.jsonb "log", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "questions", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "meta_field"
    t.boolean "use_for_relevance_score", default: false, null: false
    t.text "question"
    t.text "instructions", default: ""
    t.string "tag", default: ""
    t.index ["project_id"], name: "index_questions_on_project_id"
  end

  create_table "results", id: :serial, force: :cascade do |t|
    t.integer "question_id"
    t.integer "answer_id"
    t.integer "user_id"
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tweet_id"
    t.bigint "task_id"
    t.bigint "local_batch_job_id"
    t.bigint "question_sequence_log_id"
    t.integer "res_type", default: 0, null: false
    t.integer "flag", default: 0, null: false
    t.integer "manual_review_status", default: 0, null: false
    t.index ["answer_id"], name: "index_results_on_answer_id"
    t.index ["local_batch_job_id"], name: "index_results_on_local_batch_job_id"
    t.index ["project_id"], name: "index_results_on_project_id"
    t.index ["question_id"], name: "index_results_on_question_id"
    t.index ["question_sequence_log_id"], name: "index_results_on_question_sequence_log_id"
    t.index ["task_id"], name: "index_results_on_task_id"
    t.index ["tweet_id"], name: "index_results_on_tweet_id"
    t.index ["user_id"], name: "index_results_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "hit_id"
    t.integer "lifecycle_status", default: 0
    t.datetime "time_submitted"
    t.datetime "time_completed"
    t.bigint "mturk_batch_job_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "mturk_tweet_id"
    t.bigint "mturk_worker_id"
    t.datetime "time_assigned"
    t.index ["mturk_batch_job_id"], name: "index_tasks_on_mturk_batch_job_id"
    t.index ["mturk_tweet_id"], name: "index_tasks_on_mturk_tweet_id"
    t.index ["mturk_worker_id"], name: "index_tasks_on_mturk_worker_id"
  end

  create_table "transitions", id: :serial, force: :cascade do |t|
    t.integer "from_question_id"
    t.integer "answer_id"
    t.integer "to_question_id"
    t.integer "project_id"
    t.float "transition_probability"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answer_id"], name: "index_transitions_on_answer_id"
    t.index ["from_question_id"], name: "index_transitions_on_from_question_id"
    t.index ["project_id"], name: "index_transitions_on_project_id"
    t.index ["to_question_id"], name: "index_transitions_on_to_question_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "username"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.string "locale", default: "en"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "mturk_batch_jobs", "projects"
  add_foreign_key "public_tweets", "projects"
  add_foreign_key "question_answers", "answers"
  add_foreign_key "question_answers", "questions"
  add_foreign_key "questions", "projects"
  add_foreign_key "results", "tasks"
end
