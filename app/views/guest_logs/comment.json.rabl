object @log

attributes :id, :body
node(:created_at_time) { |n| n.created_at.strftime('%I:%M %p') }
node(:user_name) {|n| n.user.name }
node(:user_avatar) {|n| n.user.avatar.thumb.url }
node(:is_liked) { |n| current_user.liked? n }
node(:has_likes) { |n| n.get_likes.present? }
node(:likes_count) { |n| n.get_likes.count }
node(:likes) do |n|
  n.get_likes.map { |v| {user_name: v.voter.name, user_avatar: v.voter.avatar.thumb.url} }
end
