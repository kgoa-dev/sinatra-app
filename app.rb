# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'dotenv'
require 'cgi/escape'
require 'securerandom'

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
  connection_db.exec('SELECT * FROM kgoa.todo')
end

def escaping_memos(memos)
  memos.each.map do |m|
    esc_title = CGI.escapeHTML(m['title'])
    esc_content = CGI.escapeHTML(m['content'])
    { 'id' => m['id'], 'title' => esc_title, 'content' => esc_content }
  end
end

# TOP画面（メモ一覧表示）
get '/' do
  results = read_db.each.map do |memo|
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

def new_id
  create_id = SecureRandom.random_number(500)
rescue StandardError
  retry if read_data.all { |m| m['id'] == create_id }
end

post '/memos' do
  memos = read_db.map{|m| m}
  redirect '/' if memos.size >= 500

  title = @params['title']
  content = @params['content']
  connection_db.exec("INSERT INTO kgoa.todo values (#{new_id}, '#{title}', '#{content}')")

  redirect '/'
end

# メモの編集
get '/edit/*' do |id|
  memo = connection_db.exec("SELECT * FROM kgoa.todo WHERE id='#{id}' ")
  halt erb :not_found if memo.nil?

  @memo = escaping_memos([memo][0])[0]
  @title = 'Edit'
  erb :edit_memo
end

patch '/memos/*' do |id|
  title = @params['title']
  content = @params['content']

  connection_db.exec("UPDATE kgoa.todo SET title='#{title}', content='#{content}' where id='#{id}' ")
  redirect '/'
end

# メモの削除
delete '/memos/*' do |id|
  connection_db.exec("DELETE FROM kgoa.todo WHERE id='#{id}' ")

  redirect '/'
end

# エラーページ
not_found do
  erb :not_found
end

error do
  erb :not_found
end
