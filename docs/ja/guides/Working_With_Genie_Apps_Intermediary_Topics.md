# Genieアプリの操作(中級トピック)

---
**注意喚起**

このガイドはまだ修正中で予期せぬ動作をするものがあるかもしれません。現在修正に取り組んでおり、数週間で準備が整う予定です。Github上でGenieにスターをつけてフォローしていただくと、変更があった際に通知を受けることができます。

---

## フォームの処理

ここで、問題はビルゲイツの本をたくさん読むことです。ユーザが自身で本を追加できるようにして、手を貸していただければそれはより簡単になります。
しかし、当然ながらJulia REPLにアクセスすることはできないので、フォームを使用できるようにWebページをセットアップしてみましょう。

新たなルートを追加することから始めます。

```julia
# routes.jl
route("/bgbooks/new", BooksController.new)
route("/bgbooks/create", BooksController.create, method = POST, named = :create_book)
```

最初のルートは新規本のフォームページを表示するのに使われます。2つ目はフォームを送信するためのターゲットページで、ここでフォームのペイロードを受け入れます。
`POST`リクエストに一致するように設定されていて、名前を与えられていることに注意してください。フォームで名前を利用して、Genieが対応しているURLへの正しいリンクを動的に生成するようにします。(URLのべた書きコードを避けるため)
このようにして、ルートを変更したとしても(名前を変更しないかぎり)、フォームが常に正しいURLを送れるようにしています。

ここで `BooksController`にメソッドを追加します。これらの定義は`billgatesbooks`関数下に追加します。(`BooksController.API`ではなく、`BooksController`に追加してください)

```julia
# BooksController.jl
function new()
  html(:books, :new)
end

function create()
  # code here
end
```

`new`メソッドは明確です。`new`という名前のビューファイルをレンダリングするだけです。`create`メソッドについては、現状では単なるプレースホルダーです。

次にビューを追加します。`new.jl.html`という名前の空ファイルを`app/resources/books/views`に追加します。以下のようにJuliaを利用します。

```julia
julia> touch("app/resources/books/views/new.jl.html")
```

以下の内容となるように確認してください。

```html
<!-- app/resources/books/views/new.jl.html -->
<h2>Add a new book recommended by Bill Gates</h2>
<p>
  For inspiration you can visit <a href="https://www.gatesnotes.com/Books" target="_blank">Bill Gates' website</a>
</p>
<form action="$(Genie.Router.linkto(:create_book))" method="POST">
  <input type="text" name="book_title" placeholder="Book title" /><br />
  <input type="text" name="book_author" placeholder="Book author" /><br />
  <input type="submit" value="Add book" />
</form>
```

フォームの動作が`linkto`メソッドを呼び、ルート名前を渡すことでURLを生成し、次のHTMLが生成されることに注意してください。`<form method="POST" action="/bgbooks/create">`

`BooksController.create`メソッドを更新し、フォームデータで便利なことを行えるようにしてみましょう。新規の本を作成してデータベースに永続化し、本の一覧にリダイレクトしてみましょう。コードは以下の通りです。

```julia
# BooksController.jl
using Genie.Router

function create()
  Book(title = @params(:book_title), author = @params(:book_author)) |> save && redirect(:get_bgbooks)
end
```

このスニペットにはいくつか重要なポイントがあります。

* 再度、`@params`コレクションにアクセスし、リクエストデータを抽出しています。今回の場合、フォーム入力の名前をパラメータとして渡しています。
`@params`にアクセスするためにスコープに`Genie.Router`を含める必要があります。
* HTTPリダイレクトを実行するために`redirect`メソッドを使用します。フォームのアクションで実施したのと同じように、ルートの名前を引数として渡します。
しかし、この名前を使用するルートは設定してません。Genieがすべてのルートにデフォルト名を与えることは判明しています。
これらを使用できますが、注意点があります。**これらの名前はルートのプロパティを利用して生成されるため、ルート変更された場合にその名前も変わってしまう可能性があります。**
そのため、ルートが変更されないようにするか、ルートに明示的に名前をつけます。自動生成された名前`get_bgbooks`はメソッド(`GET`)とルート(`bgbooks`)に対応しています。

