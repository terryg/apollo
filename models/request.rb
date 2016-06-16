class Request
  include DataMapper::Resource

  property :id, Serial, :index => true
  property :tweet_id, Integer
  property :created_at, DateTime
  property :deleted, Boolean, :default => false

  validates_presence_of :tweet_id, :created_at

end
