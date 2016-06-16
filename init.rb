require 'rubygems'

require 'sinatra'
require 'haml'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-redis-adapter'
require 'aws/s3'

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, {:adapter => "redis"})

require './models/request'

DataMapper.finalize
DataMapper.auto_upgrade!

AWS::S3::Base.establish_connection!(
  :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
  :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
)
