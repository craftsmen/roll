module Roll
  class AppBuilder < Rails::AppBuilder
    include Roll::Actions

    def replace_gemfile
      remove_file 'Gemfile'
      template 'Gemfile.erb', 'Gemfile'
    end

    def set_ruby_to_version_being_used
      template 'ruby-version.erb', '.ruby-version'
    end

    def setup_heroku_specific_gems
      inject_into_file(
        'Gemfile',
        %{\n\s\sgem 'rails_stdout_logging'},
        after: /group :staging, :production do/
      )
    end

    def use_postgres_config_template
      template 'postgresql_database.yml.erb', 'config/database.yml',
        force: true
    end

    def use_mongoid_config_template
      remove_file 'config/database.yml'
      template 'mongoid.yml.erb', 'config/mongoid.yml'
    end

    def create_database
      bundle_command 'exec rake db:create db:migrate'
    end

    def readme
      template 'README.md.erb', 'README.md'
    end

    def raise_on_delivery_errors
      replace_in_file 'config/environments/development.rb',
        'raise_delivery_errors = false', 'raise_delivery_errors = true'
    end

    def raise_on_unpermitted_parameters
      action_on_unpermitted_parameters = <<-RUBY

    # Raise an ActionController::UnpermittedParameters exception when
    # a parameter is not explicitly permitted but is passed anyway.
    config.action_controller.action_on_unpermitted_parameters = :raise

      RUBY

      inject_into_class 'config/application.rb',
                        'Application',
                        action_on_unpermitted_parameters
    end

    def provide_setup_script
      copy_file 'bin_setup', 'bin/setup', force: true
      run 'chmod a+x bin/setup'
    end

    def provide_dev_prime_task
      copy_file 'dev_prime_task.rb', 'lib/tasks/dev.rake'
    end

    def configure_generators
      config = <<-RUBY
    config.generators do |generate|
      generate.helper false
      generate.request_specs false
      generate.routing_specs false
      generate.stylesheets false
      generate.test_framework :rspec
      generate.view_specs false
    end

      RUBY

      inject_into_class 'config/application.rb', 'Application', config
    end

    def configure_mailers_preview_path
      config = <<-RUBY


  # Specific mailers path
  config.action_mailer.preview_path = Rails.root.join('spec/mailers/previews')
      RUBY

      empty_directory_with_keep_file 'spec/mailers/previews'
      inject_into_file 'config/environments/development.rb', config, before: "\nend"
    end

    def configure_hound
      copy_file 'hound.yml', '.hound.yml'
      copy_file 'style_guides/ruby.yml', 'config/style_guides/ruby.yml'
      copy_file 'style_guides/javascript.json', 'config/style_guides/javascript.json'
      copy_file 'style_guides/javascript_ignore', 'config/style_guides/.javascript_ignore'
    end

    def set_up_factory_girl_for_rspec
      copy_file 'factory_girl_rspec.rb', 'spec/support/factory_girl.rb'
    end

    def generate_rspec
      generate 'rspec:install'
    end

    def configure_rspec
      remove_file 'spec/spec_helper.rb'
      remove_file 'spec/rails_helper.rb'
      template 'rails_helper.rb', 'spec/rails_helper.rb'
      copy_file 'spec_helper.rb', 'spec/spec_helper.rb'
    end

    def configure_background_jobs_for_rspec
      copy_file 'background_jobs_rspec.rb', 'spec/support/background_jobs.rb'
      run 'rails g delayed_job:active_record' if using_active_record?
      run 'rails g delayed_job'               if using_mongoid?
    end

    def enable_database_cleaner
      template 'database_cleaner_rspec.rb', 'spec/support/database_cleaner.rb'
    end

    def configure_spec_support_features
      empty_directory_with_keep_file 'spec/features'
      empty_directory_with_keep_file 'spec/support/features'
    end

    def configure_i18n_in_specs
      copy_file 'i18n.rb', 'spec/support/i18n.rb'
    end

    def configure_action_mailer_in_specs
      copy_file 'action_mailer.rb', 'spec/support/action_mailer.rb'
    end

    def configure_travis
      template 'travis.yml.erb', '.travis.yml'
    end

    def configure_smtp
      copy_file 'smtp.rb', 'config/smtp.rb'

      prepend_file 'config/environments/production.rb',
        "require Rails.root.join('config/smtp')\n"

      config = <<-RUBY

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = SMTP_SETTINGS
      RUBY

      inject_into_file 'config/environments/production.rb', config,
        after: 'config.action_mailer.raise_delivery_errors = false'
    end

    def enable_rack_deflater
      config = <<-RUBY

  # Enable deflate / gzip compression of controller-generated responses
  config.middleware.use Rack::Deflater
      RUBY

      inject_into_file(
        'config/environments/production.rb',
        config,
        after: "config.serve_static_assets = ENV['RAILS_SERVE_STATIC_FILES'].present?"
      )
    end

    def configure_newrelic
      template 'newrelic.yml.erb', 'config/newrelic.yml'
    end

    def setup_staging_environment
      staging_file = 'config/environments/staging.rb'
      copy_file 'staging.rb', staging_file

      config = <<-RUBY

