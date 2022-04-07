# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

class DeviseMailer < Devise::Mailer

  include Devise::Controllers::UrlHelpers
  include Mconf::LocaleControllerModule

  default template_path: 'devise/mailer'
  layout 'mailers'

  # override the default method used by devise to set the user's locale
  def devise_mail(record, action, opts = {}, &block)
    I18n.with_locale(get_user_locale(record, nil)) do
      super
    end
  end
  
  def confirmation_instructions(record, token, opts={})
    return if !record.local_auth?

    opts[:subject] = "[#{Site.current.name}] #{t('devise.mailer.confirmation_instructions.subject')}"
    super
  end

  def reset_password_instructions(record, token, opts={})
    return if !record.local_auth?

    opts[:subject] = "[#{Site.current.name}] #{t('devise.mailer.reset_password_instructions.subject')}"
    super
  end
end
