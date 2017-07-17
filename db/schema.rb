# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160819144737) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "activities", force: true do |t|
    t.integer  "trackable_id"
    t.string   "trackable_type"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "key"
    t.text     "parameters"
    t.integer  "recipient_id"
    t.string   "recipient_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type", using: :btree
  add_index "activities", ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type", using: :btree
  add_index "activities", ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type", using: :btree

  create_table "admins", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admins", ["email"], name: "index_admins_on_email", unique: true, using: :btree
  add_index "admins", ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true, using: :btree

  create_table "alarms", force: true do |t|
    t.integer  "property_id"
    t.integer  "user_id"
    t.datetime "alarm_at"
    t.text     "body"
    t.integer  "checked_by"
    t.datetime "checked_on"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blazer_audits", force: true do |t|
    t.integer  "user_id"
    t.integer  "query_id"
    t.text     "statement"
    t.string   "data_source"
    t.datetime "created_at"
  end

  create_table "blazer_checks", force: true do |t|
    t.integer  "creator_id"
    t.integer  "query_id"
    t.string   "state"
    t.string   "schedule"
    t.text     "emails"
    t.string   "check_type"
    t.text     "message"
    t.datetime "last_run_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blazer_dashboard_queries", force: true do |t|
    t.integer  "dashboard_id"
    t.integer  "query_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blazer_dashboards", force: true do |t|
    t.integer  "creator_id"
    t.text     "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blazer_queries", force: true do |t|
    t.integer  "creator_id"
    t.string   "name"
    t.text     "description"
    t.text     "statement"
    t.string   "data_source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "brands", force: true do |t|
    t.string "name"
  end

  create_table "budgets", force: true do |t|
    t.integer  "user_id"
    t.integer  "category_id"
    t.decimal  "amount"
    t.integer  "month"
    t.integer  "year"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", force: true do |t|
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.string   "title"
    t.text     "encrypted_body"
    t.string   "subject"
    t.integer  "user_id",          null: false
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "conversions", force: true do |t|
    t.integer  "unit_id"
    t.float    "factor"
    t.integer  "other_unit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "corporate_connections", force: true do |t|
    t.integer  "corporate_id"
    t.integer  "property_id"
    t.string   "email"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
  end

  create_table "corporates", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "departments", force: true do |t|
    t.string   "name"
    t.integer  "property_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "departments_tags", force: true do |t|
    t.integer "category_id"
    t.integer "department_id"
  end

  create_table "departments_users", force: true do |t|
    t.integer "department_id"
    t.integer "user_id"
  end

  create_table "engage_entities", force: true do |t|
    t.integer  "property_id"
    t.text     "body"
    t.string   "room_number"
    t.string   "entity_type"
    t.integer  "created_by_id"
    t.integer  "completed_by_id"
    t.datetime "completed_at"
    t.datetime "due_date"
    t.string   "status"
    t.hstore   "metadata"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "engage_messages", force: true do |t|
    t.integer  "property_id"
    t.string   "title"
    t.text     "encrypted_body"
    t.string   "room_number"
    t.integer  "created_by_id"
    t.date     "broadcast_start"
    t.date     "broadcast_end"
    t.integer  "work_order_id"
    t.datetime "completed_at"
    t.integer  "completed_by_id"
    t.date     "follow_up_start"
    t.date     "follow_up_end"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "engage_messages", ["property_id"], name: "index_engage_messages_on_property_id", using: :btree

  create_table "item_orders", force: true do |t|
    t.integer  "purchase_order_id"
    t.integer  "item_id"
    t.integer  "item_request_id"
    t.decimal  "quantity"
    t.decimal  "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_orders", ["item_id"], name: "index_item_orders_on_item_id", using: :btree
  add_index "item_orders", ["item_request_id"], name: "index_item_orders_on_item_request_id", using: :btree
  add_index "item_orders", ["purchase_order_id"], name: "index_item_orders_on_purchase_order_id", using: :btree

  create_table "item_receipts", force: true do |t|
    t.integer  "purchase_receipt_id"
    t.integer  "item_order_id"
    t.integer  "item_id"
    t.decimal  "quantity"
    t.decimal  "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_receipts", ["item_id"], name: "index_item_receipts_on_item_id", using: :btree
  add_index "item_receipts", ["purchase_receipt_id"], name: "index_item_receipts_on_purchase_receipt_id", using: :btree

  create_table "item_requests", force: true do |t|
    t.integer  "purchase_request_id"
    t.integer  "item_id"
    t.decimal  "quantity"
    t.decimal  "count"
    t.decimal  "part_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "skip_inventory"
    t.decimal  "prev_quantity"
  end

  add_index "item_requests", ["item_id"], name: "index_item_requests_on_item_id", using: :btree
  add_index "item_requests", ["purchase_request_id"], name: "index_item_requests_on_purchase_request_id", using: :btree

  create_table "item_tags", force: true do |t|
    t.integer "item_id"
    t.integer "tag_id"
    t.string  "tag_type"
  end

  add_index "item_tags", ["item_id", "tag_id"], name: "index_item_tags_on_item_id_and_tag_id", using: :btree
  add_index "item_tags", ["tag_id", "item_id"], name: "index_item_tags_on_tag_id_and_item_id", using: :btree

  create_table "item_transactions", force: true do |t|
    t.integer  "item_id"
    t.string   "type"
    t.decimal  "change"
    t.string   "purchase_step_type"
    t.integer  "purchase_step_id"
    t.decimal  "cumulative_total"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_transactions", ["item_id"], name: "index_item_transactions_on_item_id", using: :btree

  create_table "items", force: true do |t|
    t.string   "name"
    t.decimal  "count"
    t.integer  "frequency"
    t.decimal  "par_level"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "item_transactions_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "unit_id"
    t.integer  "subpack_unit_id"
    t.integer  "pack_unit_id"
    t.float    "unit_subpack"
    t.float    "subpack_size"
    t.integer  "inventory_unit_id"
    t.integer  "price_unit_id"
    t.integer  "property_id"
    t.boolean  "is_taxable"
    t.boolean  "archived",                default: false
    t.text     "description"
    t.boolean  "is_asset"
    t.decimal  "purchase_cost"
    t.decimal  "pack_size"
    t.integer  "brand_id"
    t.integer  "number"
  end

  add_index "items", ["inventory_unit_id"], name: "index_items_on_inventory_unit_id", using: :btree
  add_index "items", ["pack_unit_id"], name: "index_items_on_pack_unit_id", using: :btree
  add_index "items", ["price_unit_id"], name: "index_items_on_price_unit_id", using: :btree
  add_index "items", ["subpack_unit_id"], name: "index_items_on_subpack_unit_id", using: :btree
  add_index "items", ["unit_id"], name: "index_items_on_unit_id", using: :btree

  create_table "join_invitations", force: true do |t|
    t.integer "sender_id"
    t.integer "invitee_id"
    t.text    "params"
    t.integer "targetable_id"
    t.string  "targetable_type"
  end

  add_index "join_invitations", ["invitee_id"], name: "index_join_invitations_on_invitee_id", using: :btree
  add_index "join_invitations", ["sender_id"], name: "index_join_invitations_on_sender_id", using: :btree

  create_table "magic_tags", force: true do |t|
    t.string   "name"
    t.text     "text"
    t.integer  "property_id"
    t.integer  "created_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "maintenance_attachments", force: true do |t|
    t.string   "file"
    t.string   "attachmentable_type"
    t.integer  "attachmentable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "maintenance_checklist_item_maintenances", force: true do |t|
    t.integer  "maintenance_record_id"
    t.integer  "maintenance_checklist_item_id"
    t.string   "status"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "maintenance_checklist_items", force: true do |t|
    t.integer  "property_id"
    t.integer  "user_id"
    t.string   "name"
    t.string   "maintenance_type"
    t.integer  "area_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "row_order"
    t.boolean  "is_deleted",       default: false
    t.integer  "public_area_id"
  end

  add_index "maintenance_checklist_items", ["property_id"], name: "index_maintenance_checklist_items_on_property_id", using: :btree
  add_index "maintenance_checklist_items", ["user_id"], name: "index_maintenance_checklist_items_on_user_id", using: :btree

  create_table "maintenance_cycles", force: true do |t|
    t.integer  "user_id"
    t.integer  "property_id"
    t.integer  "year"
    t.integer  "start_month"
    t.integer  "frequency_months"
    t.string   "cycle_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ordinality_number"
  end

  add_index "maintenance_cycles", ["property_id"], name: "index_maintenance_cycles_on_property_id", using: :btree
  add_index "maintenance_cycles", ["user_id"], name: "index_maintenance_cycles_on_user_id", using: :btree

  create_table "maintenance_equipment", force: true do |t|
    t.string   "make"
    t.string   "name"
    t.string   "location"
    t.date     "buy_date"
    t.date     "replacement_date"
    t.integer  "property_id"
    t.integer  "equipment_type_id"
    t.text     "instruction"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "warranty"
    t.integer  "lifespan"
    t.integer  "row_order"
    t.datetime "deleted_at"
  end

  create_table "maintenance_equipment_checklist_items", force: true do |t|
    t.string   "name"
    t.text     "tools_required"
    t.integer  "equipment_type_id"
    t.integer  "frequency"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "row_order"
    t.integer  "user_id"
    t.integer  "property_id"
    t.integer  "group_id"
  end

  create_table "maintenance_equipment_types", force: true do |t|
    t.string   "name"
    t.integer  "property_id"
    t.integer  "user_id"
    t.text     "instruction"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "row_order"
    t.datetime "deleted_at"
  end

  create_table "maintenance_inspection_details", force: true do |t|
    t.integer  "work_order_id"
    t.integer  "checklist_item_maintenance_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "maintenance_materials", force: true do |t|
    t.integer  "work_order_id"
    t.integer  "item_id"
    t.decimal  "quantity"
    t.decimal  "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "maintenance_public_areas", force: true do |t|
    t.string   "name"
    t.integer  "property_id"
    t.integer  "user_id"
    t.boolean  "is_deleted",  default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "row_order"
  end

  create_table "maintenance_records", force: true do |t|
    t.integer  "user_id"
    t.integer  "cycle_id"
    t.string   "maintainable_type"
    t.integer  "maintainable_id"
    t.string   "status"
    t.text     "notes"
    t.datetime "started_at"
    t.datetime "completed_on"
    t.datetime "inspected_on"
    t.integer  "inspected_by_id"
    t.text     "inspected_notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "completed_by_id"
    t.integer  "property_id"
    t.integer  "equipment_checklist_group_id"
    t.integer  "created_by"
    t.integer  "updated_by"
  end

  add_index "maintenance_records", ["cycle_id"], name: "index_maintenance_records_on_cycle_id", using: :btree
  add_index "maintenance_records", ["user_id"], name: "index_maintenance_records_on_user_id", using: :btree

  create_table "maintenance_rooms", force: true do |t|
    t.string   "room_number"
    t.integer  "property_id"
    t.integer  "floor"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "maintenance_rooms", ["user_id"], name: "index_maintenance_rooms_on_user_id", using: :btree

  create_table "maintenance_work_orders", force: true do |t|
    t.integer  "maintainable_id"
    t.string   "maintainable_type"
    t.integer  "checklist_item_maintenance_id"
    t.integer  "opened_by_user_id"
    t.datetime "opened_at"
    t.string   "status"
    t.integer  "closed_by_user_id"
    t.datetime "closed_at"
    t.text     "closing_comment"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "property_id"
    t.string   "other_maintainable_location"
    t.string   "priority",                      limit: 1, default: "m"
    t.integer  "assigned_to_id"
    t.date     "due_to_date"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "duration"
    t.datetime "deleted_at"
  end

  add_index "maintenance_work_orders", ["property_id"], name: "index_maintenance_work_orders_on_property_id", using: :btree

  create_table "messages", force: true do |t|
    t.integer  "user_id"
    t.integer  "messagable_id"
    t.text     "body"
    t.string   "attachment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "messagable_type"
  end

  create_table "notifications", force: true do |t|
    t.integer  "user_id"
    t.integer  "property_id"
    t.string   "ntype"
    t.integer  "model_id"
    t.string   "message"
    t.boolean  "read",        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "old_roles", force: true do |t|
    t.integer  "property_id"
    t.string   "name"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "old_roles", ["property_id"], name: "index_old_roles_on_property_id", using: :btree

  create_table "old_roles_users", id: false, force: true do |t|
    t.integer "old_role_id"
    t.integer "user_id"
  end

  add_index "old_roles_users", ["old_role_id", "user_id"], name: "index_old_roles_users_on_old_role_id_and_user_id", using: :btree
  add_index "old_roles_users", ["user_id", "old_role_id"], name: "index_old_roles_users_on_user_id_and_old_role_id", using: :btree

  create_table "permission_attributes", force: true do |t|
    t.integer  "parent_id"
    t.string   "subject"
    t.string   "action"
    t.string   "name"
    t.text     "options"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions", force: true do |t|
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "department_id"
    t.integer  "property_id"
    t.integer  "permission_attribute_id"
    t.text     "options"
  end

  add_index "permissions", ["role_id"], name: "index_permissions_on_role_id", using: :btree

  create_table "procurement_interfaces", force: true do |t|
    t.string  "interface_type"
    t.text    "data"
    t.integer "vendor_id"
  end

  create_table "properties", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "contact_name"
    t.string   "street_address"
    t.string   "zip_code"
    t.string   "city"
    t.string   "email"
    t.string   "phone"
    t.string   "fax"
    t.text     "settings"
    t.string   "time_zone",      default: "Eastern Time (US & Canada)"
  end

  create_table "purchase_orders", force: true do |t|
    t.integer  "user_id"
    t.integer  "purchase_request_id"
    t.integer  "vendor_id"
    t.datetime "sent_at"
    t.datetime "closed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "fax_id"
    t.string   "fax_last_status"
    t.string   "fax_last_message"
    t.string   "state"
    t.integer  "property_id"
    t.integer  "last_user_id"
  end

  add_index "purchase_orders", ["purchase_request_id"], name: "index_purchase_orders_on_purchase_request_id", using: :btree
  add_index "purchase_orders", ["user_id"], name: "index_purchase_orders_on_user_id", using: :btree
  add_index "purchase_orders", ["vendor_id"], name: "index_purchase_orders_on_vendor_id", using: :btree

  create_table "purchase_receipts", force: true do |t|
    t.integer  "user_id"
    t.integer  "purchase_order_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "freight_shipping"
    t.decimal  "cached_total"
    t.integer  "property_id"
  end

  add_index "purchase_receipts", ["user_id"], name: "index_purchase_receipts_on_user_id", using: :btree

  create_table "purchase_requests", force: true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
    t.integer  "property_id"
    t.datetime "approved_at"
    t.text     "rejection_reason"
  end

  add_index "purchase_requests", ["user_id"], name: "index_purchase_requests_on_user_id", using: :btree

  create_table "report_favoritings", force: true do |t|
    t.integer  "report_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "report_runs", force: true do |t|
    t.integer  "user_id"
    t.integer  "report_id"
    t.integer  "property_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "report_runs", ["property_id"], name: "index_report_runs_on_property_id", using: :btree
  add_index "report_runs", ["report_id"], name: "index_report_runs_on_report_id", using: :btree
  add_index "report_runs", ["user_id"], name: "index_report_runs_on_user_id", using: :btree

  create_table "reports", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "groups"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "permalink"
  end

  create_table "roles", force: true do |t|
    t.string "name"
  end

  create_table "room_occupancies", force: true do |t|
    t.integer  "actual"
    t.integer  "forecast"
    t.integer  "room_type_id"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "room_occupancies", ["room_type_id"], name: "index_room_occupancies_on_room_type_id", using: :btree

  create_table "room_types", force: true do |t|
    t.integer  "average_occupancy"
    t.integer  "max_occupancy"
    t.integer  "min_occupancy"
    t.string   "name"
    t.integer  "property_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "room_types", ["property_id"], name: "index_room_types_on_property_id", using: :btree

  create_table "tag_hierarchies", id: false, force: true do |t|
    t.integer "ancestor_id",   null: false
    t.integer "descendant_id", null: false
    t.integer "generations",   null: false
  end

  add_index "tag_hierarchies", ["ancestor_id", "descendant_id"], name: "index_tag_hierarchies_on_ancestor_id_and_descendant_id", unique: true, using: :btree
  add_index "tag_hierarchies", ["descendant_id"], name: "index_tag_hierarchies_on_descendant_id", using: :btree

  create_table "tags", force: true do |t|
    t.string   "type"
    t.string   "name"
    t.boolean  "unboxed_countable"
    t.integer  "parent_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "property_id"
    t.integer  "user_id"
  end

  add_index "tags", ["property_id"], name: "index_tags_on_property_id", using: :btree

  create_table "units", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_list_usages", force: true do |t|
    t.integer  "user_id"
    t.integer  "list_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_roles", force: true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.integer  "property_id"
    t.string   "title"
    t.decimal  "order_approval_limit", default: 0.0
    t.datetime "deleted_at"
  end

  add_index "user_roles", ["deleted_at"], name: "index_user_roles_on_deleted_at", using: :btree

  create_table "users", force: true do |t|
    t.string   "name"
    t.datetime "deleted_at"
    t.string   "email",                  default: ""
    t.string   "encrypted_password",     default: "",  null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "authentication_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_user_id"
    t.string   "avatar"
    t.decimal  "order_approval_limit",   default: 0.0
    t.integer  "corporate_id"
    t.string   "phone_number"
    t.text     "settings"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "username"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "vendor_items", force: true do |t|
    t.boolean  "preferred"
    t.decimal  "items_per_box"
    t.integer  "vendor_id"
    t.integer  "item_id"
    t.integer  "box_unit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "price_cents",    default: 0,     null: false
    t.string   "price_currency", default: "USD", null: false
    t.string   "sku"
  end

  add_index "vendor_items", ["box_unit_id"], name: "index_vendor_items_on_box_unit_id", using: :btree

  create_table "vendors", force: true do |t|
    t.string   "name"
    t.string   "street_address"
    t.string   "zip_code"
    t.string   "city"
    t.string   "email"
    t.string   "phone"
    t.string   "fax"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "contact_name"
    t.string   "shipping_method"
    t.string   "shipping_terms"
    t.integer  "property_id"
    t.string   "payload_id"
  end

  create_table "versions", force: true do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "object_changes"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "votes", force: true do |t|
    t.integer  "votable_id"
    t.string   "votable_type"
    t.integer  "voter_id"
    t.string   "voter_type"
    t.boolean  "vote_flag"
    t.string   "vote_scope"
    t.integer  "vote_weight"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "votes", ["votable_id", "votable_type", "vote_scope"], name: "index_votes_on_votable_id_and_votable_type_and_vote_scope", using: :btree
  add_index "votes", ["voter_id", "voter_type", "vote_scope"], name: "index_votes_on_voter_id_and_voter_type_and_vote_scope", using: :btree

end
