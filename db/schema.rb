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

ActiveRecord::Schema.define(version: 20170328114422) do

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
    t.string   "answer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "key"
  end

  create_table "projects", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "questions", force: :cascade do |t|
    t.string   "question"
    t.integer  "project_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "answer_set_id"
    t.index ["answer_set_id"], name: "index_questions_on_answer_set_id", using: :btree
    t.index ["project_id"], name: "index_questions_on_project_id", using: :btree
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
