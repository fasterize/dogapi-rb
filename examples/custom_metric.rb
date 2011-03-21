require 'dogapi'

# TODO: remove explicit devices after fixing N/A issues

# Create a simple client
# The host is optional here, it's a shortcut to tie event and metrics to a given host
#
# You typically want to do:
#   Dogapi::Client.new(your_actual_api_key_as_a_string, ...)
# We are using ENV to let you experiment via an environment variable.
dog = Dogapi::Client.new(ENV['DATADOG_KEY'], 'test-api.datadoghq.com')

# Emit points one by one, timestamp is omitted and is the time this call is made.
dog.emit_point('test.api.test_metric', 4.0, :device => 'eth0')

sleep 1

dog.emit_point('test.api.test_metric', 5.0, :host => 'test-api-2.datadoghq.com', :device => 'eth0')

# Emit a list of points in one go as a list of (timestamp, value)
# here we pretend to send a point a minute for the past hour
now = Time.now
points = (0...60).map do |i|
  i = 60 - i
  t = now - (i*60)
  [t, Math.cos(i) + 1.0]
end

# And emit the data in one call
dog.emit_points('test.api.test_metric', points, :device => 'eth0')

# Send an event too, automatically tied to the same host
dog.emit_event(Dogapi::Event.new('Testing done, FTW'), :device => 'eth0')

# To record an event with duration
dog.start_event(Dogapi::Event.new('My event with a duration'), :device => 'eth0') do
  # do your work here...
  sleep 1
end
# stop_event will be sent automatically