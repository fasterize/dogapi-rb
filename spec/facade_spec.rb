require 'spec_helper'

describe "Facade", :vcr => true do

  before(:all) do
    @api_key = ENV["DATADOG_API_KEY"]
    @app_key = ENV["DATADOG_APP_KEY"]
    @job_number = ENV['TRAVIS_JOB_NUMBER'] || '1'
    @dog_r = Dogapi::Client.new(@api_key)
    @dog = Dogapi::Client.new(@api_key, @app_key)
  end

  context "Client" do

    it "emit_point passes data" do
      metric_svc = double
      @dog.instance_variable_set("@metric_svc", metric_svc)
      metric_svc.should_receive(:submit) do |metric, points, scope, options|
        expect(metric).to eq "metric.name"
        expect(points[0][1]).to eq 0
        expect(scope.host).to eq "myhost"
      end
      @dog.emit_point("metric.name", 0, :host => "myhost")
    end

    it "emit_point uses localhost default" do
      metric_svc = double
      @dog.instance_variable_set("@metric_svc", metric_svc)
      metric_svc.should_receive(:submit) do |metric, points, scope, options|
        expect(scope.host).to eq Dogapi.find_localhost
      end
      @dog.emit_point("metric.name", 0)
    end

    it "emit_point can pass nil host" do
      metric_svc = double
      @dog.instance_variable_set("@metric_svc", metric_svc)
      metric_svc.should_receive(:submit) do |metric, points, scope, options|
        expect(scope.host).to eq nil
      end
      @dog.emit_point("metric.name", 0, :host => nil)
    end

  end

  context "Events" do

    it "emits events and retrieves them" do
      now = Time.now()

      # Tag the events with the build number, because Travis parallel testing
      # can cause problems with the event stream
      tags = ["test-run:#{@job_number}"]

      now_ts = now
      now_title = 'dogapi-rb end test title ' + now_ts.to_i.to_s
      now_message = 'test message'


      event = Dogapi::Event.new(now_message, :msg_title => now_title,
        :date_happened => now_ts, :tags => tags)

      code, resp = @dog_r.emit_event(event)
      now_event_id = resp["event"]["id"]

      code, resp = @dog.get_event(now_event_id)
      expect(resp['event']).not_to eq(nil)
      expect(resp['event']['text']).to eq(now_message)
    end

    it "emits events with specified priority" do
      event = Dogapi::Event.new('test message', :msg_title => 'title', :date_happened => Time.now(), :priority => "low")
      code, resp = @dog_r.emit_event(event)
      low_event_id = resp["event"]["id"]

      code, resp = @dog.get_event(low_event_id)
      expect(resp['event']).not_to eq(nil)
      low_event = resp['event']
      expect(low_event['priority']).to eq("low")
    end

    it "emits aggregate events" do
      now = Time.now()
      code, resp = @dog_r.emit_event(Dogapi::Event.new("Testing Aggregation (first)", :aggregation_key => now.to_i))
      first = resp["event"]["id"]
      code, resp = @dog_r.emit_event(Dogapi::Event.new("Testing Aggregation (second)", :aggregation_key => now.to_i))
      second = resp["event"]["id"]

      code, resp = @dog.get_event(first)
      expect(resp["event"]).not_to eq(nil)
      code, resp = @dog.get_event(second)
      expect(resp["event"]).not_to eq(nil)
    end

  end

end
