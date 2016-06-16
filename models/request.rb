class Asset
  include DataMapper::Resource

  property :id, Serial, :index => true
  property :s3_fkey, String
  property :created_at, DateTime
  property :deleted, Boolean, :default => false
  property :md5sum, String
  property :type, String
  validates_presence_of :s3_fkey, :created_at

  after :create do
    fname = 'tmp/' + self.s3_fkey
    self.md5sum = Asset.calc_md5sum(fname)
    save_self(false)
  end

end
