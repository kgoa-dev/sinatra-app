# Sinatra-TodoApp

## Description

```
cd {パス}/sinatra-app
% bundle install
% bundle exec ruby app.rb
# =>起動
```
`http://127.0.0.1:4567/`にアクセス。

終了時は`^ + C`で終了。

### Database
```sql
{DB名}=# select {スキーマ名}

{DB名}=# create table {テーブル名} (
          id integer,
          title text,
          content text
        );
```
