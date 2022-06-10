# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'pg'
require 'cgi/escape'
require 'debug'

enable :method_override

# JSONファイルからデータ入手する関数
def read_data
  File.open('data.json') do |data|
    JSON.parse(data.read)
  end
end

# TOP画面（メモ一覧表示）
get '/' do
  memos = read_data
  @title = 'Top'
  @memos = memos || []
  erb :index
end

# メモの詳細画面
get '/memos/*' do |id|
  #binding.break
  detail = []
  read_data.each do |memo|
    detail = memo if memo['id'].to_i == id.to_i
  end

  @title = 'Show'
  @memo = detail

  if detail != []
    erb :show_detail
  else
    erb :not_found
  end
end

# メモの追加
get '/add' do
  @title = 'Add'
  erb :add_memo
end

post '/memos' do
  memos = read_data
  new_id = memos ? memos.size : 0
  title = CGI.escapeHTML(@params['title'])
  content = CGI.escapeHTML(@params['content'])
  new_memo = { 'id' => new_id, 'title' => title, 'content' => content }

  if memos
    memos << new_memo
  else
    memos = [new_memo]
  end

  File.open('data.json', 'w') do |f|
    JSON.dump(memos, f)
  end

  redirect '/'
end

# メモの編集
get '/edit/*' do |id|
  select = []
  read_data.each do |memo|
    select << memo if memo['id'] == id.to_i
  end

  @title = 'Edit'
  @memo = select[0]
  erb :edit_memo
end

patch '/memos/*' do |id|
  memos = read_data
  memos.each do |memo|
    if memo['id'] == id.to_i
      memo['title'] = CGI.escapeHTML(@params['title'])
      memo['content'] = CGI.escapeHTML(@params['content'])
    end
  end

  File.open('data.json', 'w') do |f|
    JSON.dump(memos, f)
  end

  redirect '/'
end

# メモの削除
delete '/memos/*' do |id|
  keeps = []
  memos = read_data
  i = 0
  memos.each do |memo|
    if memo['id'] != id.to_i
      keeps << { 'id' => i, 'title' => memo['title'], 'content' => memo['content'] }
      i += 1
    end
  end

  File.open('data.json', 'w') do |f|
    JSON.dump(keeps, f)
  end

  redirect '/'
end

# エラーページ
not_found do
  erb :not_found
end

error do
  erb :not_found
end
