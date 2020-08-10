# DockerでのGenie利用

Genieはアプリのコンテナ化のサポートが組み込まれています。その機能は`Genie.Deploy.Docker`モジュールで利用できます。

## Genieに最適化された`Dockerfile`の生成

`Genie.Deploy.Docker.dockerfile()`関数を呼び出すことでDockerセットアップをブートストラップできます。これにより、Gennie Webアプリコンテナ化のために最適化されたカスタム`Dockerfile`が生成されます。そのファイルは現在の作業ディレクトリ(または`path`オプション引数で指定した場所)に生成されます(`dockerfile()`関数のヘルプを参照してください)。一度生成されれば、それを編集して、必要に応じてカスタマイズできます。Genieはファイルを上書きしないため、変更は保持されます。

`dockerfile()`の振る舞いは、サポートされている複数のオプション引数を渡すことでコントロールすることができます。

## Dockerコンテナの構築

一度`Dockerfile`の準備ができたら、Dockerコンテナを構築するために`Genie.Deploy.Docker.build()`を呼び出すことができます。必要に応じて、コンテナの名前(デフォルトは`genie`)とパス(デフォルトは現在の作業ディレクトリ)を渡すことができます。

## Dockerコンテナ内でのGenieアプリ実行

イメージの準備ができたら、`Genie.Deploy.Docker.run()`で実行できます。アプリの実行方法をコントロールするためにオプション引数を構成できます。詳細については、関数のインラインヘルプを確認してください。

## 例

初めに、Genieアプリを作りましょう。

```julia
julia> using Genie

julia> Genie.newapp("DockerTest")
[ Info: Done! New app created at /Users/adrian/DockerTest
# output truncated
```

準備ができたら、`Dockerfile`を追加してみましょう。

```julia
julia> using Genie.Deploy

julia> Deploy.Docker.dockerfile()
Docker file successfully written at /Users/adrian/DockerTest/Dockerfile
```

ここでコンテナを構築します。

```julia
julia> Deploy.Docker.build()
Sending build context to Docker daemon  1.056MB
Step 1/18 : FROM julia:latest
 ---> f4c9686d85da
# output truncated
Successfully tagged genie:latest
Docker container successfully built
```

最後にDockerコンテナ内でアプリを実行することができます。

```julia
julia> Deploy.Docker.run()
Starting docker container with `docker run -it --rm -p 80:8000 --name genieapp genie bin/server`

 _____         _
|   __|___ ___|_|___
|  |  | -_|   | | -_|
|_____|___|_|_|_|___|

| Web: https://genieframework.com
| GitHub: https://github.com/genieframework/Genie.jl
| Docs: https://genieframework.github.io/Genie.jl
| Gitter: https://gitter.im/essenciary/Genie.jl
| Twitter: https://twitter.com/GenieMVC

Genie v0.19.0
Active env: DEV

Web Server starting at http://127.0.0.1:8000
```

アプリケーションはDockerコンテナ内で開始し、コンテナ内のポート8000(Genieアプリが実行されている場所)をホストのポート80にバインドします。だから、<http://localhost>でアプリにアクセスすることができます。もしお気に入りのブラウザで<http://localhost>に移動した場合、Genieのウェルカムページを表示します。ポート8000にアクセスしないことに注目してください。このページは、デフォルトのポート80のDockerコンテナから提供されます。

### 開発中のDocker利用

開発中のアプリを提供するためにDockerを利用したい場合、アプリをホスト(あなたのPC)からコンテナにマウントする必要がある。ローカルでファイルを編集しつづけても、Dockerコンテナにその変更が反映されます。これを実施するためには、`moubtapp = true`引数を`Deploy.Docker.run()`に渡す必要があります。

```julia
julia> Deploy.Docker.run(mountapp = true)
Starting docker container with `docker run -it --rm -p 80:8000 --name genieapp -v /Users/adrian/DockerTest:/home/genie/app genie bin/server`
```

アプリの起動が完了した際、好きなIDEを使ってホスト上でファイルを編集することができ、その変更はDockerコンテナに反映されます。
