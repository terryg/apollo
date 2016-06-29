require './models/request'
require './models/datafile'

class Track
  include DataMapper::Resource

  property :id, Serial, :index => true
  property :created_at, DateTime, :default => DateTime.now
  property :deleted, Boolean, :default => false

  belongs_to :request
  belongs_to :datafile

end
