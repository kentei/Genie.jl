push!(LOAD_PATH,"../src/")

using Documenter

using Genie, Genie.App, Genie.AppServer, Genie.Assets
using Genie.Cache, Genie.Commands, Genie.Configuration, Genie.Cookies
using Genie.Deploy, Genie.Encryption, Genie.Exceptions
using Genie.FileTemplates, Genie.Flash, Genie.Generator
using Genie.Headers, Genie.HTTPUtils, Genie.Inflector, Genie.Input, Genie.Plugins
using Genie.Renderer, Genie.Requests, Genie.Responses, Genie.Router
using Genie.Sessions, Genie.Toolbox, Genie.Util, Genie.WebChannels

push!(LOAD_PATH,  "../../../src",
                  "../../../src/cache_adapters",
                  "../../../src/session_adapters",
                  "../../../src/renderers")

makedocs(
    sitename = "Genie - 生産性の高いJulia Webフレームワーク",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Home" => "index.md",
        "ガイド" => [
          "Working with Genie Apps" => "guides/Working_With_Genie_Apps.md",
          "対話型環境でのGenieの利用" => "guides/Interactive_environment.md",
          "APIバックエンドの開発" => "guides/Simple_API_backend.md",
          "Genieプラグインの利用" => "guides/Genie_Plugins.md",
          "Working With Genie Apps: Intermediate Topics [WIP]" => "guides/Working_With_Genie_Apps_Intermediary_Topics.md"
        ],
        "チュートリアル" => [
          "Genieへようこそ"  => "tutorials/1--Overview.md",
          "Genieのインストール"  => "tutorials/2--Installing_Genie.md",
          "Genieを始めよう"   => "tutorials/3--Getting_Started.md",
          "Webサービスの作成" => "tutorials/4--Developing_Web_Services.md",
          "MVCによるWebアプリケーション開発" => "tutorials/4-1--Developing_MVC_Web_Apps.md",
          "クエリパラメータの処理/GETパラメータ" => "tutorials/5--Handling_Query_Params.md",
          "POSTペイロードの操作" => "tutorials/6--Working_with_POST_Payloads.md",
          "JSONペイロードの利用" => "tutorials/7--Using_JSON_Payloads.md",
          "ファイルアップロードの操作" => "tutorials/8--Handling_File_Uploads.md",
          "Genieアプリに既存Juliaコードの追加" => "tutorials/9--Publishing_Your_Julia_Code_Online_With_Genie_Apps.md",
          "Genieアプリのロードと起動" => "tutorials/10--Loading_Genie_Apps.md",
          "Genieアプリの依存管理" => "tutorials/11--Managing_External_Packages.md",
          "高度なルーティング" => "tutorials/12--Advanced_Routing_Techniques.md",
          "イニシャライザによる設定コードの自動読み込み" => "tutorials/13--Initializers.md",
          "シークレットファイル" => "tutorials/14--The_Secrets_File.md",
          "ユーザーライブラリの自動読み込み" => "tutorials/15--The_Lib_Folder.md",
          "DockerでのGenie利用" => "tutorials/16--Using_Genie_With_Docker.md",
          "WebSocketの利用" => "tutorials/17--Working_with_Web_Sockets.md",
          "ルートの強制コンパイル" => "tutorials/80--Force_Compiling_Routes.md",
          "HerokuビルドパックによるGenieアプリのデプロイ" => "tutorials/90--Deploying_With_Heroku_Buildpacks.md",
          "DockerによるHerokuへのデプロイ" => "tutorials/91--Deploying_Genie_Docker_Apps_on_Heroku.md"
        ],
        "API" => [
          "App" => "API/app.md",
          "AppServer" => "API/appserver.md",
          "Assets" => "API/assets.md",
          "Cache" => "API/cache.md",
          "Commands" => "API/commands.md",
          "Configuration" => "API/configuration.md",
          "Cookies" => "API/cookies.md",
          "Deploy" => [
            "Docker" => "API/deploy_docker.md",
            "Heroku" => "API/deploy_heroku.md"
          ],
          "Encryption" => "API/encryption.md",
          "Exceptions" => "API/exceptions.md",
          "FileTemplates" => "API/filetemplates.md",
          "Flash" => "API/flash.md",
          "Generator" => "API/generator.md",
          "Genie" => "API/genie.md",
          "Headers" => "API/headers.md",
          "HttpUtils" => "API/httputils.md",
          "Inflector" => "API/inflector.md",
          "Input" => "API/input.md",
          "Plugins" => "API/plugins.md",
          "Renderer" => "API/renderer.md",
          "HTML Renderer" => "API/renderer_html.md",
          "JS Renderer" => "API/renderer_js.md",
          "JSON Renderer" => "API/renderer_json.md",
          "Requests" => "API/requests.md",
          "Responses" => "API/responses.md",
          "Router" => "API/router.md",
          "Sessions" => "API/sessions.md",
          "Toolbox" => "API/toolbox.md",
          "Util" => "API/util.md",
          "WebChannels" => "API/webchannels.md"
        ]
    ],
)

deploydocs(
  repo = "github.com/kentei/Genie.jl.git",
)