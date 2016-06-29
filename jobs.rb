require './models/datafile'
require './models/request'
require './models/search_queue'
require 'net/http'
require 'open-uri'
require 'to_regexp'
require 'transmission_api'
require 'twitter'

class Jobs

  def poll_and_record_requests
    puts "START at #{Time.now.strftime('%Y%m%d %T')}"
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['CONSUMER_KEY']
      config.consumer_secret     = ENV['CONSUMER_SECRET']
      config.access_token        = ENV['ACCESS_TOKEN']
      config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
    end

    client.mentions_timeline(result_type: "recent").take(100).each do |tweet|
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

      puts "REQUEST [#{r.text}]"

      m = Net::HTTP.start('kat.cr', :use_ssl => true) do |http|
        resp = http.get("/usearch/#{URI::encode(r.text)}/")
        
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
      puts "INFO: Torrent id #{record.transmission_id} #{t['percentDone'] unless t.nil?}"
      if t && 1 == t['percentDone']
        puts "INFO: Torrent #{t['id']} is done."
        length = t['totalSize']
        puts "LENGTH [#{length}]"
        curr = 0
        index = 0
        while curr < length do
          track = File.join(ENV['TRANSMISSION_COMPLETED_DIR'],
                            t['files'][index]['name'])
          
          puts "INFO: #{track}"

          begin
            fkey = Datafile.store_on_s3(open(track, "rb"))

            name = File.basename(t['files'][index]['name'])

            puts "DEBUG: id #{t['id']}"
            puts "DEBUG: torrent #{t['name']}"
            puts "DEBUG: filename #{name}"
            puts "DEBUG: fkey #{fkey}"

            d = Datafile.create(:torrent_id   => t['id'],
                                :torrent_name => t['name'],
                                :file_name    => name,
                                :s3_fkey      => fkey)

            puts "DEBUG: done Datafile create"

            if !d.save
              d.errors.each do |err|
                puts "ERROR Datafile save #{err}"
              end
            else
              puts "ERROR Datafile #{d.id} saved"
            end
          rescue => e
            puts "ERROR: #{e}"
          end

          curr = curr + t['files'][index]['length']
          index = index + 1

          puts "DEBUG: Next is #{index} #{curr}"
        end

        transmission_api.destroy(record.transmission_id)

        torrent = Torrent.get(record.id)
        torrent.update(:deleted => true)
      end
    end
  end

  def match_requests
    tracks = Array.new

    Request.all(:fields => [:id, :tweet_text], :matched.not => true).each do |request|
      s = request.text.split(' ')[0]
      r = "/#{s}/"

      Datafile.all(:fields => [:id, :file_name, :torrent_name], 
                   :matched.not => true).each do |datafile|
        
        if r.to_regexp.match(datafile.torrent_name)
          s1 = request.text.split(' ')[1]
          r1 = "/#{s1}/"

          if r1.to_regexp.match(datafile.torrent_name)
            s2 = request.text.split(' ')[2]
            r2 = "/#{s2}/"
  
            if r2.to_regexp.match(datafile.file_name)
              if /(flac|mp3)/.match(datafile.file_name)
                puts "DEBUG: #{request.id} #{request.text}"
                puts "DEBUG: #{datafile.id}"
                puts "??? #{datafile.file_name}"

                track = Track.create(:request_id => request.id,
                                     :datafile_id => datafile.id)
                
                if !track.save
                  track.errors.each do |err|
                    puts "ERR: Track save #{err}"
                  end
                end

                tracks << track

                break
              end
            end
          end
        end
      end
    end

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['CONSUMER_KEY']
      config.consumer_secret     = ENV['CONSUMER_SECRET']
      config.access_token        = ENV['ACCESS_TOKEN']
      config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
    end

    tracks.each do |track|
      puts "DEBUG: #{track.id} #{track.request_id} #{track.datafile_id}"
      track.request.update(:matched => true)
      track.datafile.update(:matched => true)

      client.retweet(track.request.tweet_id)
    end
  end

end    