定義済みのルート情報を得るために、`Router.named_routes`関数を利用します。

```julia
julia> Router.named_routes()
julia> Dict{Symbol,Genie.Router.Route} with 6 entries:
  :get_bgbooks        => Route("GET", "/bgbooks", billgatesbooks, Dict{Symbol,Any}(), Function[], Function[])
  :get_bgbooks_new    => Route("GET", "/bgbooks/new", new, Dict{Symbol,Any}(), Function[], Function[])
  :get                => Route("GET", "/", (), Dict{Symbol,Any}(), Function[], Function[])
  :get_api_v1_bgbooks => Route("GET", "/api/v1/bgbooks", billgatesbooks, Dict{Symbol,Any}(), Function[], Function[])
  :create_book        => Route("POST", "/bgbooks/create", create, Dict{Symbol,Any}(), Function[], Function[])
  :get_friday         => Route("GET", "/friday", (), Dict{Symbol,Any}(), Function[], Function[])
```

試してみましょう。何かを入力してフォームを送信します。すべてがうまくいくと、データベースに新しい本が永続化され、本の一覧の下方にそれが追加されます。

---

## ファイルのアップロード

アプリは素晴らしいが、本の一覧に表紙が表示できるとより良くなるでしょう。やってみましょう！

### データベースの変更

最初に実施するのは、新しい列を追加するためにテーブルを変更し、表紙画像の名前への参照を保存することです。もちろん、マイグレーションを利用します。

```julia
julia> Genie.newmigration("add cover column")
[debug] New table migration created at db/migrations/2019030813344258_add_cover_column.jl
```

ここでマイグレーションファイルを編集する必要があります。以下のようになるように修正してください。

```julia
# db/migrations/*_add_cover_column.jl
module AddCoverColumn

import SearchLight.Migrations: add_column, remove_column

function up()
  add_column(:books, :cover, :string)
end

function down()
  remove_column(:books, :cover)
end

end
```

いい感じです。SearchLightに上記を実行するように命令しましょう。

```julia
julia> SearchLight.Migration.last_up()
[debug] Executed migration AddCoverColumn up
```

ダブルチェックをしたい場合は、マイグレーションステータスをSearchLightに尋ねましょう。

```julia
julia> SearchLight.Migration.status()

|   |                  Module name & status  |
|   |                             File name  |
|---|----------------------------------------|
|   |                   CreateTableBooks: UP |
| 1 | 2018100120160530_create_table_books.jl |
|   |                     AddCoverColumn: UP |
| 2 |   2019030813344258_add_cover_column.jl |
```

完璧ですね！　次に`Books.Book`モデルに新しいカラムをフィールドとして追加する必要があります。

```julia
module Books

using SearchLight, SearchLight.Validation, BooksValidator

export Book

mutable struct Book <: AbstractModel
  ### INTERNALS
  _table_name::String
  _id::String

  ### FIELDS
  id::DbId
  title::String
  author::String
  cover::String

  Book(;
    ### FIELDS
    id = DbId(),
    title = "",
    author = "",
    cover = "",
  ) = new("books", "id", id, title, author, cover)
end

end
```

簡単なテストとして、JSONビューを拡張して、すべてがうまくいってることを確認できます。以下のように修正してください。

```julia
# app/resources/books/views/billgatesbooks.json.jl
"Bill's Gates list of recommended books" => [Dict("author" => b.author,
                                                  "title" => b.title,
                                                  "cover" => b.cover) for b in @vars(:books)]
```

<http://localhost:8000/api/v1/bgbooks>に移動すると、新たに追加された`cover`プロパティを確認できます。(現状は空ですが)

##### 注意喚起!

時々、Julia/Genie/Reviseは、変更時に`構造体(structs)`の更新に失敗します。`Book`に`cover`フィールドがないというエラーであれば、Genieアプリを再起動してください。

