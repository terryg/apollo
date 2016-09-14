require './models/datafile'
require './models/request'
require './models/search_queue'
require 'net/http'
require 'open-uri'
require 'to_regexp'
require 'transmission_api'
require 'twitter'

class Jobs

  Dir.mkdir(File.join(File.dirname(__FILE__), "log")) unless Dir.exists?(File.join(File.dirname(__FILE__), "log"))
  @@log_file = File.open(File.join(File.dirname(__FILE__), "log/#{ENV['RACK_ENV']}.log"), 'a')
  @@log_file.sync = true
  def log(msg)
    line = "[#{Time.now.strftime('%H:%M:%S')}] #{msg}\n"
    @@log_file.write(line)
    puts line
  end

  def poll_and_record_requests
    log "START at #{Time.now.strftime('%Y%m%d %T')}"
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['CONSUMER_KEY']
      config.consumer_secret     = ENV['CONSUMER_SECRET']
      config.access_token        = ENV['ACCESS_TOKEN']
      config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
    end

    client.mentions_timeline(result_type: "recent").take(100).each do |tweet|
      if Request.first(:tweet_id => tweet.id).nil? and
          tweet.user.screen_name != "1ApolloBot"
        log "INFO: Tweet #{tweet.id} -- #{tweet.text}"
        r = Request.create(:tweet_id => tweet.id, 
                           :tweet_text => tweet.text,
                           :screen_name => tweet.user.screen_name)

        if !r.save
          r.errors.each do |err|
            log "ERROR: Request save #{err}"
          end
        else
          log "INFO: Request save #{r.id}"

          track = nil

          Datafile.all(:fields => [:id, :file_name, :torrent_name], 
                       :matched.not => true).each do |datafile|
            track = datafile.match(r) 
          end

          if track.nil?
            r.search_queue = SearchQueue.create
            r.save
          else
            log "DEBUG: #{track.id} #{track.request_id} #{track.datafile_id}"
            track.request.update(:matched => true)
            track.datafile.update(:matched => true)
            
            begin
              client = Twitter::REST::Client.new do |config|
                config.consumer_key        = ENV['CONSUMER_KEY']
                config.consumer_secret     = ENV['CONSUMER_SECRET']
                config.access_token        = ENV['ACCESS_TOKEN']
                config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
              end

              client.retweet(track.request.tweet_id)
            rescue => e
              log "ERROR: Retweet #{e}"
            end
          end
        end
      end
    end
  end
  
  def search_for_magnet_links
    SearchQueue.all(:fields => [:id, :count, :request_id],
                    :deleted.not => true).each do |record|
      if record.count < (ENV['MAX_SEARCHES']).to_i
        r = Request.get(record.request_id)
        
        log "REQUEST [#{r.text}]"

        m = Net::HTTP.start('thepiratebay.cr', :use_ssl => true) do |http|
          resp = http.get("/search/#{URI::encode(r.text)}/")

          l = /^.*alt="Magnet link".*$/.match(resp.body)
          
          /magnet:\?[^"]*/.match(l.to_s)
        end

        log "MAGNET #{m}"

        unless m.nil?
          ml = MagnetLink.create(:request => r, :link => m)
          ml.request = r
          ml.transmission_queue = TransmissionQueue.new
      
          if !ml.save
            ml.errors.each do |err|
              log "ERROR: MagnetLink save #{err}"
            end
          else
            log "INFO: MagnetLink save #{ml.id}"
          end
        else
 
          r = SearchQueue.get(record.id)
          r.update(:count => (record.count + 1))
          log "RECORD COUNT #{r.count}"
        end
        
      else # if !(record.count < MAX_SEARCHES)
        log "RECORD MARKED DELETED #{record.id}"
        s = SearchQueue.get(record.id)
        s.update(:deleted => true)

        begin
          client = Twitter::REST::Client.new do |config|
            config.consumer_key        = ENV['CONSUMER_KEY']
            config.consumer_secret     = ENV['CONSUMER_SECRET']
            config.access_token        = ENV['ACCESS_TOKEN']
            config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
          end

          client.update("Sorry @#{record.request.screen_name}, no matches for [#{record.request.text}]")
        rescue => e
          log "ERROR: Tweet #{e}"
        end

      end
    end # SearchQueue.all
  
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
      log "LINK #{m.id} #{m.link}"
        
      t = transmission_api.create(m.link)
      log "TORRENT #{t}"

      unless t.nil?
        torrent = Torrent.create(:transmission_id => t['id'],
                                 :transmission_hash => t['hashString'],
                                 :name => t['name'])
        torrent.magnet_link = m
        if !torrent.save
          torrent.errors.each do |err|
            log "ERROR: Torrent save #{err}"
          end
        else
          log "INFO: Torrent save #{torrent.id}"
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
      log "INFO: Torrent id #{record.transmission_id} #{t['percentDone'] unless t.nil?}"
      if t && 1 == t['percentDone']
        log "INFO: Torrent #{t['id']} is done."
        length = t['totalSize']
        log "LENGTH [#{length}]"
        curr = 0
        index = 0
        while curr < length do
          if (t['files'][index]['length']).to_i < 100000000
            name = t['files'][index]['name']
            s = URI.encode(name)
            log "DEBUG: http://ec2-54-166-10-103.compute-1.amazonaws.com:7722/#{s}"
            uri = URI.parse("http://ec2-54-166-10-103.compute-1.amazonaws.com:7722/#{s.gsub("[","%5B").gsub("]","%5D")}")
            tempfile = nil
            Net::HTTP.start(uri.host) do |http|
              resp = http.get(uri.path)
              tempfile = Tempfile.new(Time.now.to_i.to_s)
              track = File.open(tempfile.path, "wb") do |f|
                f.write resp.body
              end
              log "INFO: #{track}"
            end
          
            begin
              fkey = Datafile.store_on_s3(tempfile)

              log "DEBUG: id #{t['id']}"
              log "DEBUG: torrent #{t['name']}"
              log "DEBUG: temp path #{tempfile.path}"
              log "DEBUG: filename #{File.basename(name)}"
              log "DEBUG: fkey #{fkey}"
              
              d = Datafile.create(:torrent_id   => t['id'],
                                  :torrent_name => t['name'],
                                  :temp_path    => tempfile.path,
                                  :file_name    => File.basename(name),
                                  :s3_fkey      => fkey)

              log "DEBUG: done Datafile create"

              if !d.save
                d.errors.each do |err|
                  log "ERROR Datafile save #{err}"
                end
              else
                log "ERROR Datafile #{d.id} saved"
              end
            rescue => e
              log "ERROR: #{e}"
            end
          end

          curr = curr + t['files'][index]['length']
          index = index + 1

          log "DEBUG: Next is #{index} #{curr}"
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
      Datafile.all(:fields => [:id, :file_name, :torrent_name], 
                   :matched.not => true).each do |datafile|
        track = datafile.match(request) 
        tracks << track unless track.nil?
      end
    end

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['CONSUMER_KEY']
      config.consumer_secret     = ENV['CONSUMER_SECRET']
      config.access_token        = ENV['ACCESS_TOKEN']
      config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
    end

    tracks.each do |track|
      log "DEBUG: #{track.id} #{track.request_id} #{track.datafile_id}"
      track.request.update(:matched => true)
      track.datafile.update(:matched => true)

      begin
        client.retweet(track.request.tweet_id)
      rescue => e
        log "ERROR: Retweet #{e}"
      end
    end
  end

end    
