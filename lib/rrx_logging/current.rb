# frozen_string_literal: true

module RrxLogging
  class Current < ActiveSupport::CurrentAttributes
    # @return [RrxLogging::Logger]
    attribute :logger
  end
end

ActiveSupport::Notifications.subscribe 'start_processing.action_controller' do |event|
  # @type [Hash<Symbol>]
  payload = event.payload
  # @type [RrxLogging::Logger]
  rails_logger = Rails.logger
  name, request = payload.values_at(:controller, :request)
  name = name.sub('Controller', '').downcase

  # @type [Hash<Symbol>]
  tags = payload.slice(:action, :method, :path)
  tags[:request_id] = request.request_id
  tags[:controller] = name

  RrxLogging::Current.logger = rails_logger.scoped(name:, tags:)
  request.set_header 'action_dispatch.logger', RrxLogging::Current.logger
end

ActiveSupport::Notifications.subscribe 'process_action.action_controller' do |payload|
  # TODO
end
