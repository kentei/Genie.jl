# Genieアプリに既存Juliaコードの追加

既存のJuliaコード(モジュールとライブラリ)があり、アプリをゼロから構築せずにWeb上ですぐに公開したい場合、Genieはアプリにコードを追加したり読み込んだりする簡単な方法を提供します。

## JuliaコードをGenieアプリに追加

既存のJuliaアプリケーションまたはスタンドアローンのコードベースがあり、Genieアプリを介してWeb上で公開した場合、最もシンプルなのはファイルを`lib/`フォルダーに追加することです。`lib/`フォルダはGenieによって再帰的に`LOAD_PATH`に自動で追加されます。

つまり、`lib/`フォルダ配下にフォルダを追加することもでき、それらが再帰的に`LOAD_PATH`に追加されるということです。ただし、これはGenieアプリが最初にロードされた時にのみ発生することに注意してください。したがって、アプリの起動後にネストされたフォルダを追加する場合は、アプリの再起動が必要になることもあります。

---
**注意喚起**

ほとんどの場合、Genieはデフォルトで`lib/`フォルダを生成しません。アプリのルートに`lib/`フォルダが存在しない場合は、自身で作成するようにしてください。

```julia
julia> mkdir("lib")
```

---

一度コードが`lib/`フォルダに追加されると、アプリから利用可能になります。例として、`lib/MyLib.jl`を追加してみましょう。

```julia
# lib/MyLib.jl
module MyLib

using Dates

function isitfriday()
  Dates.dayofweek(Dates.now()) == Dates.Friday
end

end
```

次に、`routes.jl`で上記ライブラリを参照し、以下のようにWeb上で公開してみましょう。

```julia
# routes.jl
using Genie.Router
using MyLib

route("/friday") do
  MyLib.isitfriday() ? "Yes, it's Friday!" : "No, not yet :("
end
```

Genieが既存のJuliaコードをロードするために探す場所を知り、アプリケーションを介してコードを利用可能とできるように、コードの置き場所として`lib/`フォルダを利用してください。
