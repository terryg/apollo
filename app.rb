require 'logger'
require 'sass'
require 'sinatra'
require 'twitter'
require './models/track'

class App < Sinatra::Base
  
  set :logging, Logger::DEBUG

  get '/' do  
    if (@size = Track.all(:deleted => false, :limit => 100).length) > 0
      count = 0
      track = nil
      while track.nil?       
        id = ((rand * 100).to_i % @size) + 1
        puts "DEBUG: Get Track #{id}"
        track = Track.get(id)
        puts "DEBUG: #{track.created_at}"
        if track.created_at > (Date.today - 15)
          @@client ||= Twitter::REST::Client.new do |config|
            config.consumer_key        = ENV['CONSUMER_KEY']
            config.consumer_secret     = ENV['CONSUMER_SECRET']
            config.access_token        = ENV['ACCESS_TOKEN']
            config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
          end 
    
          puts "XXXXX #{track} XXXXX"

          @tweet = @@client.status(track.request.tweet_id)
      
          @datafile = track.datafile
      
          puts "DEBUG: #{@tweet}"
          puts "DEBUG: #{@tweet.id}"
        else
          track = nil
        end
        puts "DEBUG: COUNT #{count}"
        count = count + 1
      end
    end
    
    haml :index
  end

end