### ファイルアップロード

次のステップで、画像(本の表紙)をアップロードするためにフォームを拡張します。`new.jl.html`ビューファイルを以下のように修正してください。

```html
<h3>Add a new book recommended by Bill Gates</h3>
<p>
  For inspiration you can visit <a href="https://www.gatesnotes.com/Books" target="_blank">Bill Gates' website</a>
</p>
<form action="$(Genie.Router.linkto(:create_book))" method="POST" enctype="multipart/form-data">
  <input type="text" name="book_title" placeholder="Book title" /><br />
  <input type="text" name="book_author" placeholder="Book author" /><br />
  <input type="file" name="book_cover" /><br />
  <input type="submit" value="Add book" />
</form>
```

新規部分は以下の通りです。

* 新たな属性`enctype="multipart/form-data"`を`<form>`タグに追加しました。これは、ファイルのペイロードをサポートするために必要なものです。
* 新たにファイル型の入力エリア`<input type="file" name="book_cover" />`があります。

<http://localhost:8000/bgbooks/new>に移動することで、更新されたフォームを確認できます。

ここで、表紙つきの新たな本を追加してみましょう。フランシス・フクヤマの"Identity"なんてどうでしょうか？いい感じですね。
表紙にしたい画像を何でも利用することができます。もしくはビルゲイツから借りてくるのもいいかもしれないです。(彼は気にしないと思うから。<https://www.gatesnotes.com/-/media/Images/GoodReadsBookCovers/Identity.png>)
ファイルをコンピュータにダウンロードするだけで、フォームを通してアップロードできます。

もう少しです。サーバ側でアップロードされたファイルを処理するロジックを追加します。`BooksController.create`メソッドを以下のように更新してください。

```julia
# BooksController
function create()
  cover_path = if haskey(filespayload(), "book_cover")
      path = joinpath("img", "covers", filespayload("book_cover").name)
      write(joinpath("public", path), IOBuffer(filespayload("book_cover").data))

      path
    else
      ""
  end

  Book( title = @params(:book_title),
        author = @params(:book_author),
        cover = cover_path) |> save && redirect(:get_bgbooks)
end
```

非常に重要な点は、`BooksController`が`using Genie.Requests`であることを確認する必要があることです。

コードについては、そこまで手は込んでいません。初めに`book_cover`入力のエントリ内容にファイルペイロードが含まれているかチェックしています。
含まれている場合、ファイルを保存するパスを作成し、ファイルを書き込み、データベースにパスを保存します。

**`public/img/`の中に`covers`フォルダが作成されていることを確認してください。**

いいですね。では次に画像を表示してみましょう。HTMLビューから始めましょう。`app/resources/books/views/billgatesbooks.jl.html`を修正し、以下の内容となっていることを確認してください。

```html
<!-- app/resources/books/views/billgatesbooks.jl.html -->
<h1>Bill's Gates top $( length(@vars(:books)) ) recommended books</h1>
<ul>
<%
@foreach(@vars(:books)) do book
%>
  <li><img src='$( isempty(book.cover) ? "img/docs.png" : book.cover )' width="100px" /> $(book.title) by $(book.author)
<%
end
%>
</ul>
```

基本的にここでは`cover`プロパティが空でないことのチェックをし、実際の表紙を表示します。空の場合はプレースホルダー画像を表示します。<http://localhost:8000/bgbooks>で結果をチェックできます。

JSONビューについては、すでに完成しています。<http://localhost:8000/api/v1/bgbooks>に移動することで、データベースに保存されているように、`cover`プロパティが出力されることを確認できます。

成功しました。ここで完了です！



#### 注意喚起!

本番環境では、よりアップロード部分のコードはより堅牢にしなければなりません。ここでの大きな問題は、ユーザからの表紙ファイルを保存することです。それにより、ファイル名の衝突やファイル上書きを招く可能性があります。セキュリティの脆弱性は言うまでもないでしょう。
より堅牢にする方法は、作者とタイトルに基づいてハッシュ計算し、表紙のファイル名をそれに変えることです。

### もう一つ...

ここまで問題はありませんが、既にアップロードされた本を更新したい場合はどうでしょうか。これらの欠けている表紙を追加するのがよいでしょう。
編集機能を含めるならば、機能を少々加える必要があります。

まず最初にルートを追加しましょう。2つの新しいルート定義を`routes.jl`ファイルに追加してください。

```julia
route("/bgbooks/:id::Int/edit", BooksController.edit)
route("/bgbooks/:id::Int/update", BooksController.update, method = POST, named = :update_book)
```

2つの新しいルートを定義しました。一つは編集用で、フォームに本のオブジェクトを表示します。一方はサーバ側でデータベースを実際に更新してくれます。
両方のルートは編集したい本のidを渡す必要があります。さらにそれを`Int`型に制限します。これはルートの`/:id::Int/`部分で表現しています。

また以下も実施します。

* `app/resources/books/views/new.jl.html`で定義したフォームを再利用します。
* 適切な`action`を設定することで、新規で本を追加しているのか、すでにある本を編集しているのかがフォームに伝わるようにします
* 本を編集する際、本の情報を入力エリアに事前に入力するようにします

よいでしょう。上記は素晴らしい一覧で、面白くなってくるところです。これは、CRUD Webアプリの重要なデザインパターンです。
準備はよいでしょうか、これがコツです。フォームのレンダリングを単純化するために、常に本オブジェクトをフォームに渡します。本の編集の際、`route`に渡された`id`に対応する本になります。新しい本を作る際は、私たちが作成し、そのあと処理するであろう空の本オブジェクトになります。

#### 部分ビューの利用

最初に、ビューをセットアップしましょう。`app/resources/books/views/`に`form.jl.html`という名前のファイルを作成してください。そして、`app/resources/books/views/new.jl.html`から`<form>`コード部分を切り取ってください。つまり、`<form>...</form>`タグの開始から終了まですべてということです。
切り取った内容を新しく作った`form.jl.html`に貼り付けてください。そして、`new.jl.html`に戻って`<form>...</form>`コードの代わりに以下のコードを追加してください。

```julia
<% partial("app/resources/books/views/form.jl.html", context = @__MODULE__) %>
```

`partial`関数が示しているように、この行はビューファイルの一部である部分ビューを含んでおり、他のビュー内のビューを事実上含んでいます。Geneiが部分ビューを含む際、正しい変数スコープを設定できるように`context`を明示的に渡していることに注意してください。

`new`ページをリロードして、すべてがまだ機能していることを確認してください。(<http://localhost:8000/bgbooks/new>)

次に、本の一覧に編集オプションを追加しましょう。一覧ビューファイル `billgatesbooks.jl.html`に戻ってください。
ここでは、`@foreach`ブロック内の各反復で、対応する本の編集ページへ動的にリンクする必要があります。

##### 部分ビューの`@foreach`

しかし、Julia文字列をレンダリングするこの`@foreach`はとても醜いです。部分ビューを利用することでそれをリファクタリングする方法を示します。実際にやってみましょう。初めに`@foreach`ブロックの本体を置き換えます。

```html
<!-- app/resources/books/views/billgatesbooks.jl.html -->
"""<li><img src='$( isempty(book.cover) ? "img/docs.png" : book.cover )' width="100px" /> $(book.title) by $(book.author)"""
```

上記を以下で置き換えてください。

```julia
partial("app/resources/books/views/book.jl.html", book = book, context = @__MODULE__)
```

`partial`関数を利用して、ビューに`book`という名前で、本のオブジェクトを渡していることに注意してください(部分ビュー内の`@vars(:book)`からアクセスすることができます)。再び、スコープの`context`(コントローラオブジェクト)を渡しています。

次に`app/resources/books/views/`に`book.jl.html`を作ります。
例えば

```julia
julia> touch("app/resources/books/views/book.jl.html")
```

このコンテンツをそれに追加します。
TO BE CONTINUED


#### ビューヘルパー

#### Flax要素の利用
