require 'net/http'
require 'twitter'
require 'transmission_api'

class Apollo

  def run
    puts "START at #{Time.now.strftime('%Y%m%d %T')}"
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['CONSUMER_KEY']
      config.consumer_secret     = ENV['CONSUMER_SECRET']
      config.access_token        = ENV['ACCESS_TOKEN']
      config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
    end

    client.mentions_timeline(result_type: "recent").take(3).each do |tweet|
      puts "CHECK [#{tweet.text}]"

      if not /#request/.match(tweet.text).nil?
        t = tweet.text.gsub('#request', '').gsub('@1ApolloBot', '').strip
        puts "REQUEST [#{t}]"

        Net::HTTP.start('kat.cr', :use_ssl => true) do |http|
          resp = http.get("/usearch/#{t.gsub(' ', '+')}/")
          puts "RESPONSE"
          l = /^.* title="Torrent magnet link" .*$/.match(resp.body)
          p "MATCHED [#{l.to_s}]"
  

          m = /magnet:\?[^"]*/.match(l.to_s)
          p "MATCHED [#{m.to_s}]"


          transmission_api = TransmissionApi::Client.new(
            :username => "transmission", #ENV['TRANSMISSION_USER'],
            :password => "changeme", #ENV['TRANSMISSION_PASSWORD'],
            :url      => "http://127.0.0.1:9091/transmission/rpc" #ENV['TRANSMISSION_URL']
          )

          torrents = transmission_api.all

          torrents.each do |t|
            p "TORRENT #{t}"
          end

          t = transmission_api.create(m.to_s)
          p "TORRENT #{t}"
        end
      end
    end
    puts "END"
  end

end
