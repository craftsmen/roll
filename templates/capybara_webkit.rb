Capybara.javascript_driver = :webkit

RSpec.configure do |config|
  config.before(:each, js: true) do
    page.driver.block_unknown_urls
  end
end
