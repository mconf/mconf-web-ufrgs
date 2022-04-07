# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require 'devise/encryptors/station_encryptor'
require 'digest/sha1'
require './lib/mconf/approval_module'

class User < ActiveRecord::Base
  include PublicActivity::Common
  include Mconf::ApprovalModule
  include Mconf::DisableModule

  # TODO: block :username from being modified after registration

  ## Devise setup
  # Other available devise modules are:
  # :token_authenticatable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :confirmable, :recoverable, :rememberable, :trackable,
         :validatable, :encryptable
  # Virtual attribute for authenticating by either username or email
  attr_accessor :login
  # To login with username or email, see: http://goo.gl/zdIZ5
  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      hash = { :value => login.downcase }
      where_clause = ["lower(username) = :value OR lower(email) = :value", hash]
      where(conditions).where(where_clause).first
    else
      where(conditions).first
    end
  end

  validates :username,
    presence: true,
    format: /\A[A-Za-z0-9\-_]*\z/,
    length: { minimum: 1 },
    identifier_uniqueness: true,
    room_param_uniqueness: true

  extend FriendlyId
  friendly_id :username

  validates :email, uniqueness: true, presence: true, email: true

  has_and_belongs_to_many :spaces, -> { where(permissions: { subject_type: 'Space' }).uniq },
                          join_table: :permissions, association_foreign_key: "subject_id"

  has_many :join_requests, foreign_key: :candidate_id
  has_many :permissions
  has_one :profile, :dependent => :destroy
  has_many :posts, :as => :author
  has_one :bigbluebutton_room, :as => :owner, :dependent => :destroy
  has_one :ldap_token, :dependent => :destroy
  has_one :shib_token, :dependent => :destroy
  has_one :certificate_token, :dependent => :destroy

  after_initialize :init

  accepts_nested_attributes_for :bigbluebutton_room

  # Will be set to a user when the user was registered by an admin.
  attr_accessor :created_by

  # Full name must go to the profile, but it is provided by the user when
  # signing up so we have to cache it until the profile is created
  attr_accessor :_full_name

  # BigbluebuttonRoom requires an identifier with 3 chars generated from :name
  # So we'll require :_full_name and :username to have length >= 3
  validates :_full_name, :presence => true, :length => { :minimum => 3 }, :on => :create

  # for the associated BigbluebuttonRoom
  # attr_accessible :bigbluebutton_room_attributes
  accepts_nested_attributes_for :bigbluebutton_room

  after_create :create_webconf_room
  after_update :update_webconf_room

  before_destroy :before_disable_and_destroy, prepend: true

  default_scope { where(disabled: false) }

  # Search users based on a list of words
  scope :search_by_terms, -> (words, include_private=false) {
    query = joins(:profile).includes(:profile)

    if words.present?
      words ||= []
      words = [words] unless words.is_a?(Array)
      query_strs = []
      query_params = []
      query_orders = []

      words.reject(&:blank?).each do |word|
        str  = "profiles.full_name LIKE ? OR users.username LIKE ?"
        str += " OR users.email LIKE ?" if include_private
        query_strs << str
        query_params += ["%#{word}%", "%#{word}%"]
        query_params += ["%#{word}%"] if include_private
        query_orders += [
          "CASE WHEN profiles.full_name LIKE '%#{word}%' THEN 1 ELSE 0 END + \
           CASE WHEN users.username LIKE '%#{word}%' THEN 1 ELSE 0 END + \
           CASE WHEN users.email LIKE '%#{word}%' THEN 1 ELSE 0 END"
        ]
      end
      query = query.where(query_strs.join(' OR '), *query_params.flatten)
                .order(query_orders.join(' + ') + " DESC")
    end

    query
  }

  # The default ordering for search methods
  scope :search_order, -> {
    order("profiles.full_name")
  }

  # Returns only users that are admins of the site
  scope :superusers, -> (is_superuser=true) {
    if is_superuser
      where(id: Permission.where(subject: Site.current, role: Site.roles[:admin]).select(:user_id))
    else
      where.not(id: Permission.where(subject: Site.current, role: Site.roles[:admin]).select(:user_id))
    end
  }

  # Returns only the users that have the authentication methods selected.
  # `auth_methods` is an array with one or more of the following auth methods:
  # * `:shibboleth`
  # * `:ldap`
  # * `:local`
  scope :with_auth, -> (auth_methods, connector="AND") {
    arr = []

    arr.push("shib_tokens.id IS NOT NULL") if auth_methods.include?(:shibboleth)
    arr.push("ldap_tokens.id IS NOT NULL") if auth_methods.include?(:ldap)
    arr.push("certificate_tokens.id IS NOT NULL") if auth_methods.include?(:certificate)
    if auth_methods.include?(:local)
      ldap_str = "ldap_tokens.id IS NULL OR ldap_tokens.new_account = 'false'"
      shib_str = "shib_tokens.id IS NULL OR shib_tokens.new_account = 'false'"
      cert_str = "certificate_tokens.id IS NULL OR certificate_tokens.new_account = 'false'"
      arr.push("((#{ldap_str}) AND (#{shib_str}) AND (#{cert_str}))")
    end

    arr = arr.join(" #{connector} ")

    unless arr.empty?
      joins("LEFT JOIN shib_tokens ON shib_tokens.user_id = users.id")
        .joins("LEFT JOIN ldap_tokens ON ldap_tokens.user_id = users.id")
        .joins("LEFT JOIN certificate_tokens ON certificate_tokens.user_id = users.id")
        .where(arr)
    end
  }

  alias_attribute :name, :full_name
  alias_attribute :title, :full_name
  alias_attribute :permalink, :username

  delegate :full_name, :logo, :organization, :city, :country, :logo_image, :logo_image_url, :to => :profile

  # set to true when the user signs in via an external authentication method (e.g. LDAP)
  attr_accessor :signed_in_via_external

  # In case the profile is accessed before it is created, we build one on the fly.
  # Important specially because we have method delegated to the profile.
  def profile_with_initialize
    profile_without_initialize || build_profile
  end
  alias_method_chain :profile, :initialize

  def ability
    @ability ||= Abilities.ability_for(self)
  end

  # Returns true if the user is anonymous (not registered)
  def anonymous?
    self.new_record?
  end

  def require_approval?
    Site.current.require_registration_approval
  end

  def create_webconf_room
    params = {
      :owner => self,
      :param => self.username,
      :name => self._full_name,
      :logout_url => "/feedback/webconf/",
      :moderator_key => SecureRandom.hex(8),
      :attendee_key => SecureRandom.hex(4)
    }
    create_bigbluebutton_room(params)
  end

  def update_webconf_room
    if self.username_changed?
      params = { param: self.username }
      bigbluebutton_room.update_attributes(params)
    end
  end

  # Full location: city + country
  def location
    [ self.city.presence, self.country.presence ].compact.join(', ')
  end

  after_create :create_user_profile
  def create_user_profile
    create_profile({full_name: self._full_name})
  end

  # Builds a guest user based on the e-mail
  def self.build_guest opt={}
    return nil if opt[:email].blank?

    User.new :email => opt[:email], :username => I18n.t('_other.user.guest', :email => opt[:email])
  end

  def self.with_disabled
    unscope(where: :disabled) # removes the target scope only
  end

  def <=>(user)
    self.username <=> user.username
  end

  def other_public_spaces
    Space.public_spaces.order('name') - spaces
  end

  def fellows(name=nil, limit=nil)
    limit = limit || 5            # default to 5
    limit = 50 if limit.to_i > 50 # no more than 50

    # ids of unique users that belong to the same spaces
    ids = Permission.where(:subject_id => self.space_ids).pluck(:user_id)

    # filters and selects the users
    query = User.where(:id => ids).joins(:profile).where("users.id != ?", self.id)
    query = query.where("profiles.full_name LIKE ?", "%#{name}%") unless name.nil?
    query.limit(limit).order("profiles.full_name").includes(:profile)
  end

  def public_fellows
    fellows
  end

  def private_fellows
    ids = spaces.where(:public => false).map(&:user_ids).flatten.compact
    User.where(:id => ids).where("users.id != ?", self.id).sort_by{ |u| u.name.downcase }
  end

  def events
    ids = Event.where(:owner_type => 'User', :owner_id => id).ids
    ids += permissions.where(:subject_type => 'Event').pluck(:subject_id)
    Event.where(:id => ids)
  end

  def has_events_in_this_space?(space)
    !events.select{|ev| ev.owner_type=='Space' && ev.owner_id==space}.empty?
  end

  # Returns an array with all the webconference rooms accessible to this user
  # Includes his own room, the rooms for the spaces he belogs to and the room
  # for all public spaces
  def accessible_rooms
    rooms = BigbluebuttonRoom.where(:owner_type => "User", :owner_id => self.id)
    rooms += self.spaces.map(&:bigbluebutton_room)
    rooms += Space.public_spaces.map(&:bigbluebutton_room)
    rooms.uniq!
    rooms
  end

  # Sets the user as approved and skips confirmation
  def approve!
    skip_confirmation! unless confirmed?
    update_attributes(approved: true)
  end

  # Overrides a method from devise, see:
  # https://github.com/plataformatec/devise/wiki/How-To%3a-Require-admin-to-activate-account-before-sign_in
  def active_for_authentication?
    super && (!Site.current.require_registration_approval? || approved?)
  end

  # Overrides a method from devise, see:
  # https://github.com/plataformatec/devise/wiki/How-To%3a-Require-admin-to-activate-account-before-sign_in
  def inactive_message
    if !approved? && Site.current.require_registration_approval?
      :not_approved
    else
      super # Use whatever other message
    end
  end

  # Overrides a method from devise to send emails using a queue system, see:
  # https://github.com/heartcombo/devise#activejob-integration
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver
  end

  # Return the list of spaces in which the user has a pending join request or invitation.
  def pending_spaces
    requests = JoinRequest.where(:candidate_id => self, :processed_at => nil, :group_type => 'Space')
    ids = requests.pluck(:group_id)
    # note: not 'find' because some of the spaces might be disabled and 'find' would raise
    #   an exception
    Space.where(:id => ids)
  end

  after_create :new_activity_user_created
  def new_activity_user_created
    if created_by.present?
      create_activity 'created_by_admin', owner: created_by, notified: false, recipient: self
    else
      create_activity 'created', owner: self, notified: !require_approval?, recipient: self
    end
  end

  def created_by_shib?
    ShibToken.user_created_by_shib?(self)
  end

  def created_by_ldap?
    LdapToken.user_created_by_ldap?(self)
  end

  def created_by_certificate?
    CertificateToken.user_created_by_certificate?(self)
  end

  def local_auth?
    !created_by_shib? && !created_by_ldap? && !created_by_certificate?
  end

  def sign_in_methods
    {
      shibboleth: self.shib_token.present?,
      ldap: self.ldap_token.present?,
      certificate: self.certificate_token.present?,
      local: self.local_auth?
    }
  end

  def last_sign_in_date
    current_local_sign_in_at
  end

  def sign_in_method_name
    "local"
  end

  def last_sign_in_method
    # note: methods at the end of the array have priority in case the sign in dates
    # are equal (so keep 'self' as first!)
    [self, shib_token, ldap_token, certificate_token].reject(&:blank?).sort_by{ |method|
      method.last_sign_in_date || Time.at(0)
    }.last.sign_in_method_name
  end

  def superuser
    Permission.where(subject: Site.current, user: self, role: Site.roles[:admin]).first.present?
  end

  def superuser?
    superuser
  end

  def set_superuser!(value=true)
    if value
      Permission.find_or_create_by(subject: Site.current, user: self, role: Site.roles[:admin])
    else
      permission = Permission.find_by(subject: Site.current, user: self, role: Site.roles[:admin])
      permission.destroy if permission.present?
    end
  end

  # Returns the user's first role/enrollment.
  def enrollment
    enrollments.first
  end

  # Returns all active roles/enrollments
  def enrollments
    result = []
    if self.shib_token.present?
      data = self.shib_token.data
      value = data['ufrgsVinculo']
      if value.present?
        # value is a string with several "enrollments" in the format as the example below:
        # 'ativo:2:Tutor de disciplina:1:Instituto de Informática:NULL:NULL:NULL:NULL:01/01/2011:NULL'
        value.split(";").each do |enrollment|
          enrollment_a = enrollment.split(":")
          result << enrollment_a[2] if enrollment_a[0] == 'ativo'
        end
      end
    end
    result
  end

  # Returns whether the user has a role allowed to record meetings.
  def has_enrollment_allowed_to_record?(room)
    enrollments.map { |e| is_enrollment_allowed_to_record?(e, room) }.any?
  end

  protected

  def before_disable_and_destroy
    # get all the spaces the user is an admin of
    # do it first so permissions still exist
    admin_in = self.permissions
               .where(subject_type: 'Space', role_id: Role.find_by_name('Admin'))
               .map(&:subject)
    admin_in.compact! # remove nil (disabled) spaces

    # removes all pending join requests sent or received by the user
    join_requests.where(processed_at: nil).destroy_all

    # remove all permissions
    permissions.destroy_all

    # Disable spaces if this user was the last admin
    admin_in.each do |space|
      space.disable if space.admins.empty?
    end
  end

  # For the disable module
  def before_disable
    before_disable_and_destroy
  end

  def init
    @created_by = nil
  end

  # This overrides the method from Devise::Models::Trackable
  def update_tracked_fields(request)
    super (request)
    unless signed_in_via_external
      self.current_local_sign_in_at = self.current_sign_in_at
    end
  end

  # Returns whether a enrollment (a string, such as "Docente") is permitted to record meetings.
  def is_enrollment_allowed_to_record?(enrollment, room)
    if enrollment.blank?
      false
    else
      enrollment_to_match = I18n.transliterate(enrollment)
      # list of enrollments allowed to record
      all_allowed = Site.current.allowed_to_record

      all_allowed.each do |allowed|
        allowed = I18n.transliterate(allowed)
        if enrollment_to_match.match(/#{Regexp.quote(allowed)}/i)
          return true
        end
      end

      if enrollment.match(/aluno/i) && (room.owner_type == Space.name && room.owner.admins.include?(self))
        return true
      end
    end

    false
  end
end
