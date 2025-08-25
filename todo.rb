require "sinatra"
require "sinatra/reloader"
require "erubis"
require "securerandom"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do
  session[:lists] ||= []
end

get "/lists" do
  @lists = session[:lists]

  erb :lists
end

post "/lists" do
  list_name = params[:list_name].strip

  if list_name.size.between?(1,100)
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The new list was created successfully!"
    redirect "/lists"
  else
    session[:failure] = "The name should between 1 and 100 Characters."
    redirect "/lists/new"
  end
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

get "/" do
  redirect "/lists"
end

 
