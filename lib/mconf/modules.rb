# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

module Mconf
  module Modules

    # Indicates whether a module `mod` is enabled or not.
    # Used usually to check if a given set of resources should be loaded or not.
    def mod_enabled?(mod)
      Mconf::Modules.mod_enabled?(mod)
    end

    def self.mod_enabled?(mod)
      case mod
      when 'events'
        # mod_loaded?(mod) &&
        defined?(Site) && Site.table_exists? && Site.current &&
          Site.current.respond_to?(:events_enabled) &&
          Site.current.events_enabled?
      else
        false
      end
    end
  end
end
