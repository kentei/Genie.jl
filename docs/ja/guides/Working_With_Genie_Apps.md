# Genieアプリ(プロジェクト)の操作

対話型環境でGenieを操作することは便利な場合がありますが、大抵の場合、アプリケーションを永続化し、セッション間で再利用したいことが多いです。これを成し遂げるための1つの方法がIJuliaノートブックとして保存し、セルを再実行することです。

しかしながら、Genieアプリで操作することでGenieを最大限活用できます。GeneiアプリはMVC(Model-View-Contoroller)構造のWebアプリケーションで、「設定より規約を重視する」(convention-over-configuration,CoC)の原則を促進している。Genieアプリの構造内でいくつかの定義済みファイルを操作することで、フレームワークはたくさんの重大な内容を解決し、開発生産性を大幅に向上することができる。しかし、Genieのワークフローに従うと、自動モジュールのロードと再ロード、専用の設定ファイル、ロギング、環境のサポート、コードジェネレータ、キャッシュ、Genieプラグインのサポートなどのような機能がすぐに利用できます。

新規でGenieアプリを生成するために、`Genie.newapp($app_name)`を実行する必要があります。

```julia
julia> Genie.newapp("MyGenieApp")
```

上記コマンドが実行されれば、Genieは以下を実施する。

* `MyGenieApp`という名前の新しいディレクトリを作成し、`cd()`で中に移動する
* アプリの依存関係をすべてインストールする
* 新しいJuliaプロジェクトを生成する(`Project.toml`と`Manifest.toml`ファイルを追加)
* プロジェクトをアクティブな状態にする
* REPL内に新しいアプリの環境を自動的にロードする
* Genieのデフォルトホスト(127.0.0.1)とポート(8000)でWebサーバを起動する

この時点で、任意のWebブラウザで<http://127.0.0.1:8000>にアクセスすると、期待した通りにすべてが動作することを確認できます。Genieのウェルカムページが表示されます。

次に新しいルート(route)を追加してみましょう。ルートはJulia関数にリクエストURLをマッピングするために使われます。これらの関数はクライアントに返信される応答を提供します。ルートはそれ専用の`routes.jl`ファイルで定義されます。エディタで`MyGenieApp/routes.jl`を開くか、以下のコマンドを実行してください。(カレントディレクトリがアプリのディレクトリであることを確認してください)

```julia
julia> edit("routes.jl")
```

`routes.jl`ファイルの下方に以下のコードを追加し保存してください。

```julia
# routes.jl
route("/hello") do
  "Genieへようこそ！"
end
```

`route`メソッドを利用し、`/hello`URLと「Genieへようこそ！」という文字列を返す匿名関数を渡します。これは、`/hello`URLへの各リクエストに対して、アプリがルートハンドラ関数を呼び出し、ウェルカムメッセージをレスポンスするということです。

<http://127.0.0.1:8000/hello>にアクセスして温かい歓迎を受けてください！

## リソースの操作

コードを`routes.jl`ファイルに追加することは、Web上で機能をすばやく公開したい小規模なプロジェクトには最適です。しかし、大規模なプロジェクトの場合、GenieのMVC構造を利用するほうが適切です（MVCはModel-View-Controllerの略です）。MVCデザインパターンを採用することで、コードを明確な責任をもったモジュールに分割することができます。というのも、モデル(Model)はデータのアクセスに利用され、ビュー(View)はクライアントへのレスポンスをレンダリングし、コントローラ(Controller)はモデルとビュー間の相互作用を調整し、リクエストを操作します。モジュール単位のコードはコーディング、テスト、保守がより簡単になります。

Genieアプリは「リソース」の概念に基づいて設計できます。リソースはビジネスエンティティ(ユーザ、製品、アカウントなど)を表し、一連のファイル(コントローラ、モデル、ビューなど)に対応します。リソースは`app/resources/`フォルダ配下にあり、各リソースにはそれぞれ専用のフォルダがあり、すべてのファイルが配置されています。例えば、「書籍」についてのWebアプリがある場合、「書籍」リソース用のフォルダは`app/resources/books`にあり、Web上に書籍を公開するためのファイルはすべてこのフォルダに含まれます。(大抵の場合、コントローラには`BooksController.jl`、モデルには`Books.jl`、モデルの検証ツール(バリデータ)には`BooksValidator.jl`となります。なお、書籍データのレンダリングに必要なビューファイルは`views`フォルダに配置します。)

---
**注意喚起**

デフォルトのGenieアプリを生成する際、`app/`フォルダが見つからない場合があります。Genieのジェネレータを介してリソースを一度追加すると、自動的に生成されます。

---

## コントローラの利用

コントローラは、クライアントリクエスト、モデル(データアクセス処理)、ビュー(クライアントのWebブラウザに送られるレスポンスのレンダリングを担当)間の対話を調整するために利用されます。標準のワークフローでは、`route`はコントローラ内のメソッドを指します。ネットワークを介してレスポンスを生成して、クライアントに送信する役割を果たします。

「書籍」コントローラを追加してみましょう。Genieにはお手軽なジェネレータが収録されており、そのうちの一つが新しいコントローラを作るためのものです。

### コントローラの生成

`BooksController`を生成してみましょう。

```julia
julia> Genie.newcontroller("Books")
[info]: New controller created at ./app/resources/books/BooksController.jl
```

