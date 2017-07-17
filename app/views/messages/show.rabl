object @message

attributes :id, :body, :user_avatar, :user_name
node(:created_at) { |n| time_ago_in_words(n.created_at) }

node(:attachment_exist) {|n| !n.attachment.url.nil? }
node(:attachment_url) {|n| n.attachment.url || 'javascript:void(0)'}
node(:attachment_type) {|n| n.attachment.file.extension unless n.attachment.file.nil?}
node(:attachment_filename) {|n| n.attachment.file.filename unless n.attachment.file.nil?}