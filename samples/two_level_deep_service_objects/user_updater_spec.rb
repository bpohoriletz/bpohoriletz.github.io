require 'simplecov'
SimpleCov.start

require_relative 'user_updater'

describe UserUpdater do
  let( :acting_user ) { User.new( name: 'Acting User', user_profile: UserProfile.new ) }

  describe '#update' do
    it 'saves user' do
      user = User.new( name: 'Billy Bob', user_profile: UserProfile.new, user_option: spy( email_always: true ) )

      updater = UserUpdater.new( acting_user, user )
      updater.update( name: 'Jim Tom' )

      expect( user.reload.name ).to eq 'Jim Tom'
    end

    it 'updates various fields' do
      user = User.new( name: 'Billy Bob', user_profile: UserProfile.new, user_option: spy( email_always: true ) )
      updater = UserUpdater.new(acting_user, user)
      date_of_birth = Time.current

      val = updater.update(bio_raw: 'my new bio',
                           email_always: 'true',
                           mailing_list_mode: true,
                           digest_after_minutes: "45",
                           new_topic_duration_minutes: 100,
                           auto_track_topics_after_msecs: 101,
                           notification_level_when_replying: 3,
                           email_in_reply_to: false,
                           date_of_birth: date_of_birth,
                           theme_key: 'theme.key',
                           custom_fields: { one: :two },
                           allow_private_messages: false)

      expect(val).to be_truthy

      user.reload

      expect(user.user_profile.bio_raw).to eq 'my new bio'
    end

    it "disables email_digests when enabling mailing_list_mode" do
      user = User.new( name: 'Billy Bob', user_profile: UserProfile.new, user_option: spy( email_always: true ) )
      updater = UserUpdater.new(acting_user, user)

      val = updater.update(mailing_list_mode: true, email_digests: true)
      expect(val).to be_truthy

      user.reload

      expect(user.user_option).to have_received(:mailing_list_mode=).
                                  with( true )
    end

    context 'when sso overrides bio' do
      it 'changes bio' do
        SiteSetting.sso_url = "https://www.example.com/sso"
        SiteSetting.enable_sso = true
        SiteSetting.sso_overrides_bio = true

        user = User.new( name: 'Billy Bob', user_profile: UserProfile.new, user_option: spy( email_always: true ) )
        updater = UserUpdater.new(acting_user, user)

        expect(updater.update(bio_raw: "new bio")).to be_truthy

        user.reload
        expect(user.user_profile.bio_raw).to eq 'new bio'
      end
    end

    context 'when update fails' do
      it 'returns false' do
        user = User.new( name: 'Billy Bob', user_profile: UserProfile.new, user_option: spy( email_always: true ) )
        allow(user).to receive( :save ).
                       and_return( false )
        updater = UserUpdater.new(acting_user, user)

        expect(updater.update).to be_falsey
      end
    end
  end
end
