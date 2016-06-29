class App < Sinatra::Base

  get '/' do
    @datafiles = Datafile.all(:fields => [:id, :file_name, :s3_fkey],
                              :matched.not => false,
                              :order => [:created_at.desc])
    haml :index
  end

end
