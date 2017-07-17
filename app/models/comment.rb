class Comment < ActiveRecord::Base
  acts_as_nested_set :scope => [:commentable_id, :commentable_type]
  acts_as_votable
  include PublicActivity::Common

  validates :body, :presence => true
  validates :user, :presence => true

  # NOTE: install the acts_as_votable plugin if you
  # want user to vote on the quality of comments.
  #acts_as_votable

  after_create :create_comment_activity

  belongs_to :commentable, :polymorphic => true
  belongs_to :user

  attr_encrypted :body

  scope :created_on, -> (date) { where(created_at: date.beginning_of_day..date.end_of_day).order(created_at: :desc) }

  # Helper class method that allows you to build a comment
  # by passing a commentable object, a user_id, and comment text
  # example in readme
  def self.build_from(obj, user_id, comment)
    new \
      :commentable => obj,
      :body        => comment,
      :user_id     => user_id
  end

  #helper method to check if a comment has children
  def has_children?
    self.children.any?
  end

  # Helper class method to lookup all comments assigned
  # to all commentable types for a given user.
  scope :find_comments_by_user, lambda { |user|
    where(:user_id => user.id).order('created_at DESC')
  }

  # Helper class method to look up all comments for
  # commentable class name and commentable id.
  scope :find_comments_for_commentable, lambda { |commentable_str, commentable_id|
    where(:commentable_type => commentable_str.to_s, :commentable_id => commentable_id).order('created_at DESC')
  }

  # Helper class method to look up a commentable object
  # given the commentable class name and id
  def self.find_commentable(commentable_str, commentable_id)
    commentable_str.constantize.find(commentable_id)
  end

  def create_comment_activity
    create_activity key: "comment.created", recipient: Property.current, owner: user
  end

  def as_json(options={})
    {
        id: id,
        body: body,
        created_at_time: created_at.strftime('%I:%M %p'),
        user_name: user.name,
        user_avatar: user.avatar.thumb.url,
        is_liked: options[:current_user].liked?(self),
        has_likes: get_likes.present?,
        likes_count: get_likes.count,
        likes: get_likes.map { |v| {user_name: v.voter.name, user_avatar: v.voter.avatar.thumb.url} }
    }
  end
end
