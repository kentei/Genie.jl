# シンプルなAPIバックエンドの開発

GenieによりREST APIバックエンドを素早くとても簡単にセットアップすることができます。必要なものは、数行のコードですべてです。

```julia
using Genie
import Genie.Router: route
import Genie.Renderer.Json: json

Genie.config.run_as_server = true

route("/") do
  (:message => "Hi there!") |> json
end

Genie.startup()
```

ここで重要になるのは、`Genie.config.run_as_server = true`です。これはサーバを同期的に起動するため、`startup()`関数は返りません。
このエンドポイントはコマンドラインから直接実行できます。`rest.jl`ファイルにコードを保存して実行します。

```shell
$ julia rest.jl
```

## JSONペイロードの受け入れ

APIを公開するとき共通の要件の一つは`POST`ペイロードを受け入れることです。つまり、通常JSONエンコードされたオブジェクトであるリクエストボディと一緒に`POST`を介してリクエストを送信します。次のようなechoサービスを構築してみます。

```julia
using Genie, Genie.Router, Genie.Renderer.Json, Genie.Requests
using HTTP

route("/echo", method = POST) do
  message = jsonpayload()
  (:echo => (message["message"] * " ") ^ message["repeat"]) |> json
end

route("/send") do
  response = HTTP.request("POST", "http://localhost:8000/echo", [("Content-Type", "application/json")], """{"message":"hello", "repeat":3}""")

  response.body |> String |> json
end

Genie.startup(async = false)
```

ここでは2つのルート`/send`と`/echo`を定義しています。`send`ルートは`/echo`への`POST`を介した`HTTP`リクエストを作成し、2つの値`message`と`repeat`とともにJSONペイロードを送信します。
`/echo`ルートでは、`Requests.jsonpayload()`関数を利用し、JSONペイロードを取得し、JSONオブジェクトから値を抽出し、`message`値を`repeat`値で指定された数分だけ繰り返し出力します。

コードを実行すると、以下のように出力されます。

```javascript
{
  echo: "hello hello hello "
}
```

ペイロードに無効なJSONが含まれている場合は、`jsonpayload`は`nothing`に設定されます。`Requests.rawpayload()`関数を利用することで生ペイロードに引き続きアクセスすることはできます。
例えばリクエスト/ペイロードの型がJSONでない場合でも、`rawpayload`を使用することができます。
