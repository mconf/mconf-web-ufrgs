# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

# TODO: #1271 This class is only needed to support users that were generated
#       with station and therefore have a salt. Devise's methods were overriden 
#       (*) in User model to validate passwords first with this, and then migrate
#       the password to Devise's standard encryption.
# (*) Source:
# https://github.com/plataformatec/devise/wiki/How-To:-Migration-legacy-database
#
# TODO: This encryptor should be removed in the future, when all (or the majority of) users
#       have passwords migrated to use Bcrypt (Devise's standard encryptor).
#       Also remove legacy_encrypted_password and password_salt (isn't used by Bcrypt)
#       columns from User table.

require 'digest/sha1'

module Devise
  module Encryptable
    module Encryptors
      class StationEncryptor < Base
        def self.digest(password, stretches, salt, pepper)
          Digest::SHA1.hexdigest("--#{salt}--#{password}--")
        end
      end
    end
  end
end
