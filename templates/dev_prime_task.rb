if Rails.env.development?
  require 'factory_girl'

  namespace :dev do
    desc 'Creates sample data development environment'
    task prime: 'db:setup' do
      include FactoryGirl::Syntax::Methods

      # create(:user, email: "user@example.com", password: "password")
    end
  end
end
