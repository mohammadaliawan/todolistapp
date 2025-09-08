require "sinatra"
require "sinatra/reloader" if development?
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

def todo_name_error_msg(name)
  if !name.size.between?(1,100)
    "The name should between 1 and 100 Characters."
  end
end

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

helpers do

  def is_complete?(list)
    list[:todos].size > 0 && list[:todos].all? {|todo| todo[:complete]}
  end

  def list_class(list)
    "complete" if is_complete?(list)
  end

  def todos_count(list)
    list[:todos].size
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| !todo[:complete]}.size
  end

  def sort_lists(lists, &block)
    incomplete_lists = {}
    complete_lists = {}

    lists.each_with_index do |list, idx|
      if is_complete?(list)
        complete_lists[list] = idx
      else
        incomplete_lists[list] = idx
      end
    end

    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

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
  @list_id = params[:idx].to_i

  @list = session[:lists][@list_id]

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
  @list_index = params[:idx].to_i
  @list = session[:lists][@list_index]
  
  erb :edit_list, layout: :layout
end

post "/lists/:idx" do
  @list_index = params[:idx].to_i
  @new_list_name = params[:list_name].strip
  @list = session[:lists][@list_index]

  if error = error_msg_for_listname(@new_list_name)
    session[:failure] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = @new_list_name
    session[:success] = "The name of the list was changed successfully!"
    redirect "/lists/#{@list_index}"
  end
end

post "/lists/:idx/delete" do
  @list_index = params[:idx].to_i
  @lists = session[:lists]

  @lists.delete_at @list_index
  session[:success] = "The list has been deleted successfully!"
  redirect "/lists"
end

post "/lists/:idx/todos" do
  @list_id = params[:idx].to_i
  @todo_name = params[:todo].strip
  @list = session[:lists][@list_id]

  if error = todo_name_error_msg(@todo_name)
    session[:failure] = error
    erb :list, layout: :layout
  else
    session[:success] = "The todo was added!"
    @list[:todos] << { name: @todo_name, complete: false }
    redirect "/lists/#{@list_id}"
  end
end

post "/lists/:idx/todos/:todo_id/delete" do
  @todo_id = params[:todo_id].to_i
  @list_id = params[:idx].to_i
  @list = session[:lists][@list_id]
  @list[:todos].delete_at @todo_id

  session[:success] = "The todo was deleted successfully!"
  redirect "/lists/#{@list_id}"
end

post "/lists/:idx/todos/:todo_id" do
  @todo_id = params[:todo_id].to_i
  @list_id = params[:idx].to_i
  @list = session[:lists][@list_id]
  is_complete = params[:completed] == "true"


  @list[:todos][@todo_id][:complete] = is_complete
  session[:success] = "The todo was updated"
  redirect "/lists/#{@list_id}"
end

post "/lists/:idx/complete_all" do
  @list_id = params[:idx].to_i
  @list = session[:lists][@list_id]

  @list[:todos].each do |todo|
    todo[:complete] = true
  end

  session[:success] = "All todos were completed!"
  redirect "/lists/#{@list_id}"
end

get "/" do
  redirect "/lists"
end
