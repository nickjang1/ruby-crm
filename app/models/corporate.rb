class Corporate < ActiveRecord::Base
  
  has_many :users
  has_many :connections
  has_many :join_invitations, as: :targetable
  has_many :properties, ->{ where('corporate_connections.state = ?', :active).order(:name) }, through: :connections

  def self.create_corporate(options = {})
    return false if options[:name].blank? || options[:username].blank? || options[:useremail].blank?

    corporate = nil
    user = User.find_by(email: options[:useremail])
    if user
      user = nil
    else
      corporate = Corporate.create! name: options[:name]
      user = User.new name: options[:username], email: options[:useremail], corporate_id: corporate.id
      user.save!
    end
    corporate
  end

end
