require 'logger'
require 'sass'
require 'sinatra'
require 'twitter'
require './models/track'

class App < Sinatra::Base
  
  set :logging, Logger::DEBUG

  get '/' do  
    if (@size = Track.all.length) > 0
      id = ((rand * 100).to_i % @size) + 1
      puts "DEBUG: Get Track #{id}"
      track = Track.get(id)
      @datafile = track.datafile

      @@client ||= Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV['CONSUMER_KEY']
        config.consumer_secret     = ENV['CONSUMER_SECRET']
        config.access_token        = ENV['ACCESS_TOKEN']
        config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
      end 

      @tweet = @@client.status(track.request.tweet_id)

      puts "DEBUG: #{@tweet}"
      puts "DEBUG: #{@tweet.id}"
    end

    haml :index
  end

end
