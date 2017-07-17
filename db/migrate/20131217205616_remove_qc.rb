require 'queue_classic'
QC::Conn.connection = ActiveRecord::Base.connection.raw_connection 
class RemoveQc < ActiveRecord::Migration
  def self.up
    QC::Setup.drop
  end

  def self.down
    QC::Setup.create
  end
end
