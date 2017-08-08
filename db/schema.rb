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

ActiveRecord::Schema.define(version: 20170808123318) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.string   "author_type"
    t.integer  "author_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree
  end

  create_table "answer_sets", force: :cascade do |t|
    t.string   "name"
    t.integer  "answer0_id"
    t.integer  "answer1_id"
    t.integer  "answer2_id"
    t.integer  "answer3_id"
    t.integer  "answer4_id"
    t.integer  "answer5_id"
    t.integer  "answer6_id"
    t.integer  "answer7_id"
    t.integer  "answer8_id"
    t.integer  "answer9_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answer0_id"], name: "index_answer_sets_on_answer0_id", using: :btree
    t.index ["answer1_id"], name: "index_answer_sets_on_answer1_id", using: :btree
    t.index ["answer2_id"], name: "index_answer_sets_on_answer2_id", using: :btree
    t.index ["answer3_id"], name: "index_answer_sets_on_answer3_id", using: :btree
    t.index ["answer4_id"], name: "index_answer_sets_on_answer4_id", using: :btree
    t.index ["answer5_id"], name: "index_answer_sets_on_answer5_id", using: :btree
    t.index ["answer6_id"], name: "index_answer_sets_on_answer6_id", using: :btree
    t.index ["answer7_id"], name: "index_answer_sets_on_answer7_id", using: :btree
    t.index ["answer8_id"], name: "index_answer_sets_on_answer8_id", using: :btree
    t.index ["answer9_id"], name: "index_answer_sets_on_answer9_id", using: :btree
  end

  create_table "answers", force: :cascade do |t|
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "key"
    t.integer  "order",               default: 0
    t.jsonb    "answer_translations"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",                      null: false
    t.integer  "sluggable_id",              null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree
  end

  create_table "mturk_tokens", force: :cascade do |t|
    t.string   "hit_id"
    t.string   "token"
    t.string   "key"
    t.boolean  "used",               default: false, null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "assignment_id"
    t.string   "worker_id"
    t.integer  "questions_answered"
    t.boolean  "bonus_sent",         default: false, null: false
    t.index ["key"], name: "index_mturk_tokens_on_key", unique: true, using: :btree
    t.index ["token"], name: "index_mturk_tokens_on_token", unique: true, using: :btree
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.jsonb    "title_translations"
    t.jsonb    "description_translations"
    t.string   "es_index_name"
    t.string   "slug"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.index ["slug"], name: "index_projects_on_slug", using: :btree
  end

  create_table "questions", force: :cascade do |t|
    t.integer  "project_id"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "answer_set_id"
    t.jsonb    "question_translations"
    t.string   "meta_field"
    t.boolean  "use_for_relevance_score", default: false, null: false
    t.index ["answer_set_id"], name: "index_questions_on_answer_set_id", using: :btree
    t.index ["project_id"], name: "index_questions_on_project_id", using: :btree
  end

  create_table "results", force: :cascade do |t|
    t.integer  "question_id"
    t.integer  "answer_id"
    t.integer  "user_id"
    t.integer  "project_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.bigint   "tweet_id"
    t.integer  "mturk_token_id"
    t.index ["answer_id"], name: "index_results_on_answer_id", using: :btree
    t.index ["mturk_token_id"], name: "index_results_on_mturk_token_id", using: :btree
    t.index ["project_id"], name: "index_results_on_project_id", using: :btree
    t.index ["question_id"], name: "index_results_on_question_id", using: :btree
    t.index ["tweet_id"], name: "index_results_on_tweet_id", using: :btree
    t.index ["user_id"], name: "index_results_on_user_id", using: :btree
  end

  create_table "transitions", force: :cascade do |t|
    t.integer  "from_question_id"
    t.integer  "answer_id"
    t.integer  "to_question_id"
    t.integer  "project_id"
    t.float    "transition_probability"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["answer_id"], name: "index_transitions_on_answer_id", using: :btree
    t.index ["from_question_id"], name: "index_transitions_on_from_question_id", using: :btree
    t.index ["project_id"], name: "index_transitions_on_project_id", using: :btree
    t.index ["to_question_id"], name: "index_transitions_on_to_question_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "username"
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",        default: 0,     null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "admin",                  default: false, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree
  end

  add_foreign_key "questions", "projects"
end
