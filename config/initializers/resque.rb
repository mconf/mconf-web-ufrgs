# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require 'resque'

logger = Logger.new(STDOUT)
logger.formatter = proc do |severity, datetime, progname, msg|
  formatted_datetime = datetime.strftime("%Y-%m-%d %H:%M:%S.") << datetime.usec.to_s[0..2].rjust(3)
  "#{formatted_datetime} [#{severity}] #{msg} (pid:#{$$})\n"
end
Resque.logger = logger
Resque.logger.level = Logger::INFO
#Resque.logger.level = Logger::DEBUG

attrs = {
  host: configatron.redis.host,
  port: configatron.redis.port,
  db: configatron.redis.db
}
attrs[:password] = configatron.redis.password unless configatron.redis.password.blank?
Resque.redis = Redis.new(attrs)

# If you want to be able to dynamically change the schedule,
# uncomment this line.  A dynamic schedule can be updated via the
# Resque::Scheduler.set_schedule (and remove_schedule) methods.
# When dynamic is set to true, the scheduler process looks for
# schedule changes and applies them on the fly.
# Note: This feature is only available in >=2.0.0.
# Resque::Scheduler.dynamic = true

# The schedule doesn't need to be stored in a YAML, it just needs to
# be a hash.  YAML is usually the easiest.
Resque.schedule = YAML.load_file('config/workers_schedule.yml')

class CanAccessResque
  def self.matches?(request)
    current_user = request.env['warden'].user
    return false if current_user.blank?
    Abilities.ability_for(current_user).can? :manage, Resque
  end
end
