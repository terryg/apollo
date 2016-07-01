require 'sinatra'
require 'logger'
require 'sass'

class App < Sinatra::Base
  
  set :logging, Logger::DEBUG

  get '/' do
    
    all = Datafile.all(:matched.not => false)
    size = all.length

    puts "DEBUG: #{size} files."

    id = (rand * 100).to_i % size

    puts "DEBUG: Datafile #{id}"

    @datafile = Datafile.get(id)

    haml :index
  end

end
