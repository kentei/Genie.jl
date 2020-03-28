# 高度なルーティング技術

Genieのルータは、アプリの頭脳とみなされます。それはWebリクエストを機能と照合し、リクエストの変数と実行環境を抽出、設定し、レスポンスメソッドを呼び出します。このような能力にはルートを定義するための強力な機能セットが必要となります。これらの機能を見ていきましょう。

## 静的ルーティング

最もシンプルなケースから始めると、`route`メソッドを利用することで「プレーン」なルートを登録することができます。そのメソッドは、URIパターンとレスポンスを返すために必要な関数を必須引数として扱います。ルータは、ルートを登録する2つの方法をサポートしており、`route(pattern::String, f::Function)`または`route(f::Function, pattern::String)`が挙げられます。一番目の構文は関数参照を渡すためのもので、二番目はインライン関数を定義するためのものです。

### 例

以下のスニペットは「Genieへようこそ！」という文字列を返す`greet`関数を定義しています。`route`メソッドへ第二引数としてその関数を渡すことで、ルートハンドラとして関数を利用します。

```julia
using Genie, Genie.Router

greet() = "Genieへようこそ!"

route("/greet", greet)          # [GET] /greet => greet

up() # start the server
```

ブラウザで<http://127.0.0.1:8000/greet>へ移動すると、コードの動きを確認できます。

しかし、このようなシンプルなケースでは、専用のハンドラ関数を用意するのはやりすぎかもしれません。そのため、Genieではインラインハンドラを登録できます。

```julia
route("/bye") do
  "さようなら!"
end                 # [GET] /bye => getfield(Main, Symbol("##3#4"))()
```

<http://127.0.0.1:8000/bye>に移動すると、すぐにアプリでルート(route)を利用することができます。

---
**注意喚起**

ルートは定義された順に追加されますが、最新のものから最古のものまで一致させます。つまり、以前に定義したルートを上書くための新しいルートを定義できるということです。

Juliaの複数のディスパッチとは異なり、Genieのルータは具体的なルートではなく、最初に一致したルートに一致します。したがって、例えば`/*`に一致するようにルートを登録すると、以前により具体的なルートを定義していたとしても、すべてのリクエストを処理します。補足としてですが、この手法を利用して、一時的にすべてのユーザをメンテナンスページに誘導することができます。

---

## 動的ルーティング(ルートパラメータの利用)

静的ルーティングは固定URLに最適です。しかし、コンポーネントがバックエンドの情報(データベースのIDなど)に対応づいており、各リクエストで異なる動的URLである場合はどうでしょうか？例えば、`/customers/57943/orders/458230`(顧客ID:57943、注文ID:458230)のようなURLをどのように処理するかです。

このような場合、動的ルーティングまたはルートパラメータによって処理されます。以前の例`/customers/57943/orders/458230`では、動的ルートを`/customers/:customer_id/orders/:order_id`として定義できます。リクエストに一致すると、ルータは値を展開し、それらを`@params`コレクションに公開します。

### 例

```julia
using Genie, Genie.Router, Genie.Requests

route("/customers/:customer_id/orders/:order_id") do
  "顧客$(payload(:customer_id))の注文$(payload(:order_id))に対して尋ねました。"
end

up()
```

## ルーティングモジュール(`GET`、`POST`、`PUT`、`PATCH`、`DELETE`、`OPTIONS`)

最も一般的なリクエストであるということから、デフォルトでルート(route)は`GET`リクエストを処理します。他の種類のリクエストメソッドを処理するためのルートを定義するために、HTTPメソッドを示す`method`キーワード引数を渡す必要があります。Genieのルータは`GET`、`POST`、`PUT`、`PATCH`、`DELETE`、`OPTIONS`メソッドをサポートしています。

ルータは`Router.GET`、`Router.POST`、`Router.PUT`、`Router.PATCH`、`Router.DELETE`、`Router.OPTIONS`のように各メソッドに対して定数を定義しエクスポートします。

### 例

以下、`PATCH`ルートを設定します。

```julia
using Genie, Genie.Router, Genie.Requests

route("/patch_stuff", method = PATCH) do
  "Stuff to patch"
end

up()
```

そして`HTTP`パッケージを利用してテストします。

