# frozen_string_literal: true

require_relative 'rrx_logging/version'
require_relative 'rrx_logging/railtie'

module RrxLogging
  def self.current
    RrxLogging::Current.logger
  end
end
