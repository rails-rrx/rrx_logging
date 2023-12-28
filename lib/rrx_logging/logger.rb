require 'active_support/logger'
require 'rails/rack/logger'
require_relative './formatter'

module RrxLogging
  class Logger < ActiveSupport::Logger
    def initialize(mode = :json, name: nil, tags: nil, progname: nil)
      super($stdout, progname: name || progname)
      self.formatter = Formatter.new(mode, tags:)
      @silencers     = []
      @filters       = []
    end

    ##
    # This completely overrites the Activesupport::LoggerThreadSafeLevel
    # implementation since the logic we want to change isn't separated
    # out in any convenient way
    def add(severity, message = nil, progname = nil)
      severity ||= UNKNOWN
      progname ||= @progname

      return true if @logdev.nil? || severity < level

      if message.nil?
        if block_given?
          message = yield
        else
          message  = progname
          progname = @progname
        end
      end

      return true if noise?(message)

      write format_message(format_severity(severity), Time.zone.now, progname, message)
    end

    def scoped(name: nil, tags: nil)
      Logger.new formatter.mode,
                 name: name || progname,
                 tags: formatter.default_tags.merge(tags || {})
    end

    # @note Deliberately not named "tagged" as multiple Rails
    # classes assume if the logger has a method with that name
    # then call it with an array of text tags
    def with_tags(**tags)
      formatter.with_tags(**tags) { yield self }
    end

    # Silence logs of debug level or below
    def silence_debug(&block)
      silence(Logger::INFO, &block)
    end

    # Silence logs of info level or below
    def silence_info(&block)
      silence(Logger::WARN, &block)
    end

    # Temporarily ignore log statements below the
    # specified level for the scope of the block
    def silence(level, &block)
      if level > self.level
        log_at(level, &block)
      else
        block.call
      end
    end

    def noise?(message)
      Rails.configuration.log_noise_filters.any? do |filter|
        case filter
        when Regexp
          filter.match?(message.to_s)
        when String
          message.include? filter
        when Proc
          filter.call(message)
        else
          # Ignore
          false
        end
      end
    end

    # def add_silencer(&block)
    #   @silencers << block
    # end
    #
    # def add_filter(filter)
    #   @filters << filter
    # end
    #
    # def silence?(env)
    #   @silencers.any? {|s| s.call(env) }
    # end

    # @param [String] message
    # @param [Exception] exception
    def exception(message, exception)
      backtrace = exception.backtrace
      if backtrace.present?
        cleaned   = Rails.backtrace_cleaner.clean(backtrace)
        backtrace = cleaned unless cleaned.empty?
      else
        backtrace = nil
      end

      error("%s: %s\n%s" % [
        message,
        exception.message,
        backtrace&.join("\n") || 'No backtrace'
      ])
    end

    private

    def write(msg)
      @logdev.write msg
    end
  end
end
