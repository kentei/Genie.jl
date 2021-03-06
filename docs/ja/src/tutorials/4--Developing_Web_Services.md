# Genie Webサービスの開発

REPLでアドホック(その場限りな)Webサービスを起動し、マイクロサービスをラップする小さなスクリプトを作成することは非常に効率的ではありますが、製品版アプリは非常に早く複雑になる傾向があります。また、それらにはより厳しい要件があり、例えば依存関係の管理、アセットの圧縮、コードのリロード、ロギング、環境、またはチームで作業する際の効率的なワークフローを促進する方法としてのコードベースの構造化のようなものが挙げられます。

Genieアプリは、依存関係の管理とバージョン管理(GenieアプリがJuliaアプリであることから、Juliaの`Pkg`を利用)から、強力なアセットパイプライン(YarnやWebpackのような業界で検証済みのツールを利用)、開発中の自動コードリロード(`Revise.jl`が提供)、明確なリソース指向であるMVCレイアウトまで、これらすべての機能を提供します。

Genieはアプリの構築に向けてモジュール式アプローチを可能とし、必要に応じてコンポーネントを追加することができます。Webサービステンプレート(依存関係の管理、ロギング、環境、ルーティングを含む)で構築を開始することができ、データベースの永続性(SearchLight ORMを利用)、Juilaに組み込まれた高パフォーマンスのHTMLビューテンプレート(Flaxを利用)、アセットパイプラインやコンパイルなどを順次追加することによってアプリを成長させることができます。

## Genie Web Serviceプロジェクトのセットアップ

Genieは、アプリケーションの様々な部分のブートストラップやセットアップに役立つ便利なジェネレータ機能とテンプレートを収録しています。新しいアプリをブートストラップするには、`newapp`群内の関数の1つを呼び出す必要があります。

```julia
julia> using Genie

julia> Genie.newapp_webservice("MyGenieApp")
```

REPLのログメッセージを参照すると、コマンドが新しいプロジェクトをセットアップするために一度にたくさんのアクションのトリガーになっています。

- `MyGenieApp/`という新しいフォルダを作成します。このフォルダはアプリのファイル置き場を提供しており、フォルダの名前はアプリの名前に対応します。
- `MyGenieApp/`フォルダ内で、アプリに必要なファイルやフォルダーを作成します。
- アクティブディレクトリを`MyGenieApp/`に変更し、その中で新しいJuliaプロジェクトを作成します。(`Project.toml`ファイルを追加)
- 新しいGenieアプリに必要な依存関係をすべてインストールします。(`Pkg`と標準の`Manifest.toml`ファイルを利用)
- 最後にWebサーバを起動します。

---
**ヒント**

`Genie.newapp`、` Genie.newapp_webservice`、 `Genie.newapp_mvc`、` Genie.newapp_fullstack`のインラインヘルプで、アプリケーションのブートストラップに使用できるオプションを確認してください。 さまざまな構成については、今後のセクションで説明します。

---

## ファイル構成

新規作成したWebサービスのファイル構成は以下のとおりです。

```julia
├── Manifest.toml
├── Project.toml
├── bin
├── bootstrap.jl
├── config
├── genie.jl
├── log
├── public
├── routes.jl
└── src
```

ファイルやフォルダにそれぞれ役割があります。

- `Manifest.toml`と`Project.toml`はアプリの依存関係を管理するためにJuliaと`Pkg`に利用されます。
- `bin/`フォルダにはGenie REPLまたはGenieサーバを起動するためのスクリプトが含まれています。
- `bootstrap.jl`、`genie.jl`、および`src/`フォルダ内のファイルはすべてのファイルはアプリケーションをロードするためにGenieによって利用されています。(ユーザは編集しないでください)
- `config/`フォルダには環境ごとの設定ファイルが含まれています。
- `log/`フォルダは環境ごとのログファイルを保管するためにGenieによって利用されます。
- `public/`フォルダはドキュメントルートで、ネットワーク/インターネット上のアプリによって公開される静的ファイルを含んでいます。
- `routes.jl`はGenieのルートを登録するための専用ファイルです。

---
**注意喚起**

アプリを新規作成した後、`routes.jl`のようなファイルの編集/保存を許可するために、ファイルのアクセス権を変更する必要があります。

---

## ロジックの追加

`routes.jl`ファイルを編集し、ファイルの下部にいくつかロジックを追加してみましょう。

```julia
route("/hello") do
  "Welcome to Genie!"
end
```

<http://127.0.0.1:8000/hello>に接続すると、温かい挨拶を受けるでしょう。

## アプリの成長

GenieアプリはJuilaプロジェクトでしかありません。つまり、`routes.jl`は他のJuilaスクリプトと同様に動作するということです。例えば、追加パッケージを参照したり、`pkg>`モードに切り替えてプロジェクトごとの依存関係を管理したり、他のファイルを含めたりするなど色々なことができます。

GenieアプリにすぐにロードしたいJuliaコードがある場合、アプリのルートに `lib/`フォルダを追加し、Juliaファイルを配置することができます。利用可能な場合、`lib/`フォルダとそのすべてのサブフォルダはGenieによって再帰的に`LOAD_PATH`に自動追加されます。

データベースの対応を追加する必要がある場合は、アプリのREPLで `julia> Genie.Generator.db_support()`を実行し、専用のジェネレーターを利用することでSearchLight ORMをいつでも追加できます。

しかしながら、アプリの複雑さが増し、ゼロから開発する場合は、Genieのリソース指向であるMVC構造を活用する方が効率的です。
