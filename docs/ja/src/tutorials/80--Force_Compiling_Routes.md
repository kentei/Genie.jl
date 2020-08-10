# Genieルートの強制コンパイル

アプリケーション起動時に、JuliaはコードをJITコンパイルするため、特定のルートへの初回到達時に、Juliaはリクエストを処理する役割を担った関数をコンパイルする必要があります。これは、最初のリクエストが解決されるまでに多くの秒数がかかる可能性があることを示唆しています。それは本番環境では受け入れられないことかもしれません。このような場合のため、一度定義されたルートにアクセスするためにGenie自体を利用し、コンパイルをトリガーすることができます。

ここでは、2つの`Get`ルートを定義し、アプリケーション起動時にそれらを自動的にトリガーする簡単なスクリプトを示します。

```julia
using Genie, Genie.Router, Genie.Requests, Genie.Renderer.Json

route("/foo") do
  json(:foo => "Foo")
end

route("/bar") do
  json(:bar => "Bar")
end


function force_compile()
  sleep(5)

  for (name, r) in Router.named_routes()
    Genie.Requests.HTTP.request(r.method, "http://localhost:8000" * tolink(name))
  end
end

@async force_compile()

up(async = false)
```

上記スニペットでは、2つのルートを定義しています。 次に、ルートを反復してWebサーバ経由でヒットする関数`force_compile`を追加します。 次に、その関数を呼び出します。この関数は、Webサーバが起動するのに十分な5秒の遅延で実行されます。