require_relative 'dependencies'

class UserUpdater
  delegate :change_post_owner, to: :guardian
  delegate :log_name_change, to: :StaffActionLogger

  def update(attributes = {})
    old_user_name = user.name.present? ? user.name : ""

    update_user_profile( user.user_profile, attributes )
    update_user( user, attributes )
    update_user_option( user.user_option, attributes )
    save_user_data(user, old_user_name, attributes)
  end

  private

  attr_reader :user, :guardian

  def initialize(actor, user, guardian = Guardian.new(actor))
    @user = user
    @guardian = guardian
    @actor = actor
  end

  def update_user_profile( user_profile, attributes )
    update_geo_data( user_profile, attributes )
    update_web_data( user_profile, attributes )
    update_background_data( user_profile, attributes )
    update_bio_raw( user_profile, attributes )
  end

  def update_user(user, attributes)
    update_user_bio(user, attributes, update_title: can_grant_title?(user) )
    user.custom_fields = user.custom_fields.merge( attributes.fetch( :custom_fields, {} ) )
  end

  def update_user_option(user_option, attributes)
    update_theme_key(user_option, attributes)
    OPTION_ATTR.each { |attribute| update_single_attribute(user_option, attributes, attribute) }
    # automatically disable digests when mailing_list_mode is enabled
    user_option.email_digests = false if user_option.mailing_list_mode
  end

  def save_user_data(user, old_user_name, attributes)
    return false unless User.transaction { user.user_option.save && user.user_profile.save && user.save }
    log_name_change( user.id, old_user_name, attributes.fetch(:name) { '' } )

    return true
  end

  def update_geo_data(user_profile, attributes)
    user_profile.location = attributes.fetch(:location) { user_profile.location }
  end

  def update_web_data(user_profile, attributes)
    user_profile.website = format_url(attributes.fetch(:website) { user_profile.website })
    user_profile.dismissed_banner_key = attributes[:dismissed_banner_key] || user_profile.dismissed_banner_key
  end

  def update_background_data(user_profile, attributes)
    user_profile.profile_background = attributes.fetch(:profile_background) { user_profile.profile_background }
    user_profile.card_background = attributes.fetch(:card_background) { user_profile.card_background }
  end

  def update_bio_raw(user_profile, attributes)
    return false unless SiteSetting.enable_sso && !SiteSetting.sso_overrides_bio
    user_profile.bio_raw = attributes.fetch(:bio_raw) { user_profile.bio_raw }
  end

  def update_user_bio(user, attributes, update_title:)
    user.name = attributes.fetch(:name) { user.name }
    user.title = attributes.fetch(:title) { user.title } if update_title
    user.locale = attributes.fetch(:locale) { user.locale }
    user.date_of_birth = attributes.fetch(:date_of_birth) { user.date_of_birth }
  end

  def update_theme_key(user_option, attributes)
    # special handling for theme_key cause we need to bump a sequence number
    return false unless attributes.key?(:theme_key) && user_option.theme_key != attributes[:theme_key]
    user_option.theme_key_seq += 1
  end

  def update_single_attribute(user_option, attributes, attribute)
    if attributes.key?(attribute)
      if [true, false].include?(user_option.send(attribute))
        val = attributes[attribute].to_s == 'true'
        user_option.send("#{attribute}=", val)
      else
        user_option.send("#{attribute}=", attributes[attribute])
      end
    end
  end

  def format_url(website)
    return nil if website.blank?
    website =~ /^http/ ? website : "http://#{website}"
  end
end
