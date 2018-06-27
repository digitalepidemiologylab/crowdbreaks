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

ActiveRecord::Schema.define(version: 20180627132303) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", id: :serial, force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_id", null: false
    t.string "resource_type", null: false
    t.string "author_type"
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "answers", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "key"
    t.jsonb "answer_translations"
    t.string "color"
    t.string "label"
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

  create_table "mturk_batch_jobs", force: :cascade do |t|
    t.string "name"
    t.boolean "sandbox"
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
    t.index ["project_id"], name: "index_mturk_batch_jobs_on_project_id"
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
    t.string "lang", default: ["en"], array: true
    t.integer "question_sequences_count", default: 0, null: false
    t.integer "results_count", default: 0, null: false
    t.index ["slug"], name: "index_projects_on_slug"
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

  create_table "questions", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "question_translations"
    t.string "meta_field"
    t.boolean "use_for_relevance_score", default: false, null: false
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
    t.boolean "mturk_result", default: false, null: false
    t.index ["answer_id"], name: "index_results_on_answer_id"
    t.index ["project_id"], name: "index_results_on_project_id"
    t.index ["question_id"], name: "index_results_on_question_id"
    t.index ["task_id"], name: "index_results_on_task_id"
    t.index ["tweet_id"], name: "index_results_on_tweet_id"
    t.index ["user_id"], name: "index_results_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "hit_id"
    t.string "tweet_id"
    t.string "assignment_id"
    t.string "worker_id"
    t.integer "lifecycle_status", default: 0
    t.datetime "time_submitted"
    t.datetime "time_completed"
    t.bigint "mturk_batch_job_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hittype_id"
    t.index ["mturk_batch_job_id"], name: "index_tasks_on_mturk_batch_job_id"
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
    t.boolean "admin", default: false, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "mturk_batch_jobs", "projects"
  add_foreign_key "question_answers", "answers"
  add_foreign_key "question_answers", "questions"
  add_foreign_key "questions", "projects"
  add_foreign_key "results", "tasks"
end
