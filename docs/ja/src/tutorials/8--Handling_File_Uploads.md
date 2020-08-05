# ファイルアップロードの操作

Genieはファイルのアップロード機能を内蔵しています。アップロードされたファイルのコレクション(`POST`変数として扱う)は、`Requests.filespayload`メソッドを介してアクセスできます。または、`Requests.filespayload(key)`を利用することにより、与えられたファイルフォーム入力に対応するデータを取得できます。(`key`はフォーム内のファイル入力の名前(name)です)

以下のスニペットでは、アプリのルート(root)に2つのルート(`/`)を構成します。初めのルートは`GET`リクエストを処理し、アップロード用のフォームを表示します。2つ目のルートは`POST`リクエストを処理し、アップロードを実施し、アップされたデータからファイルを生成し、それを保存、さらにファイルの統計情報を表示します。

### 例

```julia
using Genie, Genie.Router, Genie.Renderer.Html, Genie.Requests

form = """
<form action="/" method="POST" enctype="multipart/form-data">
  <input type="file" name="yourfile" /><br/>
  <input type="submit" value="Submit" />
</form>
"""

route("/") do
  html(form)
end

route("/", method = POST) do
  if infilespayload(:yourfile)
    write(filespayload(:yourfile))

    stat(filename(filespayload(:yourfile)))
  else
    "No file uploaded"
  end
end

up()
```

ファイルをアップロードしてフォームを送信すると、アプリにファイルの統計情報が表示されます。
