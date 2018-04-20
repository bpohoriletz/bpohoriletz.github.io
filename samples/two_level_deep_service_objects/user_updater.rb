require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/time/calculations'
require 'active_model'

require_relative 'dependencies'

class UserUpdater
  delegate :change_post_owner, to: :guardian

  def update(attributes = {})
    save_options = false
    saved = nil
    old_user_name = user.name.present? ? user.name : ""

    user_profile = user.user_profile
    user_profile.location = attributes.fetch(:location) { user_profile.location }
    user_profile.dismissed_banner_key = attributes[:dismissed_banner_key] if attributes[:dismissed_banner_key].present?
    user_profile.website = format_url(attributes.fetch(:website) { user_profile.website })
    user_profile.profile_background = attributes.fetch(:profile_background) { user_profile.profile_background }
    user_profile.card_background = attributes.fetch(:card_background) { user_profile.card_background }
    if SiteSetting.enable_sso && !SiteSetting.sso_overrides_bio
      user_profile.bio_raw = attributes.fetch(:bio_raw) { user_profile.bio_raw }
    end

    user.name = attributes.fetch(:name) { user.name }
    user.locale = attributes.fetch(:locale) { user.locale }
    user.date_of_birth = attributes.fetch(:date_of_birth) { user.date_of_birth }
    if can_grant_title?(user)
      user.title = attributes.fetch(:title) { user.title }
    end

    # special handling for theme_key cause we need to bump a sequence number
    if attributes.key?(:theme_key) && user.user_option.theme_key != attributes[:theme_key]
      user.user_option.theme_key_seq += 1
    end

    OPTION_ATTR.each do |attribute|
      if attributes.key?(attribute)
        save_options = true

        if [true, false].include?(user.user_option.send(attribute))
          val = attributes[attribute].to_s == 'true'
          user.user_option.send("#{attribute}=", val)
        else
          user.user_option.send("#{attribute}=", attributes[attribute])
        end
      end
    end

    # automatically disable digests when mailing_list_mode is enabled
    user.user_option.email_digests = false if user.user_option.mailing_list_mode

    fields = attributes[:custom_fields]
    if fields.present?
      user.custom_fields = user.custom_fields.merge(fields)
    end

    User.transaction do
      if user.user_option.save && user_profile.save && user.save
        StaffActionLogger.new(@actor).log_name_change(
          user.id,
          old_user_name,
          attributes.fetch(:name) { '' }
        )

        saved = true
      end
    end

    saved
  end

  private

  attr_reader :user, :guardian

  def initialize(actor, user, guardian = Guardian.new(actor))
    @user = user
    @guardian = guardian
    @actor = actor
  end

  def format_url(website)
    return nil if website.blank?
    website =~ /^http/ ? website : "http://#{website}"
  end
end
