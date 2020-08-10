# HerokuビルドパックによるGenieアプリのデプロイ

これはHerokuビルドパックを利用してJulia/Genieアプリを提供する方法のチュートリアルです。

## 前提条件

このガイドは、Herokuアカウントがあり、Heroku CLIにサインインしていることを想定しています。[Heroku CLIのセットアップ方法の情報はこちらから](https://devcenter.heroku.com/articles/heroku-cli)

## アプリケーション

デプロイを試すために、サンプルアプリケーションが必要です。次で示すように、自分のものを利用するかサンプルをクローンするかどちらかを選択してください。

### 全ステップ (簡単なコピー/ペースト形式)

`HEROKU_APP_NAME`をユニークなものにカスタマイズします。

```sh
HEROKU_APP_NAME=my-app-name
```

必要に応じてサンプルアプリをクローンします。

```sh
git clone https://github.com/milesfrain/GenieOnHeroku.git
```

アプリのフォルダに移動します。

```sh
cd GenieOnHeroku
```

次にHerokuアプリを作成します。

```sh
heroku create $HEROKU_APP_NAME --buildpack https://github.com/Optomatica/heroku-buildpack-julia.git
```

Herokuに新しく作成したアプリをプッシュします。

```sh
git push heroku master
```

ここで、ブラウザでアプリを開くことができます。

```sh
heroku open -a $HEROKU_APP_NAME
```

必要であればログをチェックします。

```sh
heroku logs -tail -a $HEROKU_APP_NAME
```

### より詳細な説明のあるステップ

#### アプリ名を選択

```sh
HEROKU_APP_NAME=my-app-name
```

これはすべてのHerokuプロジェクト間でユニークである必要があり、プロジェクトが提供されるURLの一部になります。(例：https://my-app-name.herokuapp.com/)

名前がユニークでない場合、`heroku create`ステップでエラーが発生します。

```sh
Creating ⬢ my-app-name... !
 ▸    Name my-app-name is already taken
```

#### サンプルプロジェクトのクローン

```sh
git clone https://github.com/milesfrain/GenieOnHeroku.git
cd GenieOnHeroku
```

自身のプロジェクトを選択することもできますが、gitリポジトリである必要があります。

ルートディレクトリの`Procfile`はアプリを読み込むための起動コマンドを含んでいます。
このプロジェクトの`Procfile`の内容は以下の1行です。

```sh
web: julia --project src/app.jl $PORT
```

`Procfile`を編集して自身のプロジェクトの起動スクリプトに向けることもできます。(例えば`src/app.jl`の代わりに`src/my_app_launch_file.jl`)　ただし、Herokuによって設定され動的に変化する`$PORT`環境変数は考慮にいれてください。

`Genie.newapp`で構築した標準Genieアプリケーションをデプロイする場合、起動スクリプトは`bin/sever`になります。Genieは自動的に環境から`$PORT`番号を選択します。

#### Herokuプロジェクトの生成

```sh
heroku create $HEROKU_APP_NAME --buildpack https://github.com/Optomatica/heroku-buildpack-julia.git
```

上記により、Herokuプラットフォーム上にプロジェクトが作成されます。これには個別のgitリポジトリが含まれます。

この`heroku`レポジトリは追跡対象リポジトリの一覧に追加され、`git remote -v`で監視が可能です。

```sh
heroku  https://git.heroku.com/my-app-name.git (fetch)
heroku  https://git.heroku.com/my-app-name.git (push)
origin  https://github.com/milesfrain/GenieOnHeroku.git (fetch)
origin  https://github.com/milesfrain/GenieOnHeroku.git (push)
```

Juliaのビルドパックを使用します。これはJuliaプロジェクトが必要とする共通のデプロイ操作の多くを実行します。
それは、ルートディレクトリにある`Project.toml`, `Manifest.toml`、`src`ディレクトリ内のすべてのJuliaコードとともにサンプルプロジェクト内にあるディレクトリレイアウトに依存します。

#### アプリのデプロイ

```sh
git push heroku master
```

`heroku`リモートレポジトリの`master`ブランチに対して、ローカルレポジトリの現在のブランチをプッシュしています。

Herokuは自動的に最新のプッシュのProcfileとJuliaビルドパックで書かれたコマンドを実行します。

自動デプロイをトリガーするには、herokuの`master`ブランチにプッシュする必要があります。

#### アプリのWebページ表示

```sh
heroku open -a $HEROKU_APP_NAME
```

上記はアプリのWebページをブラウザで開く便利なコマンドです。

Webページ: `https://$HEROKU_APP_NAME.herokuapp.com/`

例: <https://my-app-name.herokuapp.com/>

#### アプリログの表示

```sh
heroku logs -tail -a $HEROKU_APP_NAME
```

これはアプリの最新のステータスを表示し続けるログビューアを起動する別の便利なコマンドです。

Juliaの`println`文もここに表示されます。

このビューアからは`Ctrl-C`で抜けてください。

ログはHerokuのWebダッシュボードからも表示できます。
例: <https://dashboard.heroku.com/apps/my-app-name/logs>

### アプリの修正をデプロイ

アプリへの変更をデプロイするために、ローカルにこれらの変更をコミットし、herokuに再度プッシュします。

```sh
<make changes>
git commit -am "my commit message"
git push heroku master
```
