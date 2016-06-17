require './models/request'
require './models/torrent'
require './models/transmission_queue'

class MagnetLink
  include DataMapper::Resource

  property :id, Serial, :index => true
  property :link, Text
  property :created_at, DateTime, :default => DateTime.now
  property :deleted, Boolean, :default => false

  validates_presence_of :link, :created_at

  belongs_to :request
  has 1, :transmission_queue
  has 1, :torrent
end
