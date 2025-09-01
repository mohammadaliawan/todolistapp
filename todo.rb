require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "erubis"
require "securerandom"

def error_msg_for_listname(name)
  if !name.size.between?(1,100)
    "The name should between 1 and 100 Characters."
  elsif session[:lists].any? {|list| list[:name] == name}
    "List name must be unique!"
  else
    return nil
  end
end

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

get "/new-list" do
  erb :new_list, layout: :layout
end

get "/lists/:idx" do
  @list_index = params["idx"].to_i

  @todo_list = session[:lists][@list_index]

  erb :list, layout: :layout
end

post "/lists" do
  list_name = params[:list_name].strip

  if error = error_msg_for_listname(list_name)
    session[:failure] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The new list was created successfully!"
    redirect "/lists"
  end
end

get "/lists/:idx/edit" do
  @list_index = params[:idx]
  erb :edit_list, layout: :layout
end

get "/" do
  redirect "/lists"
end
