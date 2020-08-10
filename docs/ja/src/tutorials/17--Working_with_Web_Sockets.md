# WebSocketの利用

GenieはWebSocketを介したクライアントサーバ間の通信のための強力なワークフローを提供します。そのシステムはネットワークレベルの複雑さを隠し、GenieのMVCワークフローに似た強力な抽象化を公開します。というのも、クライアントとサーバは`channels`(`routes`に相当)を介してメッセージを交換します。

## `channels`の登録

メッセージはマッチするチャンネルに紐づけられており、ペイロードを抽出し、指定されたハンドラ(コントローラメソッドまたは関数)を呼び出すGenieの`Router`によって処理されます。ほとんどの場合、`channels`は`routes`と機能的に同等であり、同様の方法で定義されます。

```julia
using Genie.Router

channel("/foo/bar") do
  # process request
end

channel("/baz/bax", YourController.your_handler)
```

上記の`channel`の定義は、`/foo/bar`と`/baz/bax`に送信されるWebsocketメッセージを処理します。

## クライアントのセットアップ

ブラウザでWebSocket通信を有効にするには、JavaScriptファイルをロードする必要があります。これは`Assets`モジュールを介することでGenieが提供します。Genieは、`Assets.channels_support()`を提供することで、クライアント側でWebSocketの基盤を非常に簡単に準備できます。例えば、WebアプリのルートページにWebSocketのサポートを追加する場合、必要なのは以下です。

```julia
using Genie.Router, Genie.Assets

route("/") do
  Assets.channels_support()
end
```

記載通り、クライアントとサーバ間でメッセージをやりとりできるようにするために必要なことはこれだけです。

---

## 試してみよう！

Julia REPLで次のJuliaコードを実行することで進んでいきましょう。

```julia
using Genie, Genie.Router, Genie.Assets

Genie.config.websockets_server = true # enable the websockets server

route("/") do
  Assets.channels_support()
end

up() # start the servers
```

ここで、<http://localhost:8000>にアクセスすると、空白ページが表示されますが、WebSocket通信に必要なすべての機能は既に含まれています！ブラウザの開発者ツールを利用すると、NetWork部分に、`channels.js`ファイルがロードされ、WebSocketsリクエストが行われた旨(GETを介したステータス101)が記されています。さらにコンソールを覗くと、`Subscription ready`メッセージを確認できます。コンソールの出力は次のようになります。

```text
Queuing subscription channels.js:107:13
Subscription ready channels.js:105:13
OK channels.js:74:11
Overwrite window.parse_payload to handle messages from the server channels.js:98:11
OK
```

**何が起こったか？**

この時点で、`Assets.channels_support()`を呼び出すことで、Genieは以下を実施しました。

* バンドルされた`channels.js`ファイルをロードしました。このファイルにはWebSocketを介した通信をするためのJavaScript APIを提供します
* サブスクライブ用とサブスクライブ解除用の2つのデフォルトチャンネルを作成しました。(`/__/subscribe`、`/__/unsubscribe`)
* `/__/subscribe`を呼び出し、クライアントとサーバ間のWebSocket接続を作成しました。

### サーバーからメッセージのプッシュ

クライアントと対話する準備ができました。Webアプリを実行しているJulia REPLに移動して、次の通り実行します。

```julia
julia> Genie.WebChannels.connected_clients()
1-element Array{Genie.WebChannels.ChannelClient,1}:
 Genie.WebChannels.ChannelClient(HTTP.WebSockets.WebSocket{HTTP.ConnectionPool.Transaction{Sockets.TCPSocket}}(T0  🔁    0↑🔒    0↓🔒 100s 127.0.0.1:8001:8001 ≣16, 0x01, true, UInt8[0x7b, 0x22, 0x63, 0x68, 0x61, 0x6e, 0x6e, 0x65, 0x6c, 0x22  …  0x79, 0x6c, 0x6f, 0x61, 0x64, 0x22, 0x3a, 0x7b, 0x7d, 0x7d], UInt8[], false, false), ["__"])
```

`__`チャンネルに接続されたクライアントが1つあります！　メッセージを送ってみます。

```julia
julia> Genie.WebChannels.broadcast("__", "Hey!")
true
```

ブラウザのコンソールを見ると、「Hey!」というメッセージを確認できます。デフォルトでは、クライアント側のハンドラはメッセージを出力するだけです。「Overwrite window.parse_payload to handle messages from the server(window.parse_payloadを上書きしてサーバからのメッセージを処理する)」ことができることも通知もされる。やってみましょう。現在のREPLで実行します。(ルート(root)のルート(routes)ハンドラが上書きされます)

```julia
route("/") do
  Assets.channels_support() *
  """
  <script>
  window.parse_payload = function(payload) {
    console.log('Got this payload: ' + payload);
  }
  </script>
  """
end
```

ここで、ページをリロードしてメッセージをブロードキャストすると、カスタムペイロードハンドラによって取得されます。ただし、ブロードキャスト時にエラーが発生する可能性もあります。(エラーがログに出力されるが、それは重大ではなくアプリケーションを破壊することはないので、心配する必要はない)

```julia
julia> Genie.WebChannels.broadcast("__", "Hey!")
┌ Error: Base.IOError("stream is closed or unusable", 0)
└ @ Genie.WebChannels ~/.julia/dev/Genie/src/WebChannels.jl:220
true
```

このエラーは、ページをリロードした際、前に接続したWebSocketクライアントが到達不可となるために発生しています。しかし、まだ参照を保持しており、ブロードキャストしようとするとストリームが閉じられていることがわかります。これを修正するには、以下を呼び出します。

```julia
julia> Genie.WebChannels.unsubscribe_disconnected_clients()
```

`unsubscribe_disconnected_clients()`の出力は、残りの(接続済みの)クライアントのコレクションです。

---

**注意喚起!**

無害ではありますが、エラーはメモリ内に切断したクライアントが残っていることを示しています。不要なデータであるならば、それらをパージしメモリを開放してください。

---

いつでも、接続されたクライアントは`Genie.WebChannels.connected_clients()`で、切断されたクライアントは `Genie.WebChannels.disconnected_clients()`でチェックできます。

### クライアントからメッセージのプッシュ

クライアントからサーバにメッセージをプッシュすることもできます。UIを用意していないため、ブラウザのコンソールとGenieのJavaScript APIを利用してメッセージを送信してみましょう。しかし、最初にメッセージを受信するための`channel`を設定する必要があります。アクティブなJulia REPLで以下を実行してください。

```julia
channel("/__/echo") do
  "Received: $(@params(:payload))"
end
```

エンドポイントが起動したので、ブラウザのコンソールに移動して以下を実行します。
```javascript
Genie.WebChannels.sendMessageTo('__', 'echo', 'Hello!')
```

コンソールはすぐにサーバからのレスポンス表示します。

```text
Received: Hello!  channels.js:74:3
Got this payload: Received: Hello!
```

## まとめ

これで、GenieでWebSocketを操作するための紹介は終わりです。クライアントとサーバ間の通信を設定し、サーバとクライアントの両方からメッセージを送信し、`WebChannels` APIを使用して様々なタスクを実行する知識をここまでで得ることができました。
