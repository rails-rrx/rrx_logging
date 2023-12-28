# frozen_string_literal: true

require 'rrx_logging'

describe RrxLogging do
  it 'should setup Rails logging' do
    expect(Rails.logger).to be_instance_of RrxLogging::Logger
  end

  describe 'requests', type: :request do
    let(:logs) { [] }

    before do
      allow_any_instance_of(RrxLogging::Logger).to receive(:write).and_wrap_original do |m, msg|
        logs << msg
        m.call(msg)
      end
    end

    it 'should add request context' do
      get '/good'
      expect(json_response[:logger_context]).to match(
                                                  controller: 'application',
                                                  action:     'good',
                                                  request_id: match(/[a-z0-9-]+/i),
                                                  method:     'GET',
                                                  path:       '/good'
                                                )
      expect(logs).to include match(/INFO application: GOOD!/)
    end
  end
end
