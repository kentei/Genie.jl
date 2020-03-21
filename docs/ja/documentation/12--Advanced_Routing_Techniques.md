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

ルートに名前をつけるには、`named`キーワード引数を利用する必要があり、これには`Symbolが必要です`

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

## Links to routes

We can use the name of the route to link back to it through the `linkto` method.

### Example

Let's start with the previously defined two routes:

```julia
julia> @routes
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 2 entries:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
  :get_foo            => [GET] /foo => getfield(Main, Symbol("##7#8"))()
```

Static routes such as `:get_foo` are straightforward to target:

```julia
julia> linkto(:get_foo)
"/foo"
```

For dynamic routes, it's a bit more involved as we need to supply the values for each of the parameters, as keyword arguments:

```julia
julia> linkto(:get_customer_order, customer_id = 1234, order_id = 5678)
"/customers/1234/orders/5678"
```

The `linkto` should be used in conjunction with the HTML code for generating links, ie:

```html
<a href="$(linkto(:get_foo))">Foo</a>
```

## Listing routes

At any time we can check which routes are registered with `Router.routes`:

```julia
julia> routes()
2-element Array{Genie.Router.Route,1}:
 [GET] /foo => getfield(Main, Symbol("##7#8"))()
 [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
```

Or, we can use the previously discussed `@routes` macro:

```julia
julia> @routes
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 2 entries:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
  :get_foo            => [GET] /foo => getfield(Main, Symbol("##7#8"))()
```

### The `Route` type

The routes are represented internally by the `Route` type which has 4 fields:

* `method::String` - for storing the method of the route (`GET`, `POST`, etc)
* `path::String` - represents the URI pattern to be matched against
* `action::Function` - the route handler to be executed when the route is matched
* `name::Union{Symbol,Nothing}` - the name of the route

## Removing routes

We can delete routes from the stack by calling the `delete!` method and passing the collection of routes and the name of the route to be removed. The method returns the collection of (remaining) routes

### Example

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

## Matching routes by type of arguments

By default route parameters are parsed into the `payload` collection as `SubString{String}`:

```julia
using Genie, Genie.Router, Genie.Requests

route("/customers/:customer_id/orders/:order_id") do
  "Order ID has type $(payload(:order_id) |> typeof) // Customer ID has type $(payload(:customer_id) |> typeof)"
end
```

This will output `Order ID has type SubString{String} // Customer ID has type SubString{String}`

However, for such a case, we'd very much prefer to receive our data as `Int` to avoid an explicit conversion -- _and_ to match only numbers. Genie supports such a workflow by allowing type annotations to route parameters:

```julia
route("/customers/:customer_id::Int/orders/:order_id::Int", named = :get_customer_order) do
  "Order ID has type $(payload(:order_id) |> typeof) // Customer ID has type $(payload(:customer_id) |> typeof)"
end     #     [GET] /customers/:customer_id::Int/orders/:order_id::Int => getfield(Main, Symbol("##3#4"))()
```

Notice how we've added type annotations to `:customer_id` and `:order_id` in the form `:customer_id::Int` and `:order_id::Int`.

However, attempting to access the URL `http://127.0.0.1:8000/customers/10/orders/20` will fail:

```julia
Failed to match URI params between Int64::DataType and 10::SubString{String}
MethodError(convert, (Int64, "10"), 0x00000000000063fe)
/customers/10/orders/20 404
```

As you can see, Genie attempts to convert the types from the default `SubString{String}` to `Int` -- but doesn't know how. It fails, can't find other matching routes and returns a `404 Not Found` response.

### Type conversion in routes

The error is easy to address though: we need to provide a type converter from `SubString{String}` to `Int`.

```julia
Base.convert(::Type{Int}, v::SubString{String}) = parse(Int, v)
```

Once we register the converter in `Base`, our request will be correctly handled, resulting in `Order ID has type Int64 // Customer ID has type Int64`

## Matching individual URI segments

Besides matching the full route, Genie also allows matching individual URI segments. That is, enforcing that the various route parameters obey a certain pattern. In order to introduce constraints for route parameters we append `#pattern` at the end of the route parameter.

### Example

For instance, let's assume that we want to implement a localized website where we have a URL structure like: `mywebsite.com/en`, `mywebsite.com/es` and `mywebsite.com/de`. We can define a dynamic route and extract the locale variable to serve localized content:

```julia
route(":locale", TranslationsController.index)
```

This will work very well, matching requests and passing the locale into our code within the `payload(:locale)` variable. However, it will also be too greedy, virtually matching all the requests, including things like static files (ie `mywebsite.com/favicon.ico`). We can constrain what the `:locale` variable can match, by appending the pattern (a regex pattern):

```julia
route(":locale#(en|es|de)", TranslationsController.index)
```

The refactored route only allows `:locale` to match one of `en`, `es`, and `de` strings.

---
**HEADS UP**

Keep in mind not to duplicate application logic. For instance, if you have an array of supported locales, you can use that to dynamically generate the pattern -- routes can be fully dynamically generated!

```julia
const LOCALE = ":locale#($(join(TranslationsController.AVAILABLE_LOCALES, '|')))"

route("/$LOCALE", TranslationsController.index, named = :get_index)
```

---

## The `@params` collection

It's good to know that the router bundles all the parameters of the current request into the `@params` collection (a `Dict{Symbol,Any}`). This contains valuable information, such as route parameters, query params, POST payload, the original HTTP.Request and HTTP.Response objects, etcetera. In general it's recommended not to access the `@params` collection directly but through the utility methods defined by `Genie.Requests` and `Genie.Responses` -- but knowing about `@params` might come in handy for advanced users.
