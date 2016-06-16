require 'net/http'
require 'twitter'
require 'transmission_api'
require './models/request'

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
      puts "REQUEST IS #{tweet.id} -- #{tweet.text}"

      if Request.first(:tweet_id => tweet.id).nil?
        puts "ID #{tweet.id} NOT FOUND"
        puts "CHECK [#{tweet.text}]"
        r = Request.create(:tweet_id => tweet.id, :created_at => Time.now)
        if !r.save
          r.errors.each do |err|
            puts "ERR: #{err}"
          end
        else
          puts "INFO: saved request #{r.id}"
        end
        
        if not /#request/.match(tweet.text).nil?
          t = tweet.text.gsub('#request', '').gsub('@1ApolloBot', '').strip
          puts "REQUEST [#{t}]"

          Net::HTTP.start('kat.cr', :use_ssl => true) do |http|
            resp = http.get("/usearch/#{t.gsub(' ', '+')}/")

            l = /^.* title="Torrent magnet link" .*$/.match(resp.body)

            m = /magnet:\?[^"]*/.match(l.to_s)
            p "MATCHED [#{m.to_s}]"

            transmission_api = TransmissionApi::Client.new(
              :username => ENV['TRANSMISSION_USERNAME'],
              :password => ENV['TRANSMISSION_PASSWORD'],
              :url      => ENV['TRANSMISSION_URL']
            )

            t = transmission_api.create(m.to_s)
            p "TORRENT #{t}"
          end
        end
      else
        p "REQUEST ALREADY TAKEN"
      end
    end
    puts "END"
  end

end
