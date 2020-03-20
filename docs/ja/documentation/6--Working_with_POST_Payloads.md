# POSTペイロードの読み込み

GenieによりPOSTペイロードは簡単に操作できます。初めに、`POST`リクエストを処理するための専用ルートを登録する必要があります。次に、`POST`リクエストを一度受信する度に、Genieは自動的にペイロードを抽出し、`Requests.postpayload`メソッドを通してアクセス可能とします。そして、`Router.@params(:POST)`コレクションにそれを追加します。

## `form-data`ペイロードの処理

次のスニペットは、アプリのルート(root)に2つのルート(routes)を登録します。1つは`GET`リクエスト用で、もう1つは`POST`リクエスト用です。`GET`ルートは、`POST`を介して他のルートに送信するフォームを表示します。最後に、データを受信するとカスタムメッセージを表示します。

### 例

```julia
using Genie, Genie.Router, Genie.Renderer.Html, Genie.Requests

form = """
<form action="/" method="POST" enctype="multipart/form-data">
  <input type="text" name="name" value="" placeholder="あなたのお名前は?" />
  <input type="submit" value="挨拶" />
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