素晴らしい！`BooksController.jl`を編集して(`julia> edit("./app/resources/books/BooksController.jl")`)、何かを追加してみましょう。例えば、ビルゲイツのおすすめ本をいくつか返す機能が便利でしょう。`BooksController.jl`が以下のようになっていることを確認してください。

```julia
# app/resources/books/BooksController.jl
module BooksController

struct Book
  title::String
  author::String
end

const BillGatesBooks = Book[
  Book("The Best We Could Do", "Thi Bui"),
  Book("Evicted: Poverty and Profit in the American City", "Matthew Desmond"),
  Book("Believe Me: A Memoir of Love, Death, and Jazz Chickens", "Eddie Izzard"),
  Book("The Sympathizer", "Viet Thanh Nguyen"),
  Book("Energy and Civilization, A History", "Vaclav Smil")
]

function billgatesbooks()
  "
  <h1>Bill Gates' list of recommended books</h1>
  <ul>
    $(["<li>$(book.title) by $(book.author)</li>" for book in BillGatesBooks]...)
  </ul>
  "
end

end
```

コントローラは単なる`Julia`モジュールで、`Book`型/構造と書籍オブジェクトの配列を設定しています。そして、`billgatesbooks`という関数を定義しています。この関数は、`H1`見出しとすべての書籍の番号なしリストを含むHTML文字列を返します。配列内包表記を利用して各書籍を反復処理し、`<li>`要素でレンダリングしています。配列の要素はsplat展開(`...`演算子)を用いて連結されています。計画ではこの関数をルートに紐づけて、インターネット上に公開します。

#### チェックポイント

Web上に公開する前に、REPL上で関数をテストすることができます。

```julia
julia> using BooksController

julia> BooksController.billgatesbooks()
```

関数呼び出しの出力は、以下のようなHTML文字列です。

```julia
"\n  <h1>Bill Gates' list of recommended books</h1>\n  <ul>\n    <li>The Best We Could Do by Thi Bui</li><li>Evicted: Poverty and Profit in the American City by Matthew Desmond</li><li>Believe Me: A Memoir of Love, Death, and Jazz Chickens by Eddie Izzard</li><li>The Sympathizer by Viet Thanh Nguyen</li><li>Energy and Civilization, A History by Vaclav Smil</li>\n  </ul>\n"
```

期待通り動作しているか確認してください。

### ルートのセットアップ

では、`billgatebooks`メソッドをWeb上に公開してみましょう。それを指し示す新しい`route`が必要です。`routes.jl`ファイルに以下を追加しましょう。

```julia
# routes.jl
using Genie.Router
using BooksController

route("/bgbooks", BooksController.billgatesbooks)
```

このスニペットでは、`using BooksController`を宣言(Genieはファイルの場所知っているため、ファイルの場所を明示的に含める必要はありません)し、`/bgbooks`と`BooksController.billgatesbooks`関数の間に`route`を定義します。(`BooksController.billgatesbooks`は`/bgbooks`URLまたはendpointに対するルートハンドラであると言います。)

ここまでですべてです! <http://localhost:8000/bgbooks>にアクセスすると、ビルゲイツの推薦書籍の一覧が表示されます。(まぁ少なくともそれらのうちいくつかを、人はよく読みます!)

---
**プロのヒント**

HTML文字列の代わりにJuliaを利用したい場合、Genieの`Html`APIを利用することができます。すべての標準HTML要素を紐づける関数を提供します。例えば、`BooksController.billgatesbooks`関数はHTML要素の配列として以下のように書くことができます。

```julia
using Genie.Renderer.Html

function billgatesbooks()
  [
    Html.h1() do
      "Bill Gates' list of recommended books"
    end
    Html.ul() do
      @foreach(BillGatesBooks) do book
        Html.li() do
          book.title * " by " * book.author
        end
      end
    end
  ]
end
```

`@foreach`マクロはコレクションを反復処理し、各ループの出力をループの結果に連結します。それについてはこの後すぐに説明します。

---

### ビューの追加

ただ、HTMLをコントローラに置くことは良い考えとは言えません。HTMLは専用のビューファイルに記載し、できる限りロジックを少なくするべきです。代わりにビューを利用するようにコードをリファクタリングしてみましょう。

リソースのレンダリングに利用されるビューは、リソース自体のフォルダ内にある`views/`フォルダに配置されるべきです。そのため今回のケースでは、`app/resources/books/views`フォルダを追加します。そのまま先に進んでください。Genieはこのタスク用のジェネレータを提供していません。

```julia
julia> mkdir(joinpath("app", "resources", "books", "views"))
"app/resources/books/views"
```

`app/resources/books/`フォルダ内に`views/`フォルダを生成しました。REPLがアプリのルートフォルダで実行されるため、フルパスを指定しました。また、Juilaがクロスプラットフォームでパスを作成するように、`joinpath`関数を使用します。

### ビューの名づけ

通常、各コントローラメソッドには独自のレンダリングロジックがあります。それゆえに、独自のビューファイルがあります。したがって、ビューファイルにメソッドと同じ名前をつけることをお勧めします。ビューファイルがどこで使われているか追跡できるからです。

現状、Genieは標準のJuliaと同じくらいにHTMLとMarkdownビューファイルをサポートしています。それらの種類はファイルの拡張子で区別されるため、拡張子は重要な要素です。HTMLビューは`.jl.html`拡張子を利用しており、Markdownファイルは`.jl.md`拡張子を、Juliaファイルは`.jl`を利用します。

