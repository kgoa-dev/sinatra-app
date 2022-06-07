# frozen_string_literal: true

# require 'debug'
# binding.break

require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'dotenv'
require 'securerandom'

enable :method_override

# DBとの接続
results = []
Dotenv.load

db = ENV['db']
host = ENV['host']
user = ENV['user']
pass = ENV['pass']
port = ENV['port']

connection = PG::Connection.new(host: host, port: port, dbname: db, user: user, password: pass)

# TOP画面（メモ一覧表示）
get '/' do
  results = connection.exec("SELECT * FROM kgoa.todo ORDER BY id ASC").each.map do |conn|
    {"id"=> conn['id'].to_i, "title"=> conn["title"], "content"=> conn["content"]}
  end

  @title = 'メモアプリ'
  @sub = results
  @memos = results || []
  erb :index
end

# メモの詳細画面
post '/detail/*' do |id|
  redirect "/memo/#{id}"
  erb :show_detail
end

get '/memo/*' do |id|
  detail = []
  results.each do |f|
    detail = f if f['id'] == id.to_i
  end

  @detail = detail
  erb :show_detail
end

# メモの追加
get '/add' do
  @title = 'メモアプリ'
  erb :add_memo
end

post '/new' do
  new_id = SecureRandom.random_number(500)

  title = @params['title']
  content = @params['content']

  connection.exec("INSERT INTO kgoa.todo values
    (#{new_id}, '#{title}', '#{content}')")

  redirect '/'
  erb :index
end

# メモの編集
post '/edit/*' do |id|
  redirect "/edit/#{id}"
end

get '/edit/*' do |id|
  @id = id
  sel = connection.exec("SELECT * FROM kgoa.todo
    WHERE id='#{id}' ")

  @title = sel[0]['title']
  @content = sel[0]['content']
  erb :edit_memo
end

patch '/change/*' do |id|
  title = @params['title']
  content = @params['content']

  connection.exec("UPDATE kgoa.todo
    SET title='#{title}', content='#{content}' where id='#{id}' ")

  redirect '/'
  erb :index
end

# メモの削除
delete '/delete/*' do |id|
  connection.exec("DELETE FROM kgoa.todo WHERE id='#{id}' ")

  redirect '/'
  erb :index
end
