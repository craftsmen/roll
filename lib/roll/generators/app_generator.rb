require 'rails/generators'
require 'rails/generators/rails/app/app_generator'

module Roll
  class AppGenerator < Rails::Generators::AppGenerator

    class_option :skip_active_record, type: :boolean, aliases: '-O', default: false,
      desc: 'Skip Active Record files'

    class_option :database, type: :string, aliases: '-d', default: 'postgresql',
      desc: "Preconfigure for selected database (options: #{DATABASES.join('/')})"

    class_option :mongoid, type: :boolean, aliases: '-M', default: false,
      desc: 'Use Mongoid ODM'

    class_option :heroku_flags, type: :string, default: '--region eu',
      desc: 'Set extra Heroku flags'

    class_option :skip_heroku, type: :boolean, default: false,
      desc: 'Skip creating staging and production Heroku apps'

    class_option :skip_test_unit, type: :boolean, aliases: '-T', default: true,
      desc: 'Skip Test::Unit files'

    def finish_template
      invoke :roll_customization
      super
    end

    def roll_customization
      invoke :customize_gemfile
      invoke :setup_mongoid
      invoke :setup_database
      invoke :setup_development_environment
      invoke :setup_test_environment
      invoke :setup_production_environment
      invoke :setup_staging_environment
      invoke :setup_secret_token
      invoke :create_roll_views
      invoke :configure_app
      invoke :setup_bourbon
      invoke :install_bitters
      invoke :copy_miscellaneous_files
      invoke :customize_error_pages
      invoke :remove_routes_comment_lines
      invoke :setup_git
      invoke :setup_spring
      invoke :create_heroku_apps
      invoke :outro
    end

    def customize_gemfile
      build :set_ruby_to_version_being_used

      if !options[:skip_heroku]
        build :setup_heroku_specific_gems
      end

      bundle_command 'install'
    end

    def setup_mongoid
      if !options[:skip_active_record] && options[:mongoid]
        raise Thor::Error, 'Active Record should be skipped when using mongoid. For details run: roll --help'
      end
    end

    def setup_database
      say 'Setting up database'

      if 'postgresql' == options[:database]
        build :use_postgres_config_template
      end

      if using_mongoid?
        build :use_mongoid_config_template
      end

      build :create_database
    end

    def setup_development_environment
      say 'Setting up the development environment'
      build :raise_on_delivery_errors
      build :set_test_delivery_method
      build :raise_on_missing_translations
      build :provide_setup_script
      build :provide_dev_prime_task
      build :configure_generators
      build :configure_hound
    end

    def setup_test_environment
      say 'Setting up the test environment'
      build :raise_on_missing_assets_in_test
      build :generate_rspec
      build :set_up_factory_girl_for_rspec
      build :generate_factories_file
      build :configure_rspec
      build :configure_background_jobs_for_rspec
      build :enable_database_cleaner
      build :configure_spec_support_features
      build :configure_i18n_in_specs
      build :configure_action_mailer_in_specs
      build :configure_shoulda_matchers
      build :configure_capybara_webkit
      build :configure_travis
    end

    def setup_production_environment
      say 'Setting up the production environment'
      build :configure_smtp
      build :enable_rack_canonical_host
      build :enable_rack_deflater
      build :configure_newrelic
    end

    def setup_staging_environment
      say 'Setting up the staging environment'
      build :setup_staging_environment
    end

    def setup_secret_token
      say 'Moving secret token out of version control'
      build :setup_secret_token
    end

    def create_roll_views
      say 'Creating roll views'
      build :create_partials_directory
      build :create_shared_flashes
      build :create_shared_javascripts
      build :create_application_layout
    end

    def configure_app
      say 'Configuring app'
      build :configure_active_job
      build :configure_action_mailer
      build :configure_time_formats
      build :configure_rack_timeout
      build :configure_simple_form
      build :disable_xml_params
      build :setup_default_rake_task
      build :configure_puma
      build :setup_forego
      build :raise_on_unpermitted_parameters
    end

    def setup_bourbon
      say 'Setting up Bourbon and Neat stylesheets'
      build :setup_bourbon
    end

    def install_bitters
      say 'Install Bitters'
      build :install_bitters
    end

    def copy_miscellaneous_files
      say 'Copying miscellaneous support files'
      build :copy_miscellaneous_files
    end

    def customize_error_pages
      say 'Customizing the 500/404/422 pages'
      build :customize_error_pages
    end

    def remove_routes_comment_lines
      build :remove_routes_comment_lines
    end

    def setup_git
      say 'Initializing git'
      build :setup_default_directories
      build :init_git
    end

    def setup_spring
      say 'Springifying binstubs'
      build :setup_spring
    end

    def create_heroku_apps
      if !options[:skip_heroku]
        say 'Creating Heroku apps'
        build :create_heroku_apps, options[:heroku_flags]
        build :set_heroku_remotes
        build :set_heroku_rails_secrets
        build :provide_deploy_script
      end
    end

    def outro
      say 'Congratulations!'
    end

    def run_bundle
      # Let's not: We'll bundle manually at the right spot
    end

    protected

    def get_builder_class
      Roll::AppBuilder
    end

    def using_active_record?
      !options[:skip_active_record]
    end

    def using_mongoid?
      options[:mongoid]
    end
  end
end
