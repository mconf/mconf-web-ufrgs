# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require "spec_helper"

describe BigbluebuttonRails do

  describe "#invitation_url" do
    let(:target) { BigbluebuttonRails.configuration }
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }
    before {
      Site.current.update_attributes(domain: "localhost:4000")
    }

    it { target.should respond_to(:get_invitation_url) }
    it { target.get_invitation_url.should be_a(Proc) }
    it { target.get_invitation_url.call(room).should eql("http://#{Site.current.domain}/webconf/#{room.param}") }

    context "works with HTTPS" do
      before {
        Site.current.update_attributes(ssl: true)
      }

      it { target.get_invitation_url.call(room).should eql("https://#{Site.current.domain}/webconf/#{room.param}") }
    end
  end

  describe "#get_create_options" do
    let(:target) { BigbluebuttonRails.configuration }
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }
    before {
      Site.current.update_attributes(domain: "localhost:4000")
    }

    it { target.should respond_to(:get_create_options) }
    it { target.get_create_options.should be_a(Proc) }

    context "for a user room" do
      before {
        room.update_attributes(owner: FactoryGirl.create(:user))
      }

      it {
        target.get_create_options.call(room).should have_key("meta_mconfweb-url")
        target.get_create_options.call(room).should have_key("meta_mconfweb-room-type")
        target.get_create_options.call(room)["meta_mconfweb-url"].should eql("http://#{Site.current.domain}/")
        target.get_create_options.call(room)["meta_mconfweb-room-type"].should eql("User")
      }
    end

    context "for a space room" do
      before {
        room.update_attributes(owner: FactoryGirl.create(:space))
      }

      it {
        expected = {
          "mconfweb-url" => "http://#{Site.current.domain}/",
          "mconfweb-room-type" => "Space"
        }
        target.get_dynamic_metadata.call(room).should eql(expected)
      }
    end

    context "works with HTTPS" do
      before {
        Site.current.update_attributes(ssl: true)
        room.update_attributes(owner: FactoryGirl.create(:space))
      }

      it {
        expected = {
          "mconfweb-url" => "https://#{Site.current.domain}/",
          "mconfweb-room-type" => "Space"
        }
        target.get_dynamic_metadata.call(room).should eql(expected)
      }
    end
  end

  describe "#get_join_options" do
    let(:target) { BigbluebuttonRails.configuration }
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }

    it { target.should respond_to(:get_join_options) }
    it { target.get_create_options.should be_a(Proc) }

    context 'sets locale userdata' do
      context 'when user has logged in' do
        ["en", "pt-br"].each do |user_locale|
          context "and its locale is set to #{user_locale.upcase}" do
            let(:user) { FactoryGirl.create(:user, locale: user_locale) }
            let(:join_options) { target.get_join_options.call(room, user, {}) }
            let(:locale) { Mconf::LocaleControllerModule.get_user_locale(user) }
            # FIXME: remove after team Live update bbb to version 2.4
            it { expect(join_options[:"userdata-mconf_custom_language"]).to eql(locale) }
            it { expect(join_options[:"userdata-bbb_override_default_locale"]).to eql(locale) }
          end
        end
      end

      context 'when user has not logged in' do
        let(:join_options) { target.get_join_options.call(room, nil, {}) }
        let(:locale) { Mconf::LocaleControllerModule.get_user_locale(nil) }
        # FIXME: remove after team Live update bbb to version 2.4
        it { expect(join_options).to eql(nil) }
        it { expect(join_options).to eql(nil) }
      end
    end
  end

  describe "#select_server" do
    let(:target) { BigbluebuttonRails.configuration }
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }

    it { target.should respond_to(:select_server) }
    it { target.select_server.should be_a(Proc) }

    context "calls room#server_considering_secret" do
      before {
        Site.current.update_attributes(domain: "localhost:4000")
        room.should_receive(:server_considering_secret).with(:create).and_return('expected result')
      }

      it {
        target.select_server.call(room, :create).should eql('expected result')
      }
    end
  end

end
