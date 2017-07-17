require 'queue_classic'

QC::Conn.connection = ActiveRecord::Base.connection.raw_connection

class AddQueueClassic < ActiveRecord::Migration
  def self.up
    QC::Setup.create
  end

  def self.down
    QC::Setup.drop
  end
end
