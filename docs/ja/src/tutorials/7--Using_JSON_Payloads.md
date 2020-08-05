# JSONペイロードの利用

特にREST APIを開発する際の非常に一般的なデザインパターンは、`POST`リクエストを介して`application/json`データとして送られるJSONペイロードを受け入れることです。Genieはユーティリティ関数`Requests.jsonpayload`を利用してこのユースケースを効率的に処理します。関数の内部で、Genieは`POST`リクエストを処理し、JSONテキストペイロードの解析を試みます。これが失敗した場合でも、`Requests.rawpayload`メソッドを利用することで生データ（JSONに変換されていないテキストペイロード）にアクセスできます。

### 例

```julia
using Genie, Genie.Router, Genie.Requests, Genie.Renderer.Json

route("/jsonpayload", method = POST) do
  @show jsonpayload()
  @show rawpayload()

  json("Hello $(jsonpayload()["name"])")
end

up()
```

次に`HTTP` パッケージを利用することで`POST`リクエストを作成します。

```julia
using HTTP

HTTP.request("POST", "http://localhost:8000/jsonpayload", [("Content-Type", "application/json")], """{"name":"Adrian"}""")
```

以下の内容が出力されます。

```julia
jsonpayload() = Dict{String,Any}("name"=>"Adrian")
rawpayload() = "{\"name\":\"Adrian\"}"

INFO:Main: /jsonpayload 200

HTTP.Messages.Response:
"""
HTTP/1.1 200 OK
Content-Type: application/json
Transfer-Encoding: chunked

"Hello Adrian""""
```

初めに、2つの`@show`の呼び出しについて、`jsonpayload`が`POST`データを`Dict`型に正常に変換したことに注目してください。一方で`rawpayload`は`POST`データを`String`型として、受け取った通りに返しています。最後にルートハンドラーはJSONレスポンスを返し、`jsonpayload` `Dict`から名前を抽出して、ユーザに挨拶しています。
