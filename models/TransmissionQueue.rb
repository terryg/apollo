class TransmissionQueue
  include DataMapper::Resource

  property :id, Serial, :index => true
  property :created_at, DateTime, :default => DateTime.now
  property :deleted, Boolean, :default => false

  belongs_to :magnet_link

end
