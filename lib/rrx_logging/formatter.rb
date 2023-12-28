module RrxLogging
  class Formatter
    MAX_MESSAGE_LENGTH = 2000

    attr_reader :mode, :default_tags

    def initialize(mode = :json, tags: nil)
      @mode         = mode
      @default_tags = tags || {}
      super()
    end

    # @param [String] severity
    # @param [Time] timestamp
    # @param [String] progname
    # @param [String] msg
    def call(severity, timestamp, progname, msg)
      msg = msg.to_s.strip

      if @mode == :json
        data        = {
          time:  timestamp,
          level: severity,
          log:   msg
        }
        data[:name] = progname if progname
        data[:log]  = msg.truncate(MAX_MESSAGE_LENGTH) if msg.length > MAX_MESSAGE_LENGTH
        data.merge!(current_tags)
        "#{data.to_json}\n"
      else
        tags = current_tags.map { |k, v| "[#{k}=#{v}]" }
        "%s %s %s %s%s%s\n" % [
          timestamp.strftime('%Y-%m-%d'),
          timestamp.strftime('%H:%M:%S.%L'),
          severity,
          progname ? "#{progname}: " : '',
          msg,
          tags.empty? ? '' : ' %s' % tags.join('')
        ]
      end
    end

    def with_tags(**tags)
      old_tags          = current_tags
      self.current_tags = old_tags.merge(tags)
      yield self
    ensure
      self.current_tags = old_tags
    end

    def clear_tags!
      current_tags.clear
    end

    # @return [Hash]
    def current_tags
      Thread.current[thread_key] ||= @default_tags
    end

    # @param [Hash] val
    def current_tags=(val)
      Thread.current[thread_key] = val
    end

    # @return [String]
    def thread_key
      # We use our object ID here to avoid conflicting with other instances
      @thread_key ||= "activesupport_tagged_logging_tags:#{object_id}"
    end
  end
end
