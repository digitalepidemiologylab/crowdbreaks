require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { create(:user, :confirmed) }
  let!(:admin_user) { create(:user, :confirmed, :admin) }

  it { is_expected.to respond_to :username }
  it { is_expected.to validate_presence_of :password }

  it "by default user is not admin" do
    expect(user).to_not be_admin
  end
end