### HTMLビュー

それでは、 `BooksController.billgatesbooks`メソッドの最初のビューファイルを追加してみましょう。JuliaでHTMLビューファイルを生成してみましょう。

```julia
julia> touch(joinpath("app", "resources", "books", "views", "billgatesbooks.jl.html"))
```

GenieはJuilaコードの埋め込みが可能な特殊な形式の動的HTMLビューをサポートしています。これらは高性能のコンパイル済みビューです。それらは文字列として解析されません。代わりに、**HTMLはネイティブなJuliaレンダリングコードに変換され、ファイルすシステムにキャッシュされ、他のJuliaファイルと同じようにロードされます。**
したがって、ビューを初めてロードするとき、または変更した後は、特定の遅延を感じるかもしれません。それはビューの生成、コンパイル、ロードに必要な時間です。次回の実行では、非常に高速になります!(特に本番環境)

ここで必要なのは、HTMLコードをコントローラから移動し、書籍の数も表示するように少し改善することです。ビューファイルは以下のように編集します。(修正方法：`julia> edit("app/resources/books/views/billgatesbooks.jl.html")`)

```html
<!-- billgatesbooks.jl.html -->
<h1>Bill Gates' top $(length(books)) recommended books</h1>
<ul>
  <% @foreach(books) do book %>
    <li>$(book.title) by $(book.author)</li>
  <% end %>
</ul>
```

見た通り、Juliaが埋め込まれた標準のHTMLです。`<% ... %>`コードブロックタグを利用することでJuliaコードを追加できます。これらは、より複雑な複数行の式に利用されるべきです。またはシンプルに値を出力するために`$（...）`でJuliaを用いた文字列挿入をします。

HTML生成をより効率的に行うため、Genieはヘルパー群を提供します。例えば、上記の`@foreach`マクロはコレクションを反復処理し、現在のアイテムを処理関数に渡します。

---
**注意喚起**

**GenieビューはHTML文字列をレンダリングすることで機能することを気に留めておくことは非常に重要です。したがって、Juliaビューコードは結果として文字列を返す必要があり、処理の出力がページ上に表示されます。**Juliaが最後の処理の結果を自動で返すため、ほとんどの場合これは自然に進みます。ただし、テンプレートが期待したものを出力しないと気づいた場合は、コードが文字列(または文字列に変換することができる何か)を返すことを確認してください。

---

### ビューのレンダリング

ここで、ビューを使用するようにコントローラーをリファクタリングし、期待された変数を渡す必要があります。レスポンスをHTMLとしてレンダリングし出力する`html`メソッドを使用します。以下のように`billgatesbooks`関数の定義を更新してください。

```julia
# BooksController.jl
using Genie.Renderer.Html

function billgatesbooks()
  html(:books, :billgatesbooks, books = BillGatesBooks)
end
```

まず、`html`メソッドへのアクセスをするために、依存関係として`Genie.Renderer.Html`を追加する必要があることに注意してください。`html`メソッドに関しては、リソースの名前、ビューファイルの名前、そしてビュー変数を表すキーワード引数の一覧を引数として取ります。

* `:books`はリソースの名前です。(どのviewsフォルダでGenieがビューファイルを検索するかを示します。今回のケースでは`app/resources/books/views`となります)
* `:billgatesbooks`はビューファイルの名前です。拡張子を渡す必要はありません。この名前のファイルは一つしかないため、Genieは判断できます
* そして最後に、ビューで公開したい値をキーワード引数として渡します

それだけです。リファクタリングされたアプリは準備済みです。<http://localhost:8000/bgbooks>で試してみてください。

### Markdown views

MarkdownビューはHTMLビューと同じように動作し、同じく組み込まれたJuliaの機能を使用します。`billgatebooks`関数にMarkdownビューを追加する方法を示していきます。

初めに、`.jl.md`拡張子を利用することで、対応するビューファイルを生成しましょう。おそらく以下のやり方になるでしょう。

```julia
julia> touch(joinpath("app", "resources", "books", "views", "billgatesbooks.jl.md"))
```

ここで、ファイルを編集し、以下のようになることを確認してください。

```md
<!-- app/resources/books/views/billgatesbooks.jl.md -->
# Bill Gates' $(length(books)) recommended books

$(
  @foreach(books) do book
    "* $(book.title) by $(book.author) \n"
  end
)
```

MarkdownビューはGenieの埋め込みJuilaタグである`<% ... %>`をサポートしていないことに注意してください。文字列挿入の`$(...)`のみ使用できますが、複数行に渡って機能します。

現状、ページをリロードすると、GenieはまだHTMLビューをロードします。その理由は、ビューファイルが1つしかない場合はGenieが管理しますが、複数ある場合はGenieはどれを選択すればよいか判断できないためです。エラーは発生しませんが、優先バージョン(HTMLバージョン)が選択されるのです。

`BookiesController`に簡単な変更を実施します。Genieに対してロードするファイル、拡張子などを明示的に指定します。

```julia
# BooksController.jl
function billgatesbooks()
  html(:books, "billgatesbooks.jl.md", books = BillGatesBooks)
end
```

### レイアウトを活用

Genieのビューはレイアウトファイル内でレンダリングされます。レイアウトはWebサイトのテーマ、またはビュー周りの「フレーム」をレンダリングするものです。これは、すべてのページに共通する要素です。レイアウトファイルは、メインメニューやフッターなどの様々な要素を含んでいます。`<head>`タグまたはそれに関連するタグ(`<link>`タグや`<script>`タグなどCSSやJavaScriptをページ全体で読み込むためのもの)も含むでしょう。


