require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/time/calculations'
require 'active_model'

class StaffActionLogger
  def initialize(*)
    true
  end

  def log_name_change(*)
    true
  end
end

class User
  include ::ActiveModel::Model
  attr_accessor :date_of_birth
  attr_accessor :name
  attr_accessor :user_profile
  attr_accessor :locale
  attr_accessor :title
  attr_accessor :user_option
  attr_accessor :custom_fields

  def id
    1
  end

  def reload
    self
  end

  def save
    true
  end

  def custom_fields
    {}
  end

  def self.transaction
    yield
  end
end

class UserProfile
  attr_accessor :card_background
  attr_accessor :location
  attr_accessor :profile_background
  attr_accessor :website
  attr_accessor :bio_raw

  def save
    true
  end

  def website
    'http://www.example.com'
  end
end

class Guardian
  attr_accessor :user
  private

  def initialize(user)
    @user = user
  end
end

class SiteSetting
  cattr_accessor :sso_url
  cattr_writer :enable_sso
  cattr_writer :sso_overrides_bio

  def self.enable_sso
    @enable_sso || true
  end

  def self.sso_overrides_bio
    @sso_overrides_bio || false
  end
end

class UserUpdater
  CATEGORY_IDS = {
    watched_first_post_category_ids: :watching_first_post,
    watched_category_ids: :watching,
    tracked_category_ids: :tracking,
    muted_category_ids: :muted
  }

  TAG_NAMES = {
    watching_first_post_tags: :watching_first_post,
    watched_tags: :watching,
    tracked_tags: :tracking,
    muted_tags: :muted
  }

  OPTION_ATTR = [
    :email_always,
    :mailing_list_mode,
    :mailing_list_mode_frequency,
    :email_digests,
    :email_direct,
    :email_private_messages,
    :external_links_in_new_tab,
    :enable_quoting,
    :dynamic_favicon,
    :disable_jump_reply,
    :automatically_unpin_topics,
    :digest_after_minutes,
    :new_topic_duration_minutes,
    :auto_track_topics_after_msecs,
    :notification_level_when_replying,
    :email_previous_replies,
    :email_in_reply_to,
    :like_notification_frequency,
    :include_tl0_in_digests,
    :theme_key,
    :allow_private_messages,
    :homepage_id,
  ]

  def can_grant_title?(user)
    true
  end
end
