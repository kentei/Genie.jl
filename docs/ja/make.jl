push!(LOAD_PATH,"../../src/")

using Documenter

using Genie, Genie.App, Genie.AppServer, Genie.Assets
using Genie.Cache, Genie.Commands, Genie.Configuration, Genie.Cookies
using Genie.Encryption, Genie.FileTemplates, Genie.Generator
using Genie.Inflector, Genie.Input, Genie.Plugins
using Genie.Renderer, Genie.Requests, Genie.Responses, Genie.Router
using Genie.Sessions, Genie.Toolbox, Genie.Util, Genie.WebChannels

push!(LOAD_PATH,  "../../../src",
                  "../../../src/cache_adapters",
                  "../../../src/session_adapters")

makedocs(sitename = "Genie - 生産性の高いJulia Webフレームワーク", format = Documenter.HTML(prettyurls = false))