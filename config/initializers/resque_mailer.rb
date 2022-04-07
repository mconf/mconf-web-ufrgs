# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

Resque::Mailer.excluded_environments = []

Resque::Mailer.error_handler = lambda { |mailer, message, error, action, args|
  Mconf::MailerErrorHandler.handle mailer, message, error, action, args
}
