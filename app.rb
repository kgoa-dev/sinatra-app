# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'cgi/escape'
require 'securerandom'

# JSONファイルからデータ入手する関数
def read_data
  File.open('data.json') do |data|
    JSON.parse(data.read)
  end
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
  memos = read_data
  @memos = escaping_memos(memos) || []
  erb :index
end

# メモの詳細画面
get '/memos/*' do |id|
  memo = read_data.detect { |m| m['id'].to_i == id.to_i }
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
  memos = read_data
  redirect '/' if read_data.size >= 500

  title = @params['title']
  content = @params['content']
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
  memo = read_data.detect { |m| m['id'].to_i == id.to_i }
  halt erb :not_found if memo.nil?

  @memo = escaping_memos([memo])[0]
  @title = 'Edit'
  erb :edit_memo
end

patch '/memos/*' do |id|
  memos = read_data
  memos.each do |memo|
    if memo['id'] == id.to_i
      memo['title'] = @params['title']
      memo['content'] = @params['content']
    end
  end

  File.open('data.json', 'w') do |f|
    JSON.dump(memos, f)
  end

  redirect '/'
end

# メモの削除
delete '/memos/*' do |id|
  keeps = read_data.keep_if { |m| m['id'] != id.to_i }

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