Rails.application.configure do
  # ...
end
      RUBY

      append_file staging_file, config
    end

    def setup_secret_token
      template 'secrets.yml', 'config/secrets.yml', force: true
    end

    def create_partials_directory
      empty_directory 'app/views/application'
    end

    def create_shared_flashes
      copy_file '_flashes.html.erb', 'app/views/application/_flashes.html.erb'
    end

    def create_shared_javascripts
      copy_file '_javascript.html.erb', 'app/views/application/_javascript.html.erb'
    end

    def create_application_layout
      template 'roll_layout.html.erb.erb',
        'app/views/layouts/application.html.erb',
        force: true
    end

    def configure_action_mailer
      action_mailer_host 'development', "#{app_name}.local"
      action_mailer_host 'test', 'www.example.com'
      action_mailer_host 'staging', "staging.#{app_name}.com"
      action_mailer_host 'production', "#{app_name}.com"
    end

    def fix_i18n_deprecation_warning
      config = <<-RUBY
    config.i18n.enforce_available_locales = true

      RUBY
      inject_into_class 'config/application.rb', 'Application', config
    end

    def configure_time_formats
      remove_file 'config/locales/en.yml'
      copy_file 'config_locales_en.yml', 'config/locales/en.yml'
    end

    def configure_rack_timeout
      copy_file 'rack_timeout.rb', 'config/initializers/rack_timeout.rb'
    end

    def configure_simple_form
      bundle_command 'exec rails generate simple_form:install'
    end

    def disable_xml_params
      copy_file 'disable_xml_params.rb', 'config/initializers/disable_xml_params.rb'
    end

    def setup_default_rake_task
      append_file 'Rakefile' do
        <<-EOS
task(:default).clear
task default: [:spec]
if defined? RSpec
  task(:spec).clear
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.verbose = false
  end
end
        EOS
      end
    end

    def configure_unicorn
      copy_file 'unicorn.rb', 'config/unicorn.rb'
    end

    def setup_foreman
      copy_file 'sample.env', '.sample.env'
      copy_file 'Procfile', 'Procfile'
    end

    def setup_bourbon
      remove_file 'app/assets/stylesheets/application.css'
      copy_file 'application.scss', 'app/assets/stylesheets/application.scss'
    end

    def install_bitters
      run 'bitters install --path app/assets/stylesheets'
    end

    def copy_miscellaneous_files
      copy_file 'errors.rb', 'config/initializers/errors.rb'
      copy_file 'json_encoding.rb', 'config/initializers/json_encoding.rb'
    end

    def customize_error_pages
      meta_tags =<<-EOS
  <meta charset='utf-8' />
  <meta name='ROBOTS' content='NOODP' />
      EOS

      %w(500 404 422).each do |page|
        inject_into_file "public/#{page}.html", meta_tags, after: "<head>\n"
        replace_in_file "public/#{page}.html", /<!--.+-->\n/, ''
      end
    end

    def remove_routes_comment_lines
      replace_in_file 'config/routes.rb',
        /Rails\.application\.routes\.draw do.*end/m,
        "Rails.application.routes.draw do\nend"
    end

    def gitignore_files
      remove_file '.gitignore'
      copy_file 'roll_gitignore', '.gitignore'
      [
        'app/views/pages',
        'spec/lib',
        'spec/controllers',
        'spec/helpers',
        'spec/support/matchers',
        'spec/support/mixins',
        'spec/support/shared_examples'
      ].each do |dir|
        run "mkdir #{dir}"
        run "touch #{dir}/.keep"
      end
    end

    def init_git
      run 'git init'
    end

    def create_heroku_apps
      %w(staging production).each do |environment|
        run "heroku create #{app_name}-#{environment} --remote #{environment} --region eu"
        run "heroku config:set RACK_ENV=#{environment} RAILS_ENV=#{environment} --remote #{environment}"
        run "heroku config:set RAILS_SERVE_STATIC_FILES=true --remote #{environment}"
      end
    end

    def set_heroku_remotes
      remotes = <<-RUBY

# Set up staging and production git remotes
git remote add staging git@heroku.com:#{app_name}-staging.git
git remote add production git@heroku.com:#{app_name}-production.git
      RUBY

      append_file 'bin/setup', remotes
    end

    def set_heroku_rails_secrets
      %w(staging production).each do |environment|
        run "heroku config:set SECRET_KEY_BASE=#{generate_secret} --remote #{environment}"
      end
    end

    def provide_deploy_script
      copy_file 'bin_deploy', 'bin/deploy'
      run 'chmod a+x bin/deploy'

      instructions = <<-MARKDOWN
## Deploying

If you have previously run the `./bin/setup` script,
you can deploy to staging and production with:

    $ ./bin/deploy staging
    $ ./bin/deploy production
      MARKDOWN

      append_file 'README.md', instructions
    end

    private

    def factories_spec_rake_task
      IO.read find_in_source_paths('factories_spec_rake_task.rb')
    end

    def generate_secret
      SecureRandom.hex(64)
    end
  end
end
