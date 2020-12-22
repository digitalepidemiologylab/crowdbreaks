require 'rails_helper'

RSpec.feature "UserSignUp", type: :feature, js: true do
  context 'user sign up sequence' do
    xit 'can successfully sign up user' do
      username = 'some_user'
      visit(new_user_registration_path)
      fill_in 'Username', with: username
      fill_in 'Email', with: "#{username}@example.com"
      fill_in 'Password', with: '123456', match: :prefer_exact
      fill_in 'Password confirmation', with: '123456', match: :prefer_exact
      find('input[name="commit"]').click
      user = User.find_by(email: "#{username}@example.com")
      expect(user).not_to be(nil)
      expect(user.confirmation_token).not_to be(nil)

      # confirm user
      visit("/en/users/confirmation?confirmation_token=#{user.confirmation_token}")

      # Sign in
      visit(new_user_session_path)
      fill_in 'Email', with: "#{username}@example.com"
      fill_in 'Password', with: '123456', match: :prefer_exact
      click_button "Sign in"
      expect(page).to have_content("Hello #{username}")
    end
  end
end
