require './models/magnet_link'

class Torrent
  include DataMapper::Resource

  property :id, Serial, :index => true
  property :transmission_id, Integer
  property :transmission_hash, String, :length => 40
  property :name, Text
  property :created_at, DateTime, :default => DateTime.now
  property :deleted, Boolean, :default => false

  validates_presence_of :transmission_id, :transmission_hash, :name

  belongs_to :magnet_link
end
