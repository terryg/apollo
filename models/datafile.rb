require 'digest/md5'
require './models/track'

class Datafile
  include DataMapper::Resource

  property :id, Serial, :index => true
  property :torrent_id, Integer
  property :torrent_name, Text
  property :file_name, Text
  property :s3_fkey, String
  property :md5sum, String
  property :matched, Boolean, :default => false
  property :created_at, DateTime, :default => DateTime.now
  property :deleted, Boolean, :default => false

  has 1, :track

  after :create do
    fname = File.join(ENV['TRANSMISSION_COMPLETED_DIR'], self.file_name)
    self.md5sum = Datafile.calc_md5sum(fname)
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

  def url
    "https://s3.amazonaws.com/#{self.class.s3_bucket}/#{self.s3_fkey}"
  end


end
