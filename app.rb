# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'dotenv'
require 'cgi/escape'

require 'debug'

# DBとの接続
def connection_db
  Dotenv.load
  db = ENV['db']
  host = ENV['host']
  user = ENV['user']
  pass = ENV['pass']
  port = ENV['port']

  PG::Connection.new(host: host, port: port, dbname: db, user: user, password: pass)
end

def read_db
  memos = connection_db.exec('SELECT * FROM kgoa.todo')
  memos.map { |m| m }
end

def escaping_memos(memos)
  memos.map do |m|
    esc_title = CGI.escapeHTML(m['title'])
    esc_content = CGI.escapeHTML(m['content'])
    { 'id' => m['id'], 'title' => esc_title, 'content' => esc_content }
  end
end

def esc_id(id)
  id
end

# TOP画面（メモ一覧表示）
get '/' do
  results = read_db.map do |memo|
    { 'id' => memo['id'].to_i, 'title' => memo['title'], 'content' => memo['content'] }
  end
  @memos = escaping_memos(results) || []
  erb :index
end

# メモの詳細画面
get '/memos/*' do |id|
  memo = read_db.detect { |m| m['id'].to_i == id.to_i }
  halt erb :not_found if memo.nil?
  @memo = escaping_memos([memo])[0]
  @title = 'Show'
  erb :show_detail
end

# メモの追加
get '/add' do
  @title = 'Add'
  erb :add_memo
end

post '/memos' do
  memos = read_db
  new_id = memos[0].nil? ? 0 : memos.size
  title = @params['title']
  content = @params['content']
  connection_db.exec("INSERT INTO kgoa.todo values (#{new_id}, '#{title}', '#{content}')")

  redirect '/'
end

# メモの編集
get '/edit/*' do |id|
  # debugger
  memo = connection_db.exec('SELECT * FROM kgoa.todo WHERE id = $1', [id])
  halt erb :not_found if memo.nil?

  @memo = escaping_memos([memo][0])[0]
  @title = 'Edit'
  erb :edit_memo
end

patch '/memos/*' do |id|
  title = @params['title']
  content = @params['content']

  connection_db.exec('UPDATE kgoa.todo SET title = $1, content = $2 where id = $3', [title, content, id])
  redirect '/'
end

# メモの削除
delete '/memos/*' do |id|
  connection_db.exec('DELETE FROM kgoa.todo WHERE id = $1', [id])

  read_db.each_with_index do |memo, i|
    connection_db.exec("UPDATE kgoa.todo SET id='#{i}' where id='#{memo['id']}' ")
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
