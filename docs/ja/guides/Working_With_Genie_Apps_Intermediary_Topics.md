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

Looking good - lets ask SearchLight to run it:

```julia
julia> SearchLight.Migration.last_up()
[debug] Executed migration AddCoverColumn up
```

If you want to double check, ask SearchLight for the migrations status:

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

Perfect! Now we need to add the new column as a field to the `Books.Book` model:

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

As a quick test we can extend our JSON view and see that all goes well - make it look like this:

```julia
# app/resources/books/views/billgatesbooks.json.jl
"Bill's Gates list of recommended books" => [Dict("author" => b.author,
                                                  "title" => b.title,
                                                  "cover" => b.cover) for b in @vars(:books)]
```

If we navigate <http://localhost:8000/api/v1/bgbooks> you should see the newly added "cover" property (empty, but present).

##### Heads up!

Sometimes Julia/Genie/Revise fails to update `structs` on changes. If you get an error saying that `Book` does not have a `cover` field, please restart the Genie app.

### File uploading

Next step, extending our form to upload images (book covers). Please edit the `new.jl.html` view file as follows:

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

The new bits are:

* we added a new attribute to our `<form>` tag: `enctype="multipart/form-data"`. This is required in order to support files payloads.
* there's a new input of type file: `<input type="file" name="book_cover" />`

You can see the updated form by visiting <http://localhost:8000/bgbooks/new>

Now, time to add a new book, with the cover! How about "Identity" by Francis Fukuyama? Sounds good.
You can use whatever image you want for the cover, or maybe borrow the one from Bill Gates, I hope he won't mind <https://www.gatesnotes.com/-/media/Images/GoodReadsBookCovers/Identity.png>.
Just download the file to your computer so you can upload it through our form.

Almost there - now to add the logic for handling the uploaded file server side. Please update the `BooksController.create` method to look like this:

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

Also, very important, you need to make sure that `BooksController` is `using Genie.Requests`.

Regarding the code, there's nothing very fancy about it. First we check if the files payload contains an entry for our `book_cover` input.
If yes, we compute the path where we want to store the file, write the file, and store the path in the database.

**Please make sure that you create the folder `covers/` within `public/img/`**.

Great, now let's display the images. Let's start with the HTML view - please edit `app/resources/books/views/billgatesbooks.jl.html` and make sure it has the following content:

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

Basically here we check if the `cover` property is not empty, and display the actual cover. Otherwise we show a placeholder image.
You can check the result at <http://localhost:8000/bgbooks>

As for the JSON view, it already does what we want - you can check that the `cover` property is now outputted, as stored in the database: <http://localhost:8000/api/v1/bgbooks>

Success, we're done here!



#### Heads up!

In production you will have to make the upload code more robust - the big problem here is that we store the cover file as it comes from the user which can lead to name clashes and files being overwritten - not to mention security vulnerabilities.
A more robust way would be to compute a hash based on author and title and rename the cover to that.

### One more thing...

So far so good, but what if we want to update the books we have already uploaded? It would be nice to add those missing covers.
We need to add a bit of functionality to include editing features.

First things first - let's add the routes. Please add these two new route definitions to the `routes.jl` file:

```julia
route("/bgbooks/:id::Int/edit", BooksController.edit)
route("/bgbooks/:id::Int/update", BooksController.update, method = POST, named = :update_book)
```

We defined two new routes. The first will display the book object in the form, for editing. While the second will take care of actually updating the database, server side.
For both routes we need to pass the id of the book that we want to edit - and we want to constrain it to an `Int`. We express this as the `/:id::Int/` part of the route.

We also want to:

* reuse the form which we have defined in `app/resources/books/views/new.jl.html`
* make the form aware of whether it's used to create a new book, or for editing an existing one respond accordingly by setting the correct `action`
* pre-fill the inputs with the book's info when editing a book.

OK, that's quite a list and this is where things become interesting. This is an important design pattern for CRUD web apps.
So, are you ready, cause here is the trick: in order to simplify the rendering of the form, we will always pass a book object into it.
When editing a book it will be the book corresponding to the `id` passed into the `route`. And when creating a new book, it will be just an empty book object we'll create and then dispose of.

#### Using view partials

First, let's set up the views. In `app/resources/books/views/` please create a new file called `form.jl.html`.
Then, from `app/resources/books/views/new.jl.html` cut the `<form>` code. That is, everything between the opening and closing `<form>...</form>` tags.
Paste it into the newly created `form.jl.html` file. Now, back to `new.jl.html`, instead of the previous `<form>...</form>` code add:

```julia
<% partial("app/resources/books/views/form.jl.html", context = @__MODULE__) %>
```

This line, as the `partial` function suggests, includes a view partial, which is a part of a view file, effectively including a view within another view. Notice that we're explicitly passing the `context` so Genie can set the correct variable scope when including the partial.

You can reload the `new` page to make sure that everything still works: <http://localhost:8000/bgbooks/new>

Now, let's add an Edit option to our list of books. Please go back to our list view file, `billgatesbooks.jl.html`.
Here, for each iteration, within the `@foreach` block we'll want to dynamically link to the edit page for the corresponding book.

##### `@foreach` with view partials

However, this `@foreach` which renders a Julia string is very ugly - and we now know how to refactor it, by using a view partial.
Let's do it. First, replace the body of the `@foreach` block:

```html
<!-- app/resources/books/views/billgatesbooks.jl.html -->
"""<li><img src='$( isempty(book.cover) ? "img/docs.png" : book.cover )' width="100px" /> $(book.title) by $(book.author)"""
```

with:

```julia
partial("app/resources/books/views/book.jl.html", book = book, context = @__MODULE__)
```

Notice that we are using the `partial` function and we pass the book object into our view, under the name `book` (will be accessible in `@vars(:book)` inside the view partial). Again, we're passing the scope's `context` (our controller object).

Next, create the `book.jl.html` in `app/resources/books/views/`, for example with

```julia
julia> touch("app/resources/books/views/book.jl.html")
```

Add this content to it:
TO BE CONTINUED


#### View helpers

#### Using Flax elements
