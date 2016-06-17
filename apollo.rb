require './models/request'
require './models/search_queue'
require 'net/http'
require 'open-uri'
require 'transmission_api'
require 'twitter'

class Apollo

  def poll_and_record_requests
    puts "START at #{Time.now.strftime('%Y%m%d %T')}"
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['CONSUMER_KEY']
      config.consumer_secret     = ENV['CONSUMER_SECRET']
      config.access_token        = ENV['ACCESS_TOKEN']
      config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
    end

    client.mentions_timeline(result_type: "recent").take(10).each do |tweet|
      if Request.first(:tweet_id => tweet.id).nil?
        puts "INFO: Tweet #{tweet.id} -- #{tweet.text}"
        r = Request.create(:tweet_id => tweet.id, 
                           :tweet_text => tweet.text)
        r.search_queue = SearchQueue.create

        if !r.save
          r.errors.each do |err|
            puts "ERROR: Request save #{err}"
          end
        else
          puts "INFO: Request save #{r.id}"
        end
      end
    end
  end
  
  def search_for_magnet_links
    SearchQueue.all(:fields => [:id, :request_id],
                    :deleted.not => true).each do |record|
      r = Request.get(record.request_id)

      text = r.tweet_text.gsub('#request', '').gsub('@1ApolloBot', '').strip
      
      puts "REQUEST [#{text}]"

      m = Net::HTTP.start('kat.cr', :use_ssl => true) do |http|
        resp = http.get("/usearch/#{URI::encode(text)}/")
        
        l = /^.* title="Torrent magnet link" .*$/.match(resp.body)

        /magnet:\?[^"]*/.match(l.to_s)
      end

      puts "MAGNET #{m}"

      ml = MagnetLink.create(:request => r, :link => m)
      ml.request = r
      ml.transmission_queue = TransmissionQueue.new
      
      if !ml.save
        ml.errors.each do |err|
          puts "ERROR: MagnetLink save #{err}"
        end
      else
        puts "INFO: MagnetLink save #{ml.id}"
      end
    end

    MagnetLink.all(:deleted.not => true).each do |record|
      request = Request.get(record.request_id)
      search = request.search_queue
      search.update(:deleted => true)
    end
  end

  def add_torrents
    transmission_api = TransmissionApi::Client.new(
      :username => ENV['TRANSMISSION_USERNAME'],
      :password => ENV['TRANSMISSION_PASSWORD'],
      :url      => ENV['TRANSMISSION_URL']
    )

    TransmissionQueue.all(:fields => [:id, :magnet_link_id],
                          :deleted.not => true).each do |record|
      m = MagnetLink.get(record.magnet_link_id)
      puts "LINK #{m.id} #{m.link}"
        
      t = transmission_api.create(m.link)
      puts "TORRENT #{t}"

      unless t.nil?
        torrent = Torrent.create(:transmission_id => t['id'],
                                 :transmission_hash => t['hashString'],
                                 :name => t['name'])
        torrent.magnet_link = m
        if !torrent.save
          torrent.errors.each do |err|
            puts "ERROR: Torrent save #{err}"
          end
        else
          puts "INFO: Torrent save #{torrent.id}"
        end
      end
    end

    Torrent.all(:deleted.not => true).each do |record|
      ml = MagnetLink.get(record.magnet_link_id)
      tq = ml.transmission_queue
      tq.update(:deleted => true)
    end
  end

  def poll_transmission_daemon
    transmission_api = TransmissionApi::Client.new(
      :username => ENV['TRANSMISSION_USERNAME'],
      :password => ENV['TRANSMISSION_PASSWORD'],
      :url      => ENV['TRANSMISSION_URL']
    )

    Torrent.all(:deleted.not => true).each do |record|
      t = transmission_api.find(record.transmission_id)
      if 1 == t['percentDone']
        puts "INFO: Torrent #{t['id']} is done."
      end
    end
  end

end    
