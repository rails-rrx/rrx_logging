require_relative './logger'
require_relative './middleware'
require_relative './current'
require 'rails/railtie'
require 'rrx_config'

module RrxLogging
  class Railtie < Rails::Railtie
    GEM_FILTERS = %w[active action rack rspec railtie].freeze

    # List of regular expressions that indicate noisy
    # logs that should be ignored
    config.log_noise_filters = [
      /select 1\s*$/,
      /schema_migrations|sqlite_version|ar_internal_metadata/
    ]

    # List of matchers for noisy requests. Matched requests will
    # only log warnings and above.
    config.request_noise_filters = [
      'healthcheck'
    ]

    initializer(
      'rrx.logging',
      after: :initialize_logger,
      before: %w[action_controller.set_configs active_record.logger active_job.logger]
    ) do |app|
      init_rails app.config,
                 # Verbose when local or deployed to development environment
                 RrxConfig.env.development? ? :debug : :info,
                 # JSON when deployed, text when local
                 mode: Rails.env.production? ? :json : :text
    end

    protected

    def init_rails(config, default_level = :info, mode: :json)
      Rails.logger     = RrxLogging::Logger.new(mode)
      config.log_level = ENV.fetch('LOG_LEVEL') { default_level }
      config.middleware.insert Rails::Rack::Logger, RrxLogging::Middleware
      config.colorize_logging = !Rails.env.production?

      init_backtrace_cleaner
    end

    def init_backtrace_cleaner
      # By default Rails filters exception backtraces to only include source
      # lines from the app itself. Makes it hard to debug when the source is
      # in one of our gems. This replaces the default silencers
      Rails.backtrace_cleaner.remove_filters!
      Rails.backtrace_cleaner.remove_silencers!

      add_app_filter
      add_gem_filter
      add_ruby_filter
    end

    # @see rails/backtrace_cleaner.rb
    def add_app_filter
      root = "#{Rails.root}/" # rubocop:disable Rails/FilePath
      Rails.backtrace_cleaner.add_filter do |line|
        line.start_with?(root) ? line.from(root.size) : line
      end
    end

    # @see active_support/backtrace_cleaner.rb
    def add_gem_filter
      gems_paths = (Gem.path | [Gem.default_dir]).map { |p| Regexp.escape(p) }
      return if gems_paths.empty?

      gems_regexp = %r{\A(#{gems_paths.join('|')})/(bundler/)?gems/([^/]+)-([\w.]+)/(.*)}
      gems_result = 'gems/\3-\4/\5'
      Rails.backtrace_cleaner.add_filter { |line| line.sub(gems_regexp, gems_result) }

      gems_filter = %r{\Agems/#{GEM_FILTERS.join('|')}-\w+\s/}
      Rails.backtrace_cleaner.add_silencer { |line| gems_filter.match?(line) }
    end

    # @see active_support/backtrace_cleaner.rb
    def add_ruby_filter
      Rails.backtrace_cleaner.add_silencer { |line| line.start_with?(RbConfig::CONFIG['rubylibdir']) }
    end
  end
end

