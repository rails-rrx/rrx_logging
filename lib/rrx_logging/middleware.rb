require_relative './logger'
require 'action_dispatch/http/request'

module RrxLogging
  # Replacement for default Rack logger to add pre-defined
  # named tags instead of the default tag array
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      logger  = env.fetch('action_dispatch.logger') { Rails.logger }
      if logger.is_a?(Logger)
        tags = { request_id: request.request_id }
        logger.with_tags(**tags) do
          if noise?(env)
            logger.silence_info { @app.call(env) }
          else
            @app.call(env)
          end
        end
      else
        @app.call(env)
      end
    end

    def noise?(env)
      Rails.configuration.request_noise_filters.any? do |filter|
        case filter
        when Regexp
          filter.match?(env['PATH_INFO'])
        when String
          env['PATH_INFO'].include? filter
        when Proc
          filter.call(env)
        else
          # Ignore
          false
        end
      end
    end
  end
end