すべてのGenieアプリはデフォルトで利用するメインレイアウトファイルがあります。これは`app/layouts/`にあり、`app.jl.html`という名前です。内容は以下の通りです。

```html
<!-- app/layouts/app.jl.html -->
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Genie :: The highly productive Julia web framework</title>
    <!-- link rel="stylesheet" href="/css/application.css" / -->
  </head>
  <body>
    <%
      @yield
    %>
    <!-- script src="/js/application.js"></script -->
  </body>
</html>
```

これを修正していきましょう。例として、`<body>`開始タグの真下(`<%`タグの真上)に以下を追記します。

```html
<h1>Welcome to top books</h1>
```

<http://localhost:8000/bgbooks>でページをリロードすると、新たなヘッダを確認できます。

しかし、デフォルトで我慢する必要はありません。レイアウトは追加できます。例えば完全に異なるテーマとするべき管理ページがあるとしましょう。それ専用のレイアウトを追加します。

```julia
julia> touch(joinpath("app", "layouts", "admin.jl.html"))
"app/layouts/admin.jl.html"
```

ここで上記ファイルを編集します。(編集コマンド：`julia> edit("app/layouts/admin.jl.html")`)　以下のように修正します。

```html
<!-- app/layouts/admin.jl.html -->
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Genie Admin</title>
  </head>
  <body>
    <h1>Books admin</h1>
    <%
      @yield
    %>
  </body>
</html>
```

適用したい場合は、`BooksController`で上記を利用するように命令する必要があります。`html`関数でレイアウトファイルを指定するための`layout`という名前のキーワード引数を取るようにします。`billgatesbooks`関数を以下のように更新してみましょう。

```julia
# BooksController.jl
function billgatesbooks()
  html(:books, :billgatesbooks, books = BillGatesBooks, layout = :admin)
end
```

ページを更新することで、新たなヘッダが表示されます。

#### `@yield`命令

レイアウトには`@yield`という特殊な命令があります。それは、コントローラを介してレンダリングされたビューの内容を出力します。そのため、このマクロが存在する場合、Genieはコントローラ内のルートハンドラ関数を実行することで、ビューをレンダリングした結果のHTMLを出力します。

#### ビューパスの利用

非常にシンプルなアプリケーションの場合、MVCやリソース中心のアプローチでは、あまりに多くの定型文を含みすぎているかもしれません。そのようなケースでは、ファイルパスでビュー(またはレイアウト)を参照することでコードを簡素化できます。

```julia
# BooksController.jl
using Genie.Renderer

function billgatesbooks()
  html(path"app/resources/books/views/billgatesbooks.jl.html", books = BillGatesBooks, layout = path"app/layouts/app.jl.html")
end
```

### JSONビューのレンダリング

Webアプリの一般的なユースケースは、RESTful APIのバックエンドとして動作することです。今回の場合、JSONは優先度の高いデータ形式です。GenieはJSONレスポンスのサポートを組み込んでいるので喜んでもらえるのではないでしょうか。APIのエンドポイントを追加しましょう。この対応でビルゲイツの本がJSONとしてレンダリングされるようになります。

`routes.jl`ファイルで、以下を追加することからスタートしましょう。

```julia
route("/api/v1/bgbooks", BooksController.API.billgatesbooks)
```

次に、`BooksController.jl`で、ファイルの最下方にある`end`の前に追加処理を追記します。ファイル全体は以下のようになります。

```julia
# BooksController.jl
module BooksController

using Genie.Renderer.Html

struct Book
  title::String
  author::String
end

const BillGatesBooks = Book[
  Book("The Best We Could Do", "Thi Bui"),
  Book("Evicted: Poverty and Profit in the American City", "Matthew Desmond"),
  Book("Believe Me: A Memoir of Love, Death, and Jazz Chickens", "Eddie Izzard"),
  Book("The Sympathizer!", "Viet Thanh Nguyen"),
  Book("Energy and Civilization, A History", "Vaclav Smil")
]

function billgatesbooks()
  html(:books, :billgatesbooks, layout = :admin, books = BillGatesBooks)
end


module API

using ..BooksController
using Genie.Renderer.Json

function billgatesbooks()
  json(BooksController.BillGatesBooks)
end

end

end
```

`BooksController`モジュールの中にAPIモジュールをネストさせました。そこで、JSONを出力する別の`billgatesbooks`関数を定義しました。

<http://localhost:8000/api/v1/bgbooks>にアクセスすると、期待通りに動作します。

#### JSON views

しかしながら、API開発のきわめて重大な過ちの1つをコミットしてしまっています。内部データ構造を外部表現に永続的に結合していることです。これにより、将来のリファクタリングが非常に複雑となり、データ変更を加えることでクライアントとの結合を壊れるためにエラーが発生しやすくなります。解決策としては、ビューを使用して、データのレンダリング方法を完全に制御し、Web上でのレンダリングからデータ構造を切り離すことです。

GenieはJSONビューをサポートしています。これらは、「.json.jl」という拡張子をもつ標準のJuliaファイルです。`views`フォルダに1つ追加してみましょう。

#### JSONビュー

