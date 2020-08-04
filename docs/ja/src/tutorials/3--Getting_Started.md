# GenieでHello world

Genie Webアプリの構築をすぐに開始できるようにいくつかの例を挙げます。

## REPLまたはJupyterで対話的にGenieを動かす

もっとも簡単な使用例は、REPLでルーティング機能を構成し、Webサーバを起動することです。Webでコードを実行するのに必要なことはそれだけです。

### 例

```julia
julia> using Genie, Genie.Router

julia> route("/hello") do
          "Hello World"
       end

julia> up()
```

`route`関数(`Router`モジュールで利用可能)は、URL(`"/hello"`)とクライアントにレスポンスを送るために自動的に呼び出されるJuila関数とのマッピングを定義します。今回の例の場合は、文字列"Hello World"を送り返します。 

これがすべてです！アプリとルートを設定し、Webサーバを起動しました。お気に入りのブラウザを開き、<http://127.0.0.1:8000/hello>にアクセスして結果を確認します。

---
**注意喚起**

JuliaのJIT(Just-In-Time)コンパイルに注意してください。関数は初めて呼び出されたとき自動的にコンパイルされます。この場合、関数はリクエストを処理するルートハンドラです。このことにより、コンパイル時間も含まれるため最初の応答が遅くなります。しかし、一度関数がコンパイルされてしまえば、そのあとのすべてのリクエストに対して、非常に高速になります！

---

## シンプルなGenieスクリプトの開発

Genieは、Juliaでマイクロサービスを構築するときなど、カスタムスクリプトでも使用できます。簡単なHello Worldマイクロサービスを作成しましょう。

コードを書く新しいファイルを作成することから始めます。それを`geniews.jl`としましょう。

```julia
julia> touch("geniews.jl")
```

次に`geniews.jl`をエディタで開きます。

```julia
julia> edit("geniews.jl")
```

以下のコードを追加します。

```julia
using Genie, Genie.Router
using Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json

route("/hello.html") do
  html("Hello World")
end

route("/hello.json") do
  json("Hello World")
end

route("/hello.txt") do
   respond("Hello World", :text)
end

up(8001, async = false)
```

まず2つのルートを定義し、`html`および` json`レンダリング関数(`Renderer.Html`モジュールや`Renderer.Json`モジュールで利用可能)を使用しました。こららの関数は、正しい形式とドキュメントタイプ(正しいMIME)を利用することでデータを出力する役割を果たします。今回の場合は、`hello.html`のHTMLデータと`hello.json`のJSONデータです。

3番目の`route`はテキスト形式のレスポンスを提供します。Genieは`text/plain`形式のレスポンスを送信するための特別な方法を提供していないため、一般的な`respond`関数を利用し、望むMIME形式を指定します。今回の場合は、`text / plain`に対応する`：text`です。他に利用可能なMIME形式のショートカットは、`:xml`、`:markdown`、`:javascript`です。他の指定については、文字列でのフルMIME形式の指定ができます。(例：`"text/csv"`)

`up`関数は`8001`ポートでWebサーバを起動します。この時、非常に重要なのは、`async = false`を引数で渡すことにより、サーバーを同期的(つまり、スクリプト実行のブロッキング操作)に開始できるように命令していることです。このようにして、スクリプトの実行を維持しています。そうしないと、スクリプトの最後で通常終了し、サーバが強制終了します。

スクリプトを起動するには、`$ julia geniews.jl`を実行します。

## バッテリー同梱(標準機能の充実性)

Genieでは豊富な機能のセットがすぐに利用できるようになっています。(レンダリングエンジンとルーティングエンジンの動作はすでに見てきたとおりです。)ただし、例えば、1行のコードで(ファイルやコンソールへの)ログを簡単にトリガーしたり、さらに数行で強力なキャッシュを有効にしたりできます。

アプリはすでに「404 Page Not Found」や「500 Internal Error」レスポンスを処理しています。もし<http://127.0.0.1:8001/not_here>のようにアプリで処理されないURLにアクセスしようとすると、Genieのデフォルト404ページが表示されます。デフォルトのエラーページはカスタムページで上書きすることができます。手順はあとで示します。