```julia
using HTTP

HTTP.request("PATCH", "http://127.0.0.1:8000/patch_stuff").body |> String
2019-08-19 14:23:46:INFO:Main: /patch_stuff 200

"Stuff to patch"
```

`PATCH`メソッドでリクエストを送信することにより、ルートがトリガーされます。その結果、レスポンスボディにアクセスし、レスポンスに対応する「Stuff to patch」という文字列に変換します。

## 名前付きルート

Genieでは名前でルートにタグ付けをすることができます。これは、ルートに対する動的URLのために、`Router.tolink`メソッドと組み合わせて利用される非常に強力な機能です。この手法の利点は、名前によってルートを参照し`tolink`を使用して動的リンクを生成する場合、ルートの名前が一致している限り、ルートパターンを変えたとしてもすべてのURLが新しいルート定義に自動的に一致することです。

ルートに名前をつけるには、`named`キーワード引数を利用する必要があり、これには`Symbol`が必要です。

### 例

```julia
using Genie, Genie.Router, Genie.Requests

route("/customers/:customer_id/orders/:order_id", named = :get_customer_order) do
  "Looking up order $(payload(:order_id)) for customer  $(payload(:customer_id))"
end         #  [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
```

ルートの状態をチェックします。

```julia
julia> @routes
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 1 entry:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
```

---
**注意喚起**

一貫性のため、Genieはすべてのルートに名前をつけます。ただし、自動生成された名前は状態に依存します。そのため、ルートを変更した場合、名前も変更される可能性があります。したがって、アプリ全体で参照する場合はルートに明示的に名前をつけておくのが最善であると言えます。

---

匿名ルートの追加によるルートの状態変化を確認します。

```julia
route("/foo") do
  "foo"
end  #  [GET] /foo => getfield(Main, Symbol("##7#8"))()

julia> @routes
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 2 entries:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
  :get_foo            => [GET] /foo => getfield(Main, Symbol("##7#8"))()
```

新しいルートはメソッドとURIパターンに基づいて、自動的に`get_foo`と名づけられています。

## ルート(routes)へのリンク

`linkto`メソッドを介して、ルートにリンクするためにルート名が使用できます。

### 例

以前定義済みの2つのルートから始めてみましょう。

```julia
julia> @routes
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 2 entries:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
  :get_foo            => [GET] /foo => getfield(Main, Symbol("##7#8"))()
```

`：get_foo`のような静的ルートは簡単にリンクを向けることができます。

```julia
julia> linkto(:get_foo)
"/foo"
```

動的なルートの場合、キーワード引数として各パラメータの値を渡す必要があるため、少しだけ複雑です。

```julia
julia> linkto(:get_customer_order, customer_id = 1234, order_id = 5678)
"/customers/1234/orders/5678"
```

`linkto`はリンクを生成するためにHTMLコードと組み合わせて使用されます。すなわち、以下のようになります。

```html
<a href="$(linkto(:get_foo))">Foo</a>
```

## ルートの一覧

`Router.routes`で登録されているルートをいつでも確認できます。

```julia
julia> routes()
2-element Array{Genie.Router.Route,1}:
 [GET] /foo => getfield(Main, Symbol("##7#8"))()
 [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
```

または、前述の`@routes`マクロも利用できます。

```julia
julia> @routes
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 2 entries:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
  :get_foo            => [GET] /foo => getfield(Main, Symbol("##7#8"))()
```

### `Route`型

ルートは4つのフィールドをもつ`Route`型によって内部的に表現されています。

* `method::String`- ルートのメソッドを保持するため(`GET`や`POST`など)
* `path::String` - 照合するURIパターンを表現
* `action::Function` - ルートが一致した際に実行されるルートハンドラ
* `name::Union{Symbol,Nothing}` - ルートの名前

## ルートの削除

`delete!`メソッドを呼び出し、ルートのコレクションと削除対象のルートの名前をわたすことで、スタックからルートを削除できます。そのメソッドは(残りの)ルートのコレクションを返します。

### 例

```julia
julia> @routes
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 2 entries:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##3#4"))()
  :get_foo            => [GET] /foo => getfield(Main, Symbol("##9#10"))()

julia> Router.delete!(@routes, :get_foo)
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 1 entry:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##3#4"))()

julia> @routes
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 1 entry:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##3#4"))()
```

## 引数の型によるルートの一致

デフォルトでは、ルートパラメータは`SubString {String}`として`payload`コレクションの中で解析されます。