しかし、API開発のきわめて重大な過ちの1つをコミットしてしまいました。 私たちは内部データ構造を外部表現に永続的に結合してしまっています。 これにより、将来のリファクタリングが非常に複雑になり、エラーが発生しやすくなります。データに変更を加えると、クライアントの統合が壊れるからです。 解決策は、やはりビューを使用して、データのレンダリング方法を完全に制御し、データ構造をWebでのレンダリングから切り離すことです。

GenieはJSONビューをサポートしています。これらは ".json.jl"拡張子を持つ簡単なJuliaファイルです。 `views /`フォルダーに追加しましょう：

```julia
julia> touch(joinpath("app", "resources", "books", "views", "billgatesbooks.json.jl"))
"app/resources/books/views/billgatesbooks.json.jl"
```

ここで、適切な応答を作成します。 以下をビューファイルに追加します。

```julia
# app/resources/books/views/billgatesbooks.json.jl
"Bill Gates' list of recommended books" => books
```

最後のステップは、ビューをレンダリングするように`BooksController`に命令することです。`API`サブモジュール内の既存の`billgatesbooks`関数を以下のように置き換えるだけです。

```julia
function billgatesbooks()
  json(:books, :billgatesbooks, books = BooksController.BillGatesBooks)
end
```

これは驚くほどの事ではありません。`json`関数は以前見た`html`関数に似ています。今はカスタムJSONレスポンスをレンダリングしています。ここまでですべてが機能します。

---
**注意喚起**

#### なぜJSONビューの拡張子の終わりには`.jl`がついていて、HTMLビューやMarkdownビューにはついていないのか?

良い質問です! ビューの拡張子はIDE/コードエディタ内で正しい構文のハイライト表示を維持するために選ばれています。

HTMLビューとMarkdownビューは、Juliaコードが埋め込まれたHTMLファイルとMarkdownファイルであるため、HTMLまたはMarkdown構文のハイライト表示を使用します。JSONビューの場合は、純正のJuliaを利用するため、Julia構文のハイライト表示を使用します。

---

## `SeachLight`モデルでデータベースに接続

シームレスなオブジェクト関係マッピング(ORM)レイヤーであるSearchLightとGenieを組み合わせることで、Genieを最大限に活用できます。ネイティブJulia ORMであるSearchLightは、リレーショナルデータベースでの作業に素晴らしいサポートを提供します。Genie + SearchLightコンボはCRUD(Create-Read-Update-Delete)アプリを生産的に開発するために利用できます。

---
**注意喚起**

CRUDはCreate-Read-Update-Deleteの略称で、リソースの作成、読み込み(一覧化)、更新、削除を行う多くのWebアプリのデータワークフローを表しています。

---

SearchLightはGenieのMVC基盤の「M」部分(モデル層)を表現します。

GenieアプリにSearchLightを追加してみましょう。すべてのGenieアプリは`Project.toml`と`Manifest.toml`ファイルを通して、アプリ独自のJulia環境で依存関係を管理しています。

