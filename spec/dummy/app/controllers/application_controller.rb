class ApplicationController < ActionController::API
  def good
    logger_context = logger.formatter.respond_to?(:default_tags) ?
                       logger.formatter.default_tags :
                       { error: "Invalid log class: #{logger.class.name}" }

    logger.info 'GOOD!'

    render json: { good: true, logger_context: }
  end

  def bad
    render status: :bad_request, json: { bad: true }
  end

  def slow
    sleep 3
  end

  def logger
    RrxLogging::Current.logger
  end
end
