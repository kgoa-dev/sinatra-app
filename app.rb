# frozen_string_literal: true

# require 'debug'
# binding.break

require 'sinatra'
require 'sinatra/reloader'
require 'json'

enable :method_override

# JSONファイルからデータ入手
memos = []
File.open('data.json') do |f|
  memos = JSON.parse(f.read)
end

# TOP画面（メモ一覧表示）
get '/' do
  @title = 'メモアプリ'
  @subtitle = 'Welcome to the world of sinatra and ruby.'
  @memos = memos ? memos['memo'] : []
  erb :index
end

# メモの追加
get '/add' do
  @title = 'メモアプリ'
  erb :add_memo
end

post '/new' do
  new_id = memos ? memos['memo'].size : 0
  new_memo = { 'id' => new_id, 'title' => @params['title'], 'content' => @params['content'] }
  if memos
    memos['memo'] << new_memo
  else
    memos = { 'memo' => [new_memo] }
  end

  File.open('data.json', 'w') do |f|
    JSON.dump(memos, f)
  end

  redirect '/'
  erb :index
end

# メモの詳細画面
post '/detail/*' do |id|
  redirect "/memo/#{id}"
  erb :show_detail
end

get '/memo/*' do |id|
  detail = []
  memos['memo'].each do |f|
    detail = f if f['id'] == id.to_i
  end

  @detail = detail
  erb :show_detail
end