そのため、最初に`pkg>`シェルモードであることを確認する必要があります。(Juliaモードで`]`を入力すると、シェルモードに入ります。(すなわち`julia>]`)
カーソルが`(MyGenieApp) pkg>`に変わります。

次に、`SearchLight`を追加します。

```julia
(MyGenieApp) pkg> add SearchLight
```

### データベースアダプタの追加

`SearchLight`は様々なバックエンド(現時点では、MySQL,SQLite,Postgres)を操作するためのデータベースに依存しないAPIを提供します。したがって、特定のアダプタも追加する必要があります。シンプルさを維持するため、アプリにSQLiteを使いましょう。ゆえに、`SearchLightSQLite`パッケージが必要になります。

```julia
(MyGenieApp) pkg> add SearchLightSQLite
```

### データベース接続のセットアップ

GenieはSearchLightとシームレスに結合するように設計されており、様々なデータベース指向のジェネレータへのアクセスを提供します。はじめに、Genie/SearchLightにデータベースへの接続方法を伝える必要があります。データベースサポートを設定するためにそれらを利用してみましょう。Genie/Julia REPLで以下を実行します。

```julia
julia> Genie.Generator.db_support()
```

コマンドはアプリのルートディレクトリ内に`db/`フォルダを追加します。データベースへの接続の方法をSearchLightに伝えるための`db/connection.yml`ファイルを探索します。それを編集してみましょう。以下のようにファイルを修正します。

```yaml
env: ENV["GENIE_ENV"]

dev:
  adapter: SQLite
  database: db/books.sqlite
  config:
```

これはSearchLightに対して、現在のGenieアプリの環境(デフォルトは`dev`)で動作し、アダプタ(バックエンド)として`SQLight`を利用し、データベースは`db/books.sqlite`(存在しない場合は自動で作成される)で保存するように命令しています。`config`オブジェクト内で追加の設定オプションを渡すこともできますが、今は何も必要ありません。

---
**注意喚起**

他のアダプタを利用している場合、設定済みのデータベースがすでに存在し、設定済みのユーザがそのデータベースに正常にアクセスできることを確認してください。SearchLightはデータベースの作成を試みることはしません。

---

ここまでで、SearchLightにロードするよう要求ができます。

```julia
julia> using SearchLight

julia> SearchLight.Configuration.load()
Dict{String,Any} with 4 entries:
  "options"  => Dict{String,String}()
  "config"   => nothing
  "database" => "db/books.sqlite"
  "adapter"  => "SQLite"
```

次に進んで、データベースに接続してみましょう。

```julia
julia> using SearchLightSQLite

julia> SearchLight.Configuration.load() |> SearchLight.connect
SQLite.DB("db/books.sqlite")
```

The connection succeeded and we got back a SQLite database handle.
接続が成功し、SQLiteデータベースハンドルが返されました。

---
**プロのヒント**

各データベースアダプタは、接続情報にアクセスできる`CONNECTIONS`コレクションを公開します。

```julia
julia> SearchLightSQLite.CONNECTIONS
1-element Array{SQLite.DB,1}:
 SQLite.DB("db/books.sqlite")
```

---

素晴らしい！　すべてが順調であれば、`db/`フォルダ内に`books.sqlite`データベースがあります。

```julia
shell> tree db
db
├── books.sqlite
├── connection.yml
├── migrations
└── seeds
```

### `SearchLight`マイグレーションでデータベーススキーマを管理

データベースの移行は、スキーマ変換を確実かつ一貫して繰り返し適用する(元に戻す)方法を提供します。それらはデータベースのテーブルを追加、削除、変更するための特別なスクリプトです。これらのスクリプトはバージョン管理化におかれ、実行されたスクリプトと実行されなかったスクリプトを認識し、正しい順番でスクリプトを実行できる専用のシステムで管理されます。

SearchLightはマイグレーションの状態を追跡しつづけるために独自のデータベーステーブルを必要とします。それを設定してみましょう。

```julia
julia> SearchLight.Migrations.create_migrations_table()
[ Info: Created table schema_migrations
```

このコマンドは移行を管理するために必要なテーブルをデータベースに設定します。

---
**プロのヒント**

SearchLight APIを利用して、データベースバックエンドに対してランダムクエリを実行できます。例えばテーブルが実際にあることを確認することができます。

```julia
julia> SearchLight.query("SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%'")
┌ Info: SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%'
└

1×1 DataFrames.DataFrame
│ Row │ name              │
│     │ String⍰           │
├─────┼───────────────────┤
│ 1   │ schema_migrations │
```

結果はおなじみの `DataFrame`オブジェクトです。

---

### Bookモデルの作成

Genietと同様に、SearchLightはConvention-over-Configuration設計パターンを利用します。それは大規模な構成ファイルの中ですべてを定義する必要はなく、特定の方法で設定することを好み、実用的なデフォルトを提供します。そして幸いにも、SearchLightには豊富なジェネレータ一式が付属しているため、これらの規則を覚える必要さえありません。

新しいモデルを作成するようにSearchLightに依頼してみましょう。

```julia
julia> SearchLight.Generator.newmodel("Book")

[ Info: New model created at /Users/adrian/Dropbox/Projects/MyGenieApp/app/resources/books/Books.jl
[ Info: New table migration created at /Users/adrian/Dropbox/Projects/MyGenieApp/db/migrations/2020020909574048_create_table_books.jl
[ Info: New validator created at /Users/adrian/Dropbox/Projects/MyGenieApp/app/resources/books/BooksValidator.jl
[ Info: New unit test created at /Users/adrian/Dropbox/Projects/MyGenieApp/test/books_test.jl
```

SearchLightは`Books.jl`モデルと、`*_create_table_books.jl`マイグレーションファイル、`BooksValidator.jl`モデルバリデータ、`books_test`テストファイルを作成します。

---
**注意喚起**

移行ファイルの最初の部分はあなたのものとは異なります。

名前の前半部分はファイル作成のタイムスタンプであるため、`*_create_table_books.jl`ファイルには別の名前がつけられます。このタイムスタンプ部分は、名前はユニークで、ファイル競合を回避することを保証します。(例えばチームとで作業していて似たような移行ファイルを作成する場合)

---

#### テーブルマイグレーションの記載

booksテーブルを作成するため、マイグレーションを記述してみましょう。SearchLightはマイグレーションを記載するために強力なDSLを提供します。各マイグレーションファイルは2つのメソッドを定義する必要があります。1つは変更を適用する`up`メソッド、もう1つはその`up`メソッドの効果を元に戻す`down`メソッドです。そのため、`up`メソッドはテーブルを生成し、`down`メソッドはテーブルを削除します。

SearchLightのテーブルの命名規則では、テーブル名を複数形(例：`books`)にする必要があります。なぜなら、テーブルには複数の本(books)が含まれるためです(各行はオブジェクト"book"を表現しています)　。しかし、心配することはありません。マイグレーションファイルは正しいテーブル名で既に入力されているからです。

`db/migrations/*_create_table_books.jl`ファイルを編集して、以下のようにしてください。

```julia
module CreateTableBooks

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:books) do
    [
      primary_key()
      column(:title, :string, limit = 100)
      column(:author, :string, limit = 100)
    ]
  end

  add_index(:books, :title)
  add_index(:books, :author)
end

function down()
  drop_table(:books)
end

end
```

DSLはとても読みやすいです。`up`関数内で`create_table`を呼び、列の配列を渡します。主キー、`title`列と`author`列(両方とも文字列は最大長100文字)です。また、2つのインデックス(1つは`title`列で、もう一方は`author`列)を追加します。`down`メソッドは、テーブルを削除するために`drop_table`関数を呼びます。

#### マイグレーションの実行

`SearchLight.Migrations.status`コマンドでSearchLightがマイグレーションについてわかっていることを確認します。

```julia
julia> SearchLight.Migrations.status()
|   | Module name & status                   |
|   | File name                              |
|---|----------------------------------------|
|   |                 CreateTableBooks: DOWN |
| 1 | 2020020909574048_create_table_books.jl |
```

マイグレーションは`down`状態です。つまり、`up`メソッドはまだ実行されていません。これは簡単に直せます。

```julia
julia> SearchLight.Migrations.last_up()
[ Info: Executed migration CreateTableBooks up
```

再びチェックすると、マイグレーションがupとなります。

```julia
julia> SearchLight.Migrations.status()
|   | Module name & status                   |
|   | File name                              |
|---|----------------------------------------|
|   |                   CreateTableBooks: UP |
| 1 | 2020020909574048_create_table_books.jl |
```

テーブルが準備できました！

#### モデルの定義

今度は、`app/resources/books/Books.jl`のモデルファイルを修正するときです。SearchLightの他の規則は、モジュールに複数形の名前(`Books`)を利用していることです。なぜなら、複数の本を管理するためのものだからです。その中で`Book`という名の型(`可変構造体(mutable struct)`)を定義します。基盤となるデータベースの行に割り当てるアイテム(単一の本)を表現します。

`Books.jl`ファイルを修正して、以下のようにしてください。

```julia
# Books.jl
module Books

using SearchLight

export Book

mutable struct Book <: AbstractModel
  ### INTERNALS
  _table_name::String
  _id::String

  ### FIELDS
  id::DbId
  title::String
  author::String
end

Book(;
    ### FIELDS
    id = DbId(),
    title = "",
    author = ""
  ) = Book("books", "id", id, title, author)

end
```

前の`Book`型と一致する`butable struct`を定義しましたが、それ以外にSearchLightによって内部的に利用されるいくつか特別なフィールドがあります。アンダースコアで始まるフィールドはテーブル名と主キー列の名前を参照します。SearchLightが必要とする時は、キーワードコンストラクタも定義します。

#### モデルの利用

もっと興味深くするために、データベースに現在の本をインポートする必要があります。`Books.jl`モジュールの`Book()`コンストラクタ定義の下(モジュールの`end`のちょうど上)に、この関数を追加してください。

```julia
# Books.jl
function seed()
  BillGatesBooks = [
    ("The Best We Could Do", "Thi Bui"),
    ("Evicted: Poverty and Profit in the American City", "Matthew Desmond"),
    ("Believe Me: A Memoir of Love, Death, and Jazz Chickens", "Eddie Izzard"),
    ("The Sympathizer!", "Viet Thanh Nguyen"),
    ("Energy and Civilization, A History", "Vaclav Smil")
  ]

  for b in BillGatesBooks
    Book(title = b[1], author = b[2]) |> SearchLight.save!
  end
end
```

#### データベース設定の自動読み込み

実際に試してみます。Genieはアプリを読み込む際、すべてのリソースファイルを読み込みます。これを実施するため、Genieはデータベースの設定を自動で読み込み、SearchLightをセットアップするイニシャライザと呼ばれる特別なファイルを備えています。`config/initializers/searchlight.jl`を確認してください。それは以下のようになっています。

```julia
using SearchLight

SearchLight.Configuration.load()
eval(Meta.parse("using SearchLight$(SearchLight.config.db_config_settings["adapter"])"))
SearchLight.connect()
```

---
**注意喚起!**

`config/initializers/`フォルダの中に配置された`*.jl`ファイルのすべてはGenieアプリ起動時にGenieによって自動的にインクルードされます。それらはコントローラ、モデル、ビューが読み込まれるより前の初期化時にインクルードされます。

---

#### 試してみる

REPLセッションを再開して、アプリをテストしてみましょう。Julia REPLセッションを閉じて、OSコマンドラインに戻り、以下のコマンドを実行します。

```bash
$ bin/repl
```

アプリの`bin/`フォルダに配置された`repl`実行可能スクリプトは新たなJulia REPLセッションを開始し、アプリケーションの環境を読み込みます。すべてが自動的に読み込まれ、データベース設定がインクルードされます。以前定義したbooksを挿入する`seed`関数を呼び出します。

```julia
julia> using Books

julia> Books.seed()
```

データがデータベースに挿入される方法を示すクエリの一覧があります。

```julia
julia> Books.seed()
[ Info: INSERT  INTO books ("title", "author") VALUES ('The Best We Could Do', 'Thi Bui')
[ Info: INSERT  INTO books ("title", "author") VALUES ('Evicted: Poverty and Profit in the American City', 'Matthew Desmond')
# output truncated
```

すべてがうまくいったことを確認したければ、挿入結果を取得するようにSearchLightに要求します。

```julia
julia> using SearchLight

julia> all(Book)
[ Info: 2020-02-09 13:29:32 SELECT "books"."id" AS "books_id", "books"."title" AS "books_title", "books"."author" AS "books_author" FROM "books" ORDER BY books.id ASC

5-element Array{Book,1}:
 Book
| KEY            | VALUE                |
|----------------|----------------------|
| author::String | Thi Bui              |
| id::DbId       | 1                    |
| title::String  | The Best We Could Do |

 Book
| KEY            | VALUE                                            |
|----------------|--------------------------------------------------|
| author::String | Matthew Desmond                                  |
| id::DbId       | 2                                                |
| title::String  | Evicted: Poverty and Profit in the American City |

# output truncated
```

`SearchLight.all`メソッドはデータベースからすべての`Book`アイテムを返します。

すべてうまくいきました！

次に、モデルを利用するためにコントローラを更新する必要があります。`app/resources/books/BooksController.jl`を以下のようになっているか確認してください。

```julia
# BooksController.jl
module BooksController

using Genie.Renderer.Html, SearchLight, Books

function billgatesbooks()
  html(:books, :billgatesbooks, books = all(Book))
end

module API

using ..BooksController
using Genie.Renderer.Json, SearchLight, Books

function billgatesbooks()
  json(:books, :billgatesbooks, books = all(Book))
end

end

end
```

JSONビューも少しだけ調整が必要です。

```julia
# app/resources/books/views/billgatesbooks.json.jl
"Bill's Gates list of recommended books" => [Dict("author" => b.author, "title" => b.title) for b in books]
```

サーバを起動すれば、データベースから提供される本の一覧を表示できるようになります。

```julia
# Start the server
julia> up()
```

`up`メソッドはWebサーバを起動し、対話型のJulia REPLプロンプトに戻ります

例えば、<http://localhost:8000/api/v1/bgbooks>に移動した場合、出力結果は以下のJSONドキュメントと一致します。

```json
{
  "Bill's Gates list of recommended books": [
    {
      "author": "Thi Bui",
      "title": "The Best We Could Do"
    },
    {
      "author": "Matthew Desmond",
      "title": "Evicted: Poverty and Profit in the American City"
    },
    {
      "author": "Eddie Izzard",
      "title": "Believe Me: A Memoir of Love, Death, and Jazz Chickens"
    },
    {
      "author": "Viet Thanh Nguyen",
      "title": "The Sympathizer!"
    },
    {
      "author": "Vaclav Smil",
      "title": "Energy and Civilization, A History"
    }
  ]
}
```

その動き方を確認するために新しい本を追加してみましょう。新たな`Book`アイテムを生成し、`SearchLight.save!`メソッドを利用してそれを永続化します。

```julia
julia> newbook = Book(title = "Leonardo da Vinci", author = "Walter Isaacson")

Book
| KEY            | VALUE             |
|----------------|-------------------|
| author::String | Walter Isaacson   |
| id::DbId       | NULL              |
| title::String  | Leonardo da Vinci |


julia> save!(newbook)

[ Info: INSERT  INTO books ("title", "author") VALUES ('Leonardo da Vinci', 'Walter Isaacson')
[ Info: ; SELECT CASE WHEN last_insert_rowid() = 0 THEN -1 ELSE last_insert_rowid() END AS id
[ Info: SELECT "books"."id" AS "books_id", "books"."title" AS "books_title", "books"."author" AS "books_author" FROM "books" WHERE "id" = 6 ORDER BY books.id ASC

Book
| KEY            | VALUE             |
|----------------|-------------------|
| author::String | Walter Isaacson   |
| id::DbId       | 6                 |
| title::String  | Leonardo da Vinci |
```

`save!`メソッドを呼び出すことで、SearchLightはデータベースにオブジェクトを永続化し、それを取得して返しました(`id::DbId`が更新されたことに注意してください)。

同じように`save!`操作はワンライナーで書くことができます。

```julia
julia> Book(title = "Leonardo da Vinci", author = "Walter Isaacson") |> save!
```

---
**HEADS UP**

ワンライナーの`save!`例を実行する場合、」同じ本が再び追加されます。問題はありませんが、それを消したい場合は`delete`メソッドを利用します。

```julia
julia> delete(ans)
[ Info: DELETE FROM books WHERE id = '7'

Book
| KEY            | VALUE             |
|----------------|-------------------|
| author::String | Walter Isaacson   |
| id::DbId       | NULL              |
| title::String  | Leonardo da Vinci |
```

---

<http://localhost:8000/bgbooks>のページをリロードすると、新しい本が表示されます。

```json
{
  "Bill's Gates list of recommended books": [
    {
      "author": "Thi Bui",
      "title": "The Best We Could Do"
    },
    {
      "author": "Matthew Desmond",
      "title": "Evicted: Poverty and Profit in the American City"
    },
    {
      "author": "Eddie Izzard",
      "title": "Believe Me: A Memoir of Love, Death, and Jazz Chickens"
    },
    {
      "author": "Viet Thanh Nguyen",
      "title": "The Sympathizer!"
    },
    {
      "author": "Vaclav Smil",
      "title": "Energy and Civilization, A History"
    },
    {
      "author": "Walter Isaacson",
      "title": "Leonardo da Vinci"
    }
  ]
}
```

---
**プロのヒント**

SearchLightは、2つの似たようなデータ永続化メソッドである`save!`と`save`を公開します。それらは両方とも同じ動作(データベースにオブジェクトを永続化)をしますが、`save`メソッドは操作が成功したことを示す`Bool`型の`true`を、または失敗したことを示す`Bool`型の`false`を返します。一方で`save!`は成功すると永続化オブジェクトを返し、失敗すると例外をスローします。

---

## おめでとうございます

段階的なウォークスルーの最初のパートを無事終わらせることができました。Genieの基本をマスターし、新しいアプリのセットアップ、ルート登録、リソース(コントローラ、モデル、ビュー)の追加、データベースサポートの追加、マイグレーションを伴うデータベーススキーマバージョン管理、SearchLightでの基本的なクエリ実行が可能となりました！

次のパートでは、フォームやファイルのアップロード、テンプレートによるレンダリング、対話型の処理など、より高度なトピックを見ていきます。
