namespace :engage do
  desc 'Migrate guest logs and alarms to new engage models'
  task :migrate => :environment do
    Engage::Message.unscoped.destroy_all
    Engage::Entity.unscoped.destroy_all

    Engage::Message.skip_callback(:create, :after, :create_comment_activity)
    ActiveRecord::Base.transaction do
      Comment.unscoped.each do |comment|
        msg = Engage::Message.new
        msg.property_id = comment.commentable_id
        msg.title = comment.title
        msg.body = comment.body
        msg.created_by_id = comment.user_id
        msg.created_at = comment.created_at
        msg.updated_at = comment.updated_at
        msg.parent_id = nil
        msg.save!

        likes = comment.get_likes
        likes.each do |like|
          msg_like = like.dup
          msg_like.votable = msg
          ActiveRecord::Base.record_timestamps = false
          begin
            msg_like.save!
          ensure
            ActiveRecord::Base.record_timestamps = true
          end
        end
      end

      Alarm.all.each do |alarm|
        ea = Engage::Entity.new
        ea.property_id = alarm.id
        ea.created_by_id = alarm.user_id
        ea.body = alarm.body
        ea.entity_type = Engage::Entity::ALARM
        ea.due_date = alarm.alarm_at
        ea.created_at = alarm.created_at
        ea.updated_at = alarm.updated_at
        ea.save!
      end
    end
    Engage::Message.set_callback(:create, :after, :create_comment_activity)
  end

  desc 'Migrate guest logs and alarms from staging server'
  task :migrate_staging => :environment do
    # Load staging symmetric keys
    SymmetricEncryption.load!("#{Rails.root}/config/staging-symmetric-encryption.yml", 'production')

    Engage::Message.unscoped.destroy_all
    Engage::Entity.unscoped.destroy_all

    Engage::Message.skip_callback(:create, :after, :create_comment_activity)
    ActiveRecord::Base.transaction do
      Comment.unscoped.each do |comment|
        msg = Engage::Message.new
        msg.property_id = comment.commentable_id
        msg.title = comment.title
        msg.body = comment.body
        msg.created_by_id = comment.user_id
        msg.created_at = comment.created_at
        msg.updated_at = comment.updated_at
        msg.parent_id = nil
        msg.save!

        likes = comment.get_likes
        likes.each do |like|
          msg_like = like.dup
          msg_like.votable = msg
          ActiveRecord::Base.record_timestamps = false
          begin
            msg_like.save!
          ensure
            ActiveRecord::Base.record_timestamps = true
          end
        end
      end

      Alarm.all.each do |alarm|
        ea = Engage::Entity.new
        ea.property_id = alarm.id
        ea.created_by_id = alarm.user_id
        ea.body = alarm.body
        ea.entity_type = Engage::Entity::ALARM
        ea.due_date = alarm.alarm_at
        ea.created_at = alarm.created_at
        ea.updated_at = alarm.updated_at
        ea.save!
      end
    end
    Engage::Message.set_callback(:create, :after, :create_comment_activity)

    # convert staging encryption to dev server encryption
    messages = Engage::Message.unscoped.pluck :id, :body
    SymmetricEncryption.load!("#{Rails.root}/config/symmetric-encryption.yml", 'qa')
    messages.each do |msg|
      message = Engage::Message.unscoped.find msg[0]
      message.body = msg[1]
      message.save
    end
  end
end
