collection @notifications

attributes :id, :read, :message, :icon, :link, :method
node(:created_at) { |n| time_ago_in_words(n.created_at) }
