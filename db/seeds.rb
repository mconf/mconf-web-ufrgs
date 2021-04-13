# This file should contain all the record creation needed to seed the
# database with its default values. The data can then be loaded with
# the rake db:seed (or created alongside the db with db:setup).

puts "* Create the default site"
puts "  attributes read from the configuration file:"
puts "    #{config.inspect}"
puts "  smtp configurations defaults to Gmail if not set"

params = { # smtp configs for gmail
  "smtp_auto_tls" => true,
  "smtp_server" => "smtp.gmail.com",
  "smtp_port" => 587,
  "smtp_use_tls" => true,
  "smtp_domain" => "gmail.com",
  "smtp_auth_type" => :plain,
  "domain" => 'mconf-example.com'
}
params.merge!(config["site"])
params[:smtp_sender] ||= params[:smtp_login]

if Site.count > 0
  Site.current.update_attributes params
else
  Site.create! params
end


puts "* Create the default webconference server"
puts "  attributes read from the configuration file:"
puts "    #{params.inspect}"

params = configatron.webconf_server.to_hash
if BigbluebuttonServer.count > 0
  BigbluebuttonServer.first.update_attributes params
else
  BigbluebuttonServer.create! params
end


puts "* Create default roles"
Role.where(name: 'User', stage_type: Space.name).first_or_create!
Role.where(name: 'Admin', stage_type: Space.name).first_or_create!
Role.where(name: 'Organizer', stage_type: Event.name).first_or_create!
Role.where(name: 'Global Admin', stage_type: Site.name).first_or_create!
Role.where(name: 'Normal User', stage_type: Site.name).first_or_create!

puts "* Create the administrator account"
puts "  attributes read from the configuration file:"
puts "    #{params.inspect}"

params["password_confirmation"] ||= params["password"]
params["_full_name"] ||= params["username"]
profile = params.delete("profile_attributes")

u = User.where(username: params["username"]).first_or_initialize
u.assign_attributes(params)
u.skip_confirmation!
u.approved = true
if u.save(validate: false)
  u.profile.update_attributes(profile) unless profile.nil?
  u.set_superuser!
else
  puts "ERROR!"
  puts u.errors.inspect
end

puts "* db:seed finished successfully"
