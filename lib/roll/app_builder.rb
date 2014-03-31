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
  # a parameter is not explcitly permitted but is passed anyway.
  config.action_controller.action_on_unpermitted_parameters = :raise
      RUBY
      inject_into_file(
        "config/environments/development.rb",
        action_on_unpermitted_parameters,
        before: "\nend"
      )
    end

    def provide_setup_script
      copy_file 'bin_setup', 'bin/setup'
      run 'chmod a+x bin/setup'
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

    def set_up_factory_girl_for_rspec
      copy_file 'factory_girl_rspec.rb', 'spec/support/factory_girl.rb'
    end

    def generate_rspec
      generate 'rspec:install'
    end

    def configure_rspec
      remove_file 'spec/spec_helper.rb'
      template 'spec_helper.rb', 'spec/spec_helper.rb'
    end

    def use_spring_binstubs
      run 'bundle exec spring binstub --all'
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

    def configure_travis
      template 'travis.yml.erb', '.travis.yml'
    end

    def configure_smtp
      copy_file 'smtp.rb', 'config/initializers/smtp.rb'

      prepend_file 'config/environments/production.rb',
        "require Rails.root.join('config/initializers/smtp')\n"

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

      inject_into_file 'config/environments/production.rb', config,
        after: "config.serve_static_assets = false\n"
    end

    def setup_staging_environment
      staging_file = 'config/environments/staging.rb'
      copy_file 'staging.rb', staging_file

      config = <<-RUBY

#{app_name.classify}::Application.configure do
  # ...
end
      RUBY

      append_file staging_file, config
    end

    def setup_secret_token
      template 'secret_token.rb',
        'config/initializers/secret_token.rb',
        force: true
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

    def configure_time_zone
      if using_active_record?
        config = <<-RUBY
    config.active_record.default_timezone = :utc

        RUBY
        inject_into_class 'config/application.rb', 'Application', config
      end
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

    def disable_xml_params
      copy_file 'disable_xml_params.rb', 'config/initializers/disable_xml_params.rb'
    end

    def setup_default_rake_task
      append_file 'Rakefile' do
        "task(:default).clear\ntask default: [:spec]\n"
      end
    end

    def configure_unicorn
      copy_file 'unicorn.rb', 'config/unicorn.rb'
    end

    def setup_foreman
      copy_file 'sample.env', '.sample.env'
      copy_file 'Procfile', 'Procfile'
    end

    def setup_zurb_foundation
      copy_file 'foundation_and_overrides.scss', 'app/assets/stylesheets/foundation_and_overrides.scss'
      remove_file 'app/assets/stylesheets/application.css'
      copy_file 'application.css.scss', 'app/assets/stylesheets/application.css.scss'
    end

    def copy_miscellaneous_files
      copy_file 'errors.rb', 'config/initializers/errors.rb'
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
        /Application\.routes\.draw do.*end/m,
        "Application.routes.draw do\nend"
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
      path_addition = override_path_for_tests
      run "#{path_addition} heroku create #{app_name}-staging --remote=staging"
      run "#{path_addition} heroku config:add RACK_ENV=staging RAILS_ENV=staging --remote=staging"
    end

    def set_heroku_remotes
      remotes = <<-RUBY

# Set up staging and production git remotes
git remote add staging git@heroku.com:#{app_name}-staging.git
      RUBY

      append_file 'bin/setup', remotes
    end

    def set_heroku_rails_secrets
      path_addition = override_path_for_tests
      run "#{path_addition} heroku config:add SECRET_KEY_BASE=#{generate_secret} --remote=staging"
    end

    private

    def override_path_for_tests
      if ENV['TESTING']
        support_bin = File.expand_path(File.join('..', '..', '..', 'features', 'support', 'bin'))
        "PATH=#{support_bin}:$PATH"
      end
    end

    def factories_spec_rake_task
      IO.read find_in_source_paths('factories_spec_rake_task.rb')
    end

    def generate_secret
      SecureRandom.hex(64)
    end
  end
end
