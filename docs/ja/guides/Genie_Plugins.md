# Genieプラグイン

Genieプラグインは、特別な統合ポイント(integration points)を提供することにより、強力な機能でGenieアプリを拡張する特別なJuliaパッケージです。Genieプラグインは2つのパートで構成されています。

1. プラグインのコア機能を公開するJuliaパッケージ
2. プラグインのインストール時にクライアントアプリにコピーされるファイルペイロード(コントローラ、モジュール、ビュー、データベースマイグレーション、イニシャライザなど)

## Genieプラグインの利用

プラグインはサードパーティであるGenie/Julia開発者によって作成されます。例としてシンプルなデモプラグインを扱ってみましょう。(<https://github.com/GenieFramework/HelloPlugin.jl>)

プラグインを既存のアプリに追加するために、以下を実施する必要があります。

`HelloPlugin`パッケージを、他のJulia Pkg依存のように、Genieアプリに追加してください。

```julia
pkg> add https://github.com/GenieFramework/HelloPlugin.jl
```

スコープ内にパッケージを持ってきます。
```julia
julia> using HelloPlugin
```

プラグインをインストールします。(これはパッケージを追加するときに一度だけ実施します)
```julia
julia> HelloPlugin.install(@__DIR__)
```

### プラグインの実行

プラグインのインストールにより、`app/resources/hello/`に`HelloController.jl`と`views/greet.jl.html`という形式で新たな`hello`リソースが追加されます。また、Genieアプリの`plugins/`フォルダに新しいファイル`helloplugin.jl`(プラグインのイニシャライザであり、ブートストラッププロセスの早い段階でGenieによって自動的に読み込まれます)があります。

`helloplugin.jl`イニシャライザは新しいルート`route("/hello", HelloController.greet)`を定義しています。Genieアプリを再起動し、`/hello`に移動すると、プラグインの挨拶が表示されます。

## ウォークスルー

新しいGenieアプリを作成します。

```julia
julia> using Genie

julia> Genie.newapp("Greetings", autostart = false)
```

依存関係としてプラグインを追加します。

```julia
julia> ]

pkg> add https://github.com/GenieFramework/HelloPlugin.jl
```

プラグインをスコープ内に入れ、インストーラを実行します。(インストーラはプラグインパッケージを追加する際に、一度だけ実行されます)

```julia
julia> using HelloPlugin

julia> HelloPlugin.install(@__DIR__)
```

インストール時には、ファイルのコピーやフォルダの作成に失敗した旨を通知する一連のログメッセージが表示されるかもしれません。通常、そのことは心配する必要がありません。これらはいくつかのファイルまたはフォルダがすでに存在するためにインストーラが上書きできないために発生しています。

プラグインを読み込むためにアプリを再起動してください。

```julia
julia> exit()

$ cd Greetings/

$ bin/repl
```

サーバを開始します。

```julia
julia> Genie.startup()
```

<http://localhost:8000/hello>に移動するとプラグインから挨拶を受けることができます。

---

## Genieプラグインの開発

Genieは新しいプラグインパッケージのブートストラップ用の効率的なスキャフォールド(scaffold)を提供します。プラグインプロジェクトを作成するためには以下のコードを実行するだけです。

```julia
julia> using Genie

julia> Genie.Plugins.scaffold("GenieHelloPlugin") # use the actual name of your plugin
Generating project file
Generating project GenieHelloPlugin:
    GenieHelloPlugin/Project.toml
    GenieHelloPlugin/src/GenieHelloPlugin.jl
Scaffolding file structure

Adding dependencies
  Updating registry at `~/.julia/registries/General`
  Updating git-repo `https://github.com/JuliaRegistries/General.git`
  Updating git-repo `https://github.com/genieframework/Genie.jl`
 Resolving package versions...
  Updating `~/GenieHelloPlugin/Project.toml`
  [c43c736e] + Genie v0.9.4 #master (https://github.com/genieframework/Genie.jl)
  Updating `~/GenieHelloPlugin/Manifest.toml`

Initialized empty Git repository in /Users/adrian/GenieHelloPlugin/.git/
[master (root-commit) 30533f9] initial commit
 11 files changed, 261 insertions(+)

Congratulations, your plugin is ready!
You can use this default installation function in your plugin's module:
  function install(dest::String; force = false)
    src = abspath(normpath(joinpath(@__DIR__, "..", Genie.Plugins.FILES_FOLDER)))

    for f in readdir(src)
      isdir(f) || continue
      Genie.Plugins.install(joinpath(src, f), dest, force = force)
    end
  end
```

スキャフォールドコマンドはプラグインのファイル構造を生成します。それはJuliaプロジェクト、`git`リポジトリ、Genieアプリを統合するためのファイル構造を含んでいます。

```
.
├── Manifest.toml
├── Project.toml
├── files
│   ├── app
│   │   ├── assets
│   │   │   ├── css
│   │   │   ├── fonts
│   │   │   └── js
│   │   ├── helpers
│   │   ├── layouts
│   │   └── resources
│   ├── db
│   │   ├── migrations
│   │   └── seeds
│   ├── lib
│   ├── plugins
│   │   └── geniehelloplugin.jl
│   └── task
└── src
    └── GenieHelloPlugin.jl
```

機能のコア部分は`src/GenieHelloPlugin.jl`モジュールにあります。`files/`フォルダ内に配置されたすべてのものは、プラグインをインストールするGenieアプリの対応するフォルダにコピーする必要があります。リソース、コントローラ、モデル、データベースマイグレーション、ビュー、アセットおよびコピーするべき`files/`フォルダの中にあるその他のファイルを追加できます。

スキャフォールディングは`plugins/geniehelloplugin.jl`ファイルも作成します。これはプラグインのイニシャライザであり、プラグインの機能をブートストラップすることを意図しています。ここでは、依存関係の読み込み、ルートの定義、設定のセットアップなどを実施できます。

GenieプラグインはJulia `Pkg`プロジェクトであるため、依存関係として他のJuliaパッケージを追加することができます。

### インストール機能

`src/GenieHelloPlugin.jl`にあるメインモジュールファイルは、ユーザのGenieアプリにプラグインのファイルをコピーする役割を持つ`install(path::String)`関数も公開する必要があります。その`path`パラメータは、インストールが実行されるGenieアプリのルートディレクトリです。

プラグインのファイルをコピーすることは普通ですが、面倒な操作であるため、Genieはそれを開始するためのいくつかのヘルパーを提供します。`Genie.Plugins`モジュールは、アプリのプラグインファイルのコピー先にファイルをコピーするのに使うことができる`install(path::String, dest::String; force = false)`を提供します。

スキャフォールディング機能は、モジュールで使用できるデフォルトの`install(path::String)`も推奨しています。

```julia
function install(dest::String; force = false)
  src = abspath(normpath(joinpath(@__DIR__, "..", Genie.Plugins.FILES_FOLDER)))

  for f in readdir(src)
    isdir(f) || continue
    Genie.Plugins.install(joinpath(src, f), dest, force = force)
  end
end
```

ここまでをスタート地点として利用し、他の独自のロジックを追加できます。