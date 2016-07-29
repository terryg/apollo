require './models/search_queue'
require './models/magnet_link'
require './models/track'

class Request
  include DataMapper::Resource

  property :id, Serial, :index => true
  property :tweet_id, Integer
  property :tweet_text, String, :length => 140
  property :matched, Boolean, :default => false
  property :created_at, DateTime, :default => DateTime.now
  property :deleted, Boolean, :default => false
  property :screen_name, String, :length => 20

  validates_presence_of :tweet_id, :tweet_text, :created_at

  has 1, :search_queue
  has n, :magnet_links
  has 1, :track

  def text
    self.tweet_text.gsub('#request', '').gsub('@1ApolloBot', '').strip
  end

end
