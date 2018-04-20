require_relative 'dependencies'

class UserUpdater
  attr_reader :user
  attr_reader :user_profile
  attr_reader :user_option
  attr_reader :attributes

  delegate :change_post_owner, to: :guardian
  delegate :log_user_name_change, to: :StaffActionLogger

  def update(attributes = {})
    @attributes = attributes
    old_user_name = user.name.present? ? user.name : ""

    set_user_profile_geo_data
    set_user_profile_web_data
    set_user_profile_background_data
    set_user_profile_bio_raw if should_update_user_profile_bio_raw?

    set_user_bio( update_title: can_grant_title?(user) )
    user.custom_fields = user.custom_fields.merge( attributes.fetch( :custom_fields, {} ) )

    set_user_option_theme_key if should_update_user_option_theme_key?
    OPTION_ATTR.each do |attribute|
      set_user_option_single_attribute( attribute )
    end
    # automatically disable digests when mailing_list_mode is enabled
    user_option.email_digests = false if user_option.mailing_list_mode

    return false unless User.transaction { save_user_and_related_entities }
    log_user_name_change( user.id, old_user_name, attributes.fetch(:name) { '' } )

    return true
  end

  private

  attr_reader :user, :guardian

  def initialize(actor, user, guardian = Guardian.new(actor))
    @user = user
    @guardian = guardian
    @user_profile = user.user_profile
    @user_option = user.user_option
    @actor = actor
  end

  def set_user_profile_geo_data
    user_profile.location = attributes.fetch(:location) { user_profile.location }
  end

  def set_user_profile_web_data
    user_profile.website = format_url(attributes.fetch(:website) { user_profile.website })
    user_profile.dismissed_banner_key = attributes[:dismissed_banner_key] || user_profile.dismissed_banner_key
  end

  def set_user_profile_background_data
    user_profile.profile_background = attributes.fetch(:profile_background) { user_profile.profile_background }
    user_profile.card_background = attributes.fetch(:card_background) { user_profile.card_background }
  end

  def set_user_profile_bio_raw
    user_profile.bio_raw = attributes.fetch(:bio_raw) { user_profile.bio_raw }
  end

  def should_update_user_profile_bio_raw?
    SiteSetting.enable_sso && !SiteSetting.sso_overrides_bio
  end

  def set_user_bio(update_title:)
    user.name = attributes.fetch(:name) { user.name }
    user.title = attributes.fetch(:title) { user.title } if update_title
    user.locale = attributes.fetch(:locale) { user.locale }
    user.date_of_birth = attributes.fetch(:date_of_birth) { user.date_of_birth }
  end

  def set_user_option_theme_key
    # special handling for theme_key cause we need to bump a sequence number
    user_option.theme_key_seq += 1
  end

  def should_update_user_option_theme_key?
    attributes.key?(:theme_key) && user_option.theme_key != attributes[:theme_key]
  end

  def set_user_option_single_attribute(attribute)
    return false unless attributes.key?(attribute)
    if [true, false].include?(user_option.send(attribute))
      val = attributes[attribute].to_s == 'true'
      user_option.send("#{attribute}=", val)
    else
      user_option.send("#{attribute}=", attributes[attribute])
    end
  end

  def save_user_and_related_entities
    user.user_option.save && user.user_profile.save && user.save
  end

  def format_url(website)
    return nil if website.blank?
    website =~ /^http/ ? website : "http://#{website}"
  end
end
