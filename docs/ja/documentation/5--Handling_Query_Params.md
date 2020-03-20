# クエリパラメータの処理 (GET変数)

Genieは、GETリクエストを介してURLの一部分として送信されるクエリパラメータに簡単にアクセスすることができます(例：「mywebsite.com/index?foo=1&bar=2」の`foo`と`bar`は変数`foo = 1`、`bar = 2`に対応するクエリパラメータです)。これらの値はすべてGenieによって自動的に収集され、`@params`コレクション(`Router`モジュールの一部)に公開されます。

### 例

```julia
using Genie, Genie.Router

route("/hi") do
  name = haskey(@params, :name) ? @params(:name) : "Anon"

  "Hello $name"
end
```
<http://127.0.0.1:8000/hi>にアクセスすると、クエリパラメータ指定がないため、アプリは「Hello Anon」を返します。

しかしながら、<http://127.0.0.1:8000/hi?name=Adrian>へのリクエストは、`name`クエリ変数に`Adrian`という値を渡しているため、「Hello Adrian」と表示します。この変数はGenieによって`@params(:name)`として公開されています。

しかし、Genieは `Requests`モジュールでこれらの値にアクセスするためのユーティリティメソッドを提供します。

## `Requests`モジュール

Genieは、`Requests`モジュール内でリクエストデータを操作するためのユーティリティセットを提供しています。`getpayload`メソッドを利用することで、クエリパラメータを`Dict{Symbol,Any}`として取得することができます。`Requests`ユーティリティを利用することで前のルートを書き直すことができます。

### 例

```julia
using Genie, Genie.Router, Genie.Requests

route("/hi") do
  "Hello $(getpayload(:name, "Anon"))"
end
```

`getpayload`関数はいくつかの特殊性があり、そのうちの1つにはキーとデフォルト値を受け入れることが挙げられます。`key`変数が定義されていない場合、デフォルト値が返されます。APIドキュメントまたはJuliaの `help>`モードを利用することで、 `getpayload`のさまざまな実装を確認できます。