```julia
using Genie, Genie.Router, Genie.Requests

route("/customers/:customer_id/orders/:order_id") do
  "Order ID has type $(payload(:order_id) |> typeof) // Customer ID has type $(payload(:customer_id) |> typeof)"
end
```

上記は、`Order ID has type SubString{String} // Customer ID has type SubString{String}`と出力されます。

しかし、今回のような場合、明示的な変換(数字のみマッチなど)を回避するために`Int`型のデータとして受け取ることが非常に好まれます。Genieは、ルートパラメータに型アノテーションの指定を許すことでこのようなワークフローをサポートします。

```julia
route("/customers/:customer_id::Int/orders/:order_id::Int", named = :get_customer_order) do
  "Order ID has type $(payload(:order_id) |> typeof) // Customer ID has type $(payload(:customer_id) |> typeof)"
end     #     [GET] /customers/:customer_id::Int/orders/:order_id::Int => getfield(Main, Symbol("##3#4"))()
```

`:customer_id`と`:order_id`に、`:customer_id::Int`および`:order_id::Int`という形式で型アノテーションを追加していることに注意してください。

ただし、<http://127.0.0.1:8000/customers/10/orders/20>にアクセスしようとすると失敗します。

```julia
Failed to match URI params between Int64::DataType and 10::SubString{String}
MethodError(convert, (Int64, "10"), 0x00000000000063fe)
/customers/10/orders/20 404
```

見た通り、Genieは型をデフォルトの`SubString{String}`から`Int`に変換しようとしています。しかし、その方法がわかりません。そのため失敗し、他に一致するルートを見つけられず`404 Not Found`を返しています。

### ルートでの型変換

エラーは簡単に対処できます。`SubString{String} `から` Int`への型変換器を提供する必要があります。

```julia
Base.convert(::Type{Int}, v::SubString{String}) = parse(Int, v)
```

一度`Base`内で、その変換器を登録すれば、リクエストは正しく処理され、その結果`Order ID has type Int64 // Customer ID has type Int64`となります。

## 個々のURIセグメントの一致

完全一致のルートだけでなく、Genieは個々のURIセグメントでの一致をサポートしています。つまり、さまぁまなルートパラメータが特定のパターンに従うよう強制します。ルートパラメータの制約を導入するためには、ルートパラメータの末尾に`#pattern`を追加します。

### 例

例えば、`mywebsite.com/en`、`mywebsite.com/es`、`mywebsite.com/de`のようなURL構造を持つローカライズされたWebサイトを実装してみましょう。動的ルートを定義し、ロケール変数を抽出することで、ローカライズされたコンテンツを提供することができます。

```julia
route(":locale", TranslationsController.index)
```

これは非常にうまく機能し、リクエストを照合し、`payload(:locale)`変数内のコードにロケール情報を渡します。しかし、それはとても貪欲で、静的ファイル(`mywebsite.com/favicon.ico`等)のようなものを含むすべてのリクエストにほとんどが一致します。以下のようにパターン(正規表現パターン)を追加することで、`:locale`変数が一致できるものを制限できます。

```julia
route(":locale#(en|es|de)", TranslationsController.index)
```

リファクタリングされたルートは、`:locale`は`en`、`es`、`de`のどれか一文字列にのみ一致します。

---
**注意喚起**

アプリケーションのロジックを重複させないように気を付けてください。サポート済みのロケールの配列があれば、そのパターンを動的に生成するのに利用できます。ルートを完全に動的生成することができます。

```julia
const LOCALE = ":locale#($(join(TranslationsController.AVAILABLE_LOCALES, '|')))"

route("/$LOCALE", TranslationsController.index, named = :get_index)
```

---

## `@params`コレクション

ルータが現在のリクエストのすべてのパラメータを`@params`コレクション(`Dict{Symbol, Any}`型)に入れていることは知っておくとよいです。これはルートパラメータ、クエリパラメータ、POSTペイロード、オリジナルHTTP,RequestとHTTP.Responseオブジェクトなどの貴重な情報が含まれています。一般的に、直接`@params`コレクションにアクセスするのではなく、`Genie.Requests`と`Genie.Responses`で定義されたユーティリティメソッドを介してアクセスすることを推奨します。ただし、`@params`について知っていることは、上級ユーザにとって役に立つでしょう。
