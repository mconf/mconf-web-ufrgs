class AddLegacyEncryptedPasswordToUser < ActiveRecord::Migration
  
  class User <ActiveRecord::Base
  end

  def up
    add_column :users, :legacy_encrypted_password, :string, default: ""

    ActiveRecord::Base.transaction do
      User.find_each do |u|
        u.update_attributes(legacy_encrypted_password: u.encrypted_password)
      end
    end
  end

  def down
    remove_column :users, :legacy_encrypted_password
  end
end
