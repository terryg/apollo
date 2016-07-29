require './models/request'

class SearchQueue
  include DataMapper::Resource

  property :id, Serial, :index => true
  property :created_at, DateTime, :default => DateTime.now
  property :deleted, Boolean, :default => false
  property :count, Integer, :default => 0

  belongs_to :request

end
