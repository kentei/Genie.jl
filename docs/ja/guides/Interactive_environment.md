# 対話型環境でのGenieの利用(Jupyter/IJulia、REPLなど)

Genieはアドホックな探索的プログラミングに利用することで、Webサーバを迅速に立ち上げたり、自作のJulia関数を公開することができます。

一度`Genie`をスコープに入れると、新たな`route`を定義できます。`route`はURLを関数に関連付けます。

```julia
julia> import Genie.Router: route
julia> route("/") do
         "Hi there!"
       end
```

ここで使用するWebサーバを起動します。

```julia
julia> Genie.startup()
```

<http://localhost:8000>にアクセスすると、「Hi there！」というメッセージが確認できます。


より複雑なURIを定義でき、前に定義した関数に関連付けることができます。

```julia
julia> function hello_world()
         "Hello World!"
       end
julia> route("/hello/world", hello_world)
```

(上記で)明らかなように、関数は現在のスコープでアクセス可能である限り、どこにでも(他のモジュール内でも)定義できます。

現状、ブラウザで<http://localhost:8000/hello/world>にアクセスできるようになっています。

もちろん、GETパラメータにもアクセスできます。

```julia
julia> import Genie.Router: @params
julia> route("/echo/:message") do
         @params(:message)
       end
```

<http://localhost:8000/echo/ciao>にアクセスすると、`ciao`と出力されます。

また型で一致させることもできます。

```julia
julia> route("/sum/:x::Int/:y::Int") do
         @params(:x) + @params(:y)
       end
```

デフォルトでは、GETパラメータは`SubString`(より正確には`SubString{String}`)型として抽出されます。型の制約が追加されると、Genieは`SubString`を指定された型への変換を試みます。

上記が機能するためには、Genieに変換の実行方法を伝えることも必要です。

```julia
julia> import Base.convert
julia> convert(::Type{Int}, s::SubString{String}) = parse(Int, s)
```

ここで、<http://localhost:8000/sum/2/3>にアクセスすると、`5`と表示されます。

## クエリ文字列パラメータの処理

`...?foo=bar&baz=2`のようなクエリ文字列パラメータは、Genieによって自動的に解凍され、`@params`コレクションに配置されます。例は以下の通りです。

```julia
julia> route("/sum/:x::Int/:y::Int") do
         @params(:x) + @params(:y) + parse(Int, get(@params, :initial_value, "0"))
       end
```

ここで、<http://localhost:8000/sum/2/3?initial_value=10>にアクセスすると、`15`と出力されます。
