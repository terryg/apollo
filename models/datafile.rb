require 'digest/md5'
require './models/track'

class Datafile
  include DataMapper::Resource

  property :id, Serial, :index => true
  property :torrent_id, Integer
  property :torrent_name, Text
  property :temp_path, Text
  property :file_name, Text
  property :s3_fkey, String
  property :md5sum, String
  property :matched, Boolean, :default => false
  property :created_at, DateTime, :default => DateTime.now
  property :deleted, Boolean, :default => false

  has 1, :track

  after :create do
    self.md5sum = Datafile.calc_md5sum(self.temp_path)
    save_self(false)
  end

  def self.calc_md5sum(fname)
    Digest::MD5.hexdigest(File.read(fname))
  end

  def self.s3_bucket
    ENV['S3_BUCKET_NAME']
  end

  def self.store_on_s3(track)
    puts "INFO: STORE ON S3"
    value = (0...16).map{(97+rand(26)).chr}.join
    ext = File.extname(track.path)
    fkey = value  + ext

    puts "S3 STORE begin"

    AWS::S3::S3Object.store(fkey, open(track), self.s3_bucket)

    puts "S3 STORE IS DONE"

    return fkey
  end

  def delete_s3
    puts "INFO: Datafile #{self.id} exists with S3 #{self.s3_fkey}? #{AWS::S3::S3Object.exists?(self.s3_fkey, self.class.s3_bucket)}"
    AWS::S3::S3Object.delete(self.s3_fkey, self.class.s3_bucket)
    puts "INFO: delete_s3 done."
  end

  def match(request)
    if match_ratio(request) > ENV['MATCH_PERCENTAGE'].to_f
      track = Track.create(:request_id => request.id,
                           :datafile_id => self.id)
    
      if !track.save
        track.errors.each do |err|
          puts "ERR: Track save #{err}"
        end
      end

      return track
    end
  end

  def match_ratio(request)
    cleaned = request.text.gsub('-', ' ')
    tokens = cleaned.split(' ')
    
    search_string = "#{self.torrent_name} #{self.file_name}"

    puts "SEARCH ON #{search_string}"
    
    count = 0
    
    tokens.each do |token|
      if /#{token}/.match(search_string)
        count = count + 1
      end
    end

    puts "COUNT/SIZE #{count}/#{tokens.size}"

    return (count.to_f/tokens.size.to_f)
  end

  def url
    "https://s3.amazonaws.com/#{self.class.s3_bucket}/#{self.s3_fkey}"
  end

end
