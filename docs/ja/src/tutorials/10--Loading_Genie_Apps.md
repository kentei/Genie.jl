# Genieアプリのロードと起動

At any time, you can load and serve an existing Genie app. Loading a Genie app will bring into scope all your app's files, including the main app module, controllers, models, etcetera.

## MacOS / LinuxでのGenie REPLの起動

推奨されるアプローチは、プロジェクトのルートフォルダにて、OSシェルで`bin/repl`を実行し、Genie環境で対話型REPLを開始することです。

```sh
$ bin/repl
```

アプリの環境がロードされます。

Webサーバを起動するために、次のコマンドを実行します。

```julia
julia> up()
```

サーバを直接開始したい場合は、`bin/repl`の代わりに`bin/server`を利用してください。

```sh
$ bin/server
```

上記により、Webサーバが自動的に非対話モードで起動します。

最後に、`bin/serverinteractive`を代わりに利用することで、サーバを起動し対話型REPLに落とし込むオプションがあります。

## WindowsでのGenie REPLの起動

Windowsでは、ワークフローはmacOSやLinuxと似ていますが、Windows専用のスクリプトである`repl.bat`、`server.bat`、`serverinteractive.bat`が、プロジェクトフォルダ内の`bin/`フォルダに含む形で提供されています。それらをダブルクリックするか、OSシェル(コマンドプロンプトまたはPowerShell)で実行することで、前の段落で説明したように、対話型REPLセッションまたはサーバセッションを開始します。

---
**注意喚起**

Windowsの実行可能ファイル`repl.bat`、` server.bat`、および`serverinteractive.bat`が存在しない可能性があります。(この現象が発生するのは通常、アプリがLinux/Macで生成され、Windowsコンピュータに移植された場合です) Genie/Julia REPLで以下のジェネレーターを実行するといつでも作成できます。(場所はGenieプロジェクトのルート)

```julia
julia> using Genie

julia> Genie.Generator.setup_windows_bin_files()
```

あるいは、プロジェクトのパスを引数として`setup_windows_bin_files`に渡すことができます。

```julia
julia> Genie.Generator.setup_windows_bin_files("path/to/your/Genie/project")
```

## Juno / Jupyter / その他のJulia環境

Juno、Jupyter、およびその他の対話型の環境では、最初にアプリのプロジェクトフォルダに`cd`で移動してください。

ローカルパッケージ環境を利用可能にする必要があります。

```julia
using Pkg
Pkg.activate(".")
```

次に以下を実行してください。

```julia
using Genie

Genie.loadapp()
```

## JuliaのREPLでの手動ロード

開いているJulia REPLセッション内でGenieアプリをロードするため、初めにGenieアプリのルートディレクトリに移動済みであることを確認してください。ここはプロジェクトのフォルダで、`bootstrap.jl`ファイルに加えて、特にJuliaの`Project.toml`ファイルと `Manifest.toml`ファイルが必要であるということです。`julia> cd(...)` または`shell> cd ...`コマンドでGenieアプリのフォルダに移動できます。

次に、アクティブなJulia REPLセッションないから、ローカルパッケージ環境をアクティブ化する必要があります。

```julia
julia> ] # enter pkg> mode

pkg> activate .
```

そして、Juliaプロンプトに戻り、以下の通りGenieアプリのロードを実行します。

```julia
julia> using Genie

julia> Genie.loadapp()
```

これで、アプリの環境がロードされます。

サーバを起動するために以下を実行します。

```julia
julia> startup()
```

---
**注意喚起**

アプリをロードする推奨方法は、`bin/repl`や`bin/server`、`bin/serverinteractive`コマンドを使用することです。Juliaプロセスを正しく開始し、1つのコマンドですべての依存関係をロードしてアプリのREPLを開始します。

---
