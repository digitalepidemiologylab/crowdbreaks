require 'rails_helper'

RSpec.feature "UserSignIn", type: :feature, js: true do
  # confirmed test user
  let!(:user) { FactoryBot.create(:user, :confirmed, username: 'testuser', email: 'user@example.com', password: '123456') }

  before(:each) do
    visit(root_path)
  end

  context 'user sign in sequence' do
    xit 'can successfully sign in user' do
      visit(new_user_session_path)
      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: '123456'
      click_button "Sign in"
      expect(page).to have_content('Hello testuser')
    end
  end
end
