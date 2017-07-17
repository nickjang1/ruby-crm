object @guest_log

node(:comments) do |n|
  n[:comments].map { |c| partial('guest_logs/comment', object: c) }
end
node(:alarms) do |n|
  n[:alarms].map { |a| partial('guest_logs/alarm', object: a) }
end
