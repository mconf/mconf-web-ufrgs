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

ActiveRecord::Schema.define(version: 20220321165703) do

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
    t.boolean  "notified"
  end

  add_index "activities", ["key"], name: "index_activities_on_key", using: :btree
  add_index "activities", ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type", using: :btree
  add_index "activities", ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type", using: :btree
  add_index "activities", ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type", using: :btree

  create_table "attachments", force: true do |t|
    t.string   "type"
    t.integer  "size"
    t.string   "content_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "space_id"
    t.integer  "author_id"
    t.string   "author_type"
    t.string   "attachment"
  end

  add_index "attachments", ["space_id"], name: "index_attachments_on_space_id", using: :btree

  create_table "bigbluebutton_attendees", force: true do |t|
    t.string   "user_id"
    t.string   "external_user_id"
    t.string   "user_name"
    t.decimal  "join_time",                precision: 14, scale: 0
    t.decimal  "left_time",                precision: 14, scale: 0
    t.integer  "bigbluebutton_meeting_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bigbluebutton_meetings", force: true do |t|
    t.integer  "room_id"
    t.string   "meetingid"
    t.string   "name"
    t.boolean  "running",                                default: false
    t.boolean  "recorded",                               default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "creator_id"
    t.string   "creator_name"
    t.string   "server_url"
    t.string   "server_secret"
    t.decimal  "create_time",   precision: 14, scale: 0
    t.boolean  "ended",                                  default: false
    t.decimal  "finish_time",   precision: 14, scale: 0
  end

  add_index "bigbluebutton_meetings", ["meetingid", "create_time"], name: "index_bigbluebutton_meetings_on_meetingid_and_create_time", unique: true, using: :btree
  add_index "bigbluebutton_meetings", ["room_id", "create_time"], name: "index_bigbluebutton_meetings_on_room_id_create_time", using: :btree
  add_index "bigbluebutton_meetings", ["room_id"], name: "index_bigbluebutton_meetings_on_room_id", using: :btree

  create_table "bigbluebutton_metadata", force: true do |t|
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "name"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bigbluebutton_metadata", ["owner_id", "owner_type", "name"], name: "bigbluebutton_metadata_owner_id_IDX", using: :btree
  add_index "bigbluebutton_metadata", ["owner_id", "owner_type"], name: "index_bigbluebutton_metadata_on_owner_id_owner_type", using: :btree

  create_table "bigbluebutton_playback_formats", force: true do |t|
    t.integer  "recording_id"
    t.string   "url"
    t.integer  "length"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "playback_type_id"
  end

  add_index "bigbluebutton_playback_formats", ["playback_type_id"], name: "index_bigbluebutton_playback_formats_on_playback_type_id", using: :btree
  add_index "bigbluebutton_playback_formats", ["recording_id"], name: "index_bigbluebutton_playback_formats_on_recording_id", using: :btree

  create_table "bigbluebutton_playback_types", force: true do |t|
    t.string   "identifier"
    t.boolean  "visible",      default: false
    t.boolean  "default",      default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "downloadable", default: false
  end

  create_table "bigbluebutton_recordings", force: true do |t|
    t.integer  "server_id"
    t.integer  "room_id"
    t.string   "recordid"
    t.string   "meetingid"
    t.string   "name"
    t.boolean  "published",                                          default: false
    t.boolean  "available",                                          default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "meeting_id"
    t.integer  "size",            limit: 8,                          default: 0
    t.decimal  "start_time",                precision: 14, scale: 0
    t.decimal  "end_time",                  precision: 14, scale: 0
    t.text     "recording_users"
  end

  add_index "bigbluebutton_recordings", ["meeting_id"], name: "index_bigbluebutton_recordings_on_meeting_id", using: :btree
  add_index "bigbluebutton_recordings", ["recordid"], name: "index_bigbluebutton_recordings_on_recordid", unique: true, using: :btree
  add_index "bigbluebutton_recordings", ["room_id"], name: "index_bigbluebutton_recordings_on_room_id", using: :btree
  add_index "bigbluebutton_recordings", ["server_id"], name: "index_bigbluebutton_recordings_on_server_id", using: :btree

  create_table "bigbluebutton_room_options", force: true do |t|
    t.integer  "room_id"
    t.string   "default_layout"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "presenter_share_only"
    t.boolean  "auto_start_video"
    t.boolean  "auto_start_audio"
    t.string   "background"
  end

  add_index "bigbluebutton_room_options", ["room_id"], name: "index_bigbluebutton_room_options_on_room_id", using: :btree

  create_table "bigbluebutton_rooms", force: true do |t|
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "meetingid"
    t.string   "name"
    t.string   "attendee_key"
    t.string   "moderator_key"
    t.string   "welcome_msg"
    t.string   "logout_url"
    t.string   "voice_bridge"
    t.string   "dial_number"
    t.integer  "max_participants"
    t.boolean  "private",                                             default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "external",                                            default: false
    t.string   "param"
    t.boolean  "record_meeting",                                      default: false
    t.integer  "duration",                                            default: 0
    t.string   "moderator_api_password"
    t.string   "attendee_api_password"
    t.decimal  "create_time",                precision: 14, scale: 0
    t.string   "moderator_only_message"
    t.boolean  "auto_start_recording",                                default: false
    t.boolean  "allow_start_stop_recording",                          default: true
  end

  add_index "bigbluebutton_rooms", ["meetingid"], name: "index_bigbluebutton_rooms_on_meetingid", unique: true, using: :btree
  add_index "bigbluebutton_rooms", ["owner_id", "owner_type"], name: "index_bigbluebutton_rooms_on_owner_id_owner_type", using: :btree
  add_index "bigbluebutton_rooms", ["param"], name: "index_bigbluebutton_rooms_on_param", using: :btree

  create_table "bigbluebutton_server_configs", force: true do |t|
    t.integer  "server_id"
    t.text     "available_layouts"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bigbluebutton_servers", force: true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "secret"
    t.string   "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "param"
  end

  add_index "bigbluebutton_servers", ["param"], name: "index_bigbluebutton_servers_on_param", using: :btree

  create_table "certificate_tokens", force: true do |t|
    t.string   "identifier"
    t.integer  "user_id"
    t.text     "public_key"
    t.boolean  "new_account",        default: false
    t.datetime "current_sign_in_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "certificate_tokens", ["identifier"], name: "index_certificate_tokens_on_identifier", unique: true, using: :btree
  add_index "certificate_tokens", ["user_id"], name: "index_certificate_tokens_on_user_id", unique: true, using: :btree

  create_table "db_files", force: true do |t|
    t.binary "data"
  end

  create_table "events", force: true do |t|
    t.string   "name"
    t.text     "summary"
    t.text     "description"
    t.string   "social_networks"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.datetime "start_on"
    t.datetime "end_on"
    t.string   "time_zone"
    t.string   "location"
    t.string   "address"
    t.float    "latitude",        limit: 24
    t.float    "longitude",       limit: 24
    t.string   "permalink"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "events", ["end_on"], name: "index_events_on_end_on", using: :btree
  add_index "events", ["owner_id", "owner_type"], name: "index_events_on_owner_id_owner_type", using: :btree
  add_index "events", ["owner_id"], name: "index_events_on_owner_id", using: :btree
  add_index "events", ["owner_type"], name: "index_events_on_owner_type", using: :btree
  add_index "events", ["permalink"], name: "index_events_on_permalink", using: :btree
  add_index "events", ["start_on"], name: "index_events_on_start_on", using: :btree

  create_table "invitations", force: true do |t|
    t.integer  "target_id"
    t.string   "target_type"
    t.integer  "sender_id"
    t.integer  "recipient_id"
    t.string   "recipient_email"
    t.string   "type"
    t.string   "title"
    t.text     "description"
    t.string   "url"
    t.datetime "starts_on"
    t.datetime "ends_on"
    t.boolean  "ready",            default: false
    t.boolean  "sent",             default: false
    t.boolean  "result",           default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "invitation_group"
  end

  add_index "invitations", ["recipient_id"], name: "index_invitations_on_recipient_id", using: :btree
  add_index "invitations", ["sender_id"], name: "index_invitations_on_sender_id", using: :btree
  add_index "invitations", ["target_id", "target_type"], name: "index_invitations_on_target_id_and_target_type", using: :btree

  create_table "join_requests", force: true do |t|
    t.string   "request_type"
    t.integer  "candidate_id"
    t.integer  "introducer_id"
    t.integer  "group_id"
    t.string   "group_type"
    t.string   "comment"
    t.integer  "role_id"
    t.string   "email"
    t.boolean  "accepted"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "processed_at"
    t.string   "secret_token"
  end

  add_index "join_requests", ["candidate_id"], name: "index_join_requests_on_candidate_id", using: :btree
  add_index "join_requests", ["group_id", "group_type"], name: "index_join_requests_on_group_id_group_type", using: :btree
  add_index "join_requests", ["introducer_id"], name: "index_join_requests_on_introducer_id", using: :btree
  add_index "join_requests", ["request_type"], name: "index_join_requests_on_request_type", using: :btree
  add_index "join_requests", ["role_id"], name: "index_join_requests_on_role_id", using: :btree
  add_index "join_requests", ["secret_token"], name: "index_join_requests_on_secret_token", using: :btree

  create_table "ldap_tokens", force: true do |t|
    t.integer  "user_id"
    t.string   "identifier"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "new_account",        default: false
    t.datetime "current_sign_in_at"
  end

  add_index "ldap_tokens", ["identifier"], name: "index_ldap_tokens_on_identifier", unique: true, using: :btree
  add_index "ldap_tokens", ["user_id"], name: "index_ldap_tokens_on_user_id", unique: true, using: :btree

  create_table "participant_confirmations", force: true do |t|
    t.string   "token"
    t.integer  "participant_id"
    t.datetime "confirmed_at"
    t.datetime "email_sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "participant_confirmations", ["participant_id"], name: "index_participant_confirmations_on_participant_id", using: :btree
  add_index "participant_confirmations", ["token"], name: "index_participant_confirmations_on_token", using: :btree

  create_table "participants", force: true do |t|
    t.integer  "owner_id"
    t.string   "owner_type"
    t.integer  "event_id"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "participants", ["event_id"], name: "fk_participants_event_id", using: :btree
  add_index "participants", ["owner_id", "owner_type"], name: "index_participants_on_owner_id_owner_type", using: :btree

  create_table "permissions", force: true do |t|
    t.integer  "user_id",      null: false
    t.integer  "subject_id",   null: false
    t.string   "subject_type", null: false
    t.integer  "role_id",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permissions", ["role_id"], name: "fk_permissions_role_id", using: :btree
  add_index "permissions", ["subject_id"], name: "index_permissions_on_subject_id", using: :btree
  add_index "permissions", ["subject_type"], name: "index_permissions_on_subject_type", using: :btree
  add_index "permissions", ["user_id", "subject_type", "subject_id"], name: "index_permissions_on_user_id_subject_type_subject_id", using: :btree
  add_index "permissions", ["user_id", "subject_type"], name: "index_permissions_on_user_id_subject_type", using: :btree
  add_index "permissions", ["user_id"], name: "index_permissions_on_user_id", using: :btree

  create_table "posts", force: true do |t|
    t.string   "title"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "reader_id"
    t.integer  "space_id"
    t.integer  "author_id"
    t.string   "author_type"
    t.integer  "parent_id"
  end

  add_index "posts", ["author_id", "author_type"], name: "index_posts_on_author_id_author_type", using: :btree
  add_index "posts", ["parent_id"], name: "index_posts_on_parent_id", using: :btree
  add_index "posts", ["reader_id"], name: "index_posts_on_reader_id", using: :btree
  add_index "posts", ["space_id"], name: "index_posts_on_space_id", using: :btree

  create_table "profiles", force: true do |t|
    t.string  "organization"
    t.string  "phone"
    t.string  "mobile"
    t.string  "fax"
    t.string  "address"
    t.string  "city"
    t.string  "zipcode"
    t.string  "province"
    t.string  "country"
    t.integer "user_id"
    t.string  "prefix_key",   default: ""
    t.text    "description"
    t.string  "url"
    t.string  "skype"
    t.string  "im"
    t.integer "visibility",   default: 3
    t.string  "full_name"
    t.string  "logo_image"
  end

  add_index "profiles", ["full_name"], name: "index_profiles_on_full_name", using: :btree
  add_index "profiles", ["user_id"], name: "profiles_user_id_IDX", using: :btree

  create_table "roles", force: true do |t|
    t.string "name"
    t.string "stage_type"
  end

  add_index "roles", ["stage_type"], name: "index_roles_on_stage_type", using: :btree

  create_table "shib_tokens", force: true do |t|
    t.integer  "user_id"
    t.string   "identifier"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "new_account",        default: false
    t.datetime "current_sign_in_at"
  end

  add_index "shib_tokens", ["identifier"], name: "index_shib_tokens_on_identifier", unique: true, using: :btree
  add_index "shib_tokens", ["user_id"], name: "index_shib_tokens_on_user_id", unique: true, using: :btree

  create_table "sites", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "domain"
    t.string   "smtp_login"
    t.string   "locale"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "ssl",                            default: false
    t.boolean  "exception_notifications",        default: false
    t.string   "exception_notifications_email"
    t.text     "signature"
    t.string   "presence_domain"
    t.string   "feedback_url"
    t.boolean  "shib_enabled",                   default: false
    t.string   "shib_name_field"
    t.string   "shib_email_field"
    t.string   "exception_notifications_prefix"
    t.string   "smtp_password"
    t.string   "analytics_code"
    t.boolean  "smtp_auto_tls"
    t.string   "smtp_server"
    t.integer  "smtp_port"
    t.boolean  "smtp_use_tls"
    t.string   "smtp_domain"
    t.string   "smtp_auth_type"
    t.string   "smtp_sender"
    t.string   "xmpp_server"
    t.text     "shib_env_variables"
    t.string   "shib_login_field"
    t.string   "timezone",                       default: "UTC"
    t.string   "external_help"
    t.boolean  "ldap_enabled"
    t.string   "ldap_host"
    t.integer  "ldap_port"
    t.string   "ldap_user"
    t.string   "ldap_user_password"
    t.string   "ldap_user_treebase"
    t.string   "ldap_username_field"
    t.string   "ldap_email_field"
    t.string   "ldap_name_field"
    t.boolean  "require_registration_approval",  default: false,                  null: false
    t.boolean  "events_enabled",                 default: false
    t.boolean  "registration_enabled",           default: true,                   null: false
    t.string   "shib_principal_name_field"
    t.string   "ldap_filter"
    t.boolean  "shib_always_new_account",        default: false
    t.boolean  "local_auth_enabled",             default: true
    t.string   "visible_locales",                default: "---\n- en\n- pt-br\n"
    t.string   "room_dial_number_pattern"
    t.boolean  "captcha_enabled",                default: false
    t.string   "recaptcha_public_key"
    t.string   "recaptcha_private_key"
    t.boolean  "require_space_approval",         default: false
    t.boolean  "forbid_user_space_creation",     default: false
    t.string   "max_upload_size",                default: "15000000"
    t.string   "allowed_to_record"
    t.boolean  "shib_update_users",              default: false
    t.boolean  "use_gravatar",                   default: false
    t.string   "smtp_receiver"
    t.boolean  "unauth_access_to_conferences",   default: true
    t.boolean  "certificate_login_enabled"
    t.string   "certificate_id_field"
    t.string   "certificate_name_field"
  end

  create_table "spaces", force: true do |t|
    t.string   "name"
    t.boolean  "deleted"
    t.boolean  "public",              default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.string   "permalink"
    t.boolean  "disabled",            default: false
    t.boolean  "repository",          default: false
    t.string   "logo_image"
    t.boolean  "approved",            default: false
    t.datetime "last_activity"
    t.integer  "last_activity_count"
  end

  add_index "spaces", ["approved"], name: "index_spaces_on_approved", using: :btree
  add_index "spaces", ["disabled"], name: "index_spaces_on_disabled", using: :btree
  add_index "spaces", ["last_activity"], name: "index_spaces_on_last_activity", using: :btree
  add_index "spaces", ["last_activity_count"], name: "index_spaces_on_last_activity_count", using: :btree
  add_index "spaces", ["permalink"], name: "index_spaces_on_permalink", using: :btree
  add_index "spaces", ["public"], name: "index_spaces_on_public", using: :btree

  create_table "taggings", force: true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["context"], name: "index_taggings_on_context", using: :btree
  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy", using: :btree
  add_index "taggings", ["taggable_id"], name: "index_taggings_on_taggable_id", using: :btree
  add_index "taggings", ["taggable_type"], name: "index_taggings_on_taggable_type", using: :btree
  add_index "taggings", ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type", using: :btree
  add_index "taggings", ["tagger_id"], name: "index_taggings_on_tagger_id", using: :btree

  create_table "tags", force: true do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "users", force: true do |t|
    t.string   "username"
    t.string   "email",                                default: "",    null: false
    t.string   "encrypted_password",                   default: "",    null: false
    t.string   "password_salt",             limit: 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "disabled",                             default: false
    t.datetime "confirmed_at"
    t.string   "timezone"
    t.boolean  "expanded_post",                        default: false
    t.string   "locale"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                        default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.boolean  "can_record"
    t.boolean  "approved",                             default: false, null: false
    t.datetime "current_local_sign_in_at"
    t.string   "legacy_encrypted_password",            default: ""
  end

  add_index "users", ["approved"], name: "index_users_on_approved", using: :btree
  add_index "users", ["can_record"], name: "index_users_on_can_record", using: :btree
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["disabled"], name: "index_users_on_disabled", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", using: :btree

end
