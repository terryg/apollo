require 'logger'
require 'sass'
require 'sinatra'
require 'twitter'
require './models/track'

class App < Sinatra::Base
  
  set :logging, Logger::DEBUG

  get '/' do  
    if (@size = Track.all(:deleted => false).length) > 0
      tracks = {}
      (1..5).each do       
        id = ((rand * 100).to_i % @size) + 1
        puts "DEBUG: Get Track #{id}"
        tracks[id] = Track.get(id)
      end
      
      @@client ||= Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV['CONSUMER_KEY']
        config.consumer_secret     = ENV['CONSUMER_SECRET']
        config.access_token        = ENV['ACCESS_TOKEN']
        config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
      end 

      tracks.each do |t|
        puts "XXXXX #{t} XXXXX"
        @tweet = @@client.status(t[1].request.tweet_id)
      end

      @datafiles = tracks.collect{|t| t[1].datafile}
      
      puts "DEBUG: #{@tweet}"
      puts "DEBUG: #{@tweet.id}"
    end

    haml :index
  end

end
