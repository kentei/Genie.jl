# POSTペイロードの読み込み

Genie makes it easy to work with `POST` payloads. First, we need to register a dedicated route to handle `POST` requests. Then, once a `POST` request is received, Genie will automatically extract the payload, making it accessible throughout the `Requests.postpayload` method -- and appending it to the `Router.@params(:POST)` collection.

## `form-data`ペイロードの処理

次のスニペットは、アプリのルート(root)に2つのルート(routes)を登録します。1つは`GET`リクエスト用で、もう1つは`POST`リクエスト用です。`GET`ルートは、`POST`を介して他のルートに送信するフォームを表示します。最後に、データを受信するとカスタムメッセージを表示します。

### 例

```julia
using Genie, Genie.Router, Genie.Renderer.Html, Genie.Requests

form = """
<form action="/" method="POST" enctype="multipart/form-data">
  <input type="text" name="name" value="" placeholder="What's your name?" />
  <input type="submit" value="Greet" />
</form>
"""

route("/") do
  html(form)
end

route("/", method = POST) do
  "Hello $(postpayload(:name, "Anon"))"
end

up()
```

`postpayload`関数はいくつかの特殊性があり、そのうちの1つにはキーとデフォルト値を受け入れることが挙げられます。`key`変数が定義されていない場合、デフォルト値が返されます。APIドキュメントまたはJuliaの `help>`モードを利用することで、 `postpayload`のさまざまな実装を確認できます。
