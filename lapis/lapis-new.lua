#!/bin/lua5.1

-- Lapis project initialise script

-- REQUIREMENTS:
-- lua5.1, luarocks, git

-- USAGE:
-- Save this script in your $PATH as lapis-new and give the file execute permissions (chmod +x lapis-new)
-- Run either:
-- lapis-new
-- or
-- lapis-new [-h] [porject_name] [db] [project_type] [view_type]
--
-- db can be either "db" or "no-db"
-- project_type can be either "api" or "full"
-- template_type can be either "etlua" or "lua"

local haslfs, lfs = pcall(require, "lfs")
if not haslfs then
  os.execute("luarocks install luafilesystem --lua-version=5.1")
  lfs = require("lfs")
end
for index in pairs(arg) do
  if arg[index] == "-h" or arg[index] == "--help" then
    print([[
Usage: lapis-new [-h] [project_name] [db] [project_type] [view_type]

Script to initialise a new lapis project using the openresty backend

Arguments:
  project_name        The name of the project
  db                  Init with or without a database(db, no-db)
  project_type        Whether the project is an API or Fullstack(api, full)
  view_type           The type of views used in the project(etlua, lua)

Options:
  -h, --help          Show this help message]])
    os.exit(0)
  end
end

local project_name
if arg[1] then
  project_name = arg[1]
else
  print("Project name?")
  project_name = io.read()
end

local new_project = lfs.mkdir(project_name)
if not new_project then
  print("Folder already exists, would you like to override? [Y/N]")
  local answer = string.lower(io.read())
  if answer == "y" then
    os.execute("rm -rf " .. project_name)
    lfs.mkdir(project_name)
  elseif answer == "n" then
    print("Operation cancelled")
    return
  else
    print("Invalid response")
    return
  end
end
lfs.chdir(project_name)

local haslapis, _ = pcall(require, "lapis")
if not haslapis then
  print("lapis not installed, installing...")
  os.execute("luarocks install lapis --lua-version=5.1")
end
os.execute("lapis new --rockspec")
os.execute("git init")

local db

if arg[2] then
  db = arg[2]
else
  print("db[1] or no db[2]")
  db = tonumber(io.read())
end

local gitignore_content
local config_content

local is_db = false

if db == 1 or db == "db" then
  is_db = true
  local haslsqlite, _ = pcall(require, "lsqlite3")
  if not haslsqlite then
    print("lsqlite not installed, installing...")
    os.execute("luarocks install lsqlite3 --lua-version=5.1")
  end
  local migrations_content = [[
local db = require("lapis.db")
local schema = require("lapis.db.schema")
local types = schema.types

return {
  [1] = function()
    schema.create_table("users", {
      { "id",       types.integer },
      { "username", types.text },
      { "email",    types.text },
      { "password", types.text },

      "PRIMARY KEY (id)"
    })

    schema.create_index("users", "username", "email", { unique = true })
  end,
}]]
  local migrations_file = io.open("migrations.lua", "w")
  io.output(assert(migrations_file))
  io.write(migrations_content)
  io.close()

  os.execute("lapis generate model users")
  gitignore_content = [[
logs/
nginx.conf.compiled
*.sqlite
*_temp/
]]
  config_content = [[
local config = require("lapis.config")

config("development", {
  server = "nginx",
  port = "8080",
  code_cache = "off",
  num_workers = "1",
  sqlite = {
    database = "app.sqlite"
  }
})

config("production", {
  server = "nginx",
  port = "8080",
  code_cache = "on",
  num_workers = "auto",
  sqlite = {
    database = "app.sqlite"
  }
})
]]
elseif db == 2 or db == "no-db" then
  gitignore_content = [[
logs/
nginx.conf.compiled
*_temp/
]]
  config_content = [[
local config = require("lapis.config")

config("development", {
  server = "nginx",
  port = "8080",
  code_cache = "off",
  num_workers = "1",
})

config("production", {
  server = "nginx",
  port = "8080",
  code_cache = "on",
  num_workers = "auto",
})
]]
end

local gitignore_file = io.open(".gitignore", "w")
io.output(assert(gitignore_file))
io.write(gitignore_content)
io.close()

local config_file = io.open("config.lua", "w")
io.output(assert(config_file))
io.write(config_content)
io.close()

local project_type
if arg[3] then
  project_type = string.lower(arg[3])
else
  print("Project type?")
  print("API [1] or Fullstack [2]")
  project_type = io.read()
end

if tonumber(project_type) == 1 or project_type == "api" then
  local docker_content
  if is_db then
    docker_content = [[
FROM openresty/openresty:jammy

WORKDIR /app

RUN apt update
RUN apt install -y libssl-dev
RUN apt install -y sqlite3
RUN apt install -y libsqlite3-dev

RUN luarocks install luasec
RUN luarocks install lapis
RUN luarocks install lsqlite3
RUN luarocks install tableshape

COPY . .

RUN lapis migrate production

EXPOSE 8080

CMD ["lapis", "server", "production"]
  ]]
  else
    docker_content = [[
FROM openresty/openresty:jammy

WORKDIR /app

RUN apt update
RUN apt install -y libssl-dev

RUN luarocks install luasec
RUN luarocks install lapis
RUN luarocks install tableshape

COPY . .

RUN lapis migrate production

EXPOSE 8080

CMD ["lapis", "server", "production"]
  ]]
  end

  local docker_file = io.open("Dockerfile", "w")
  io.output(assert(docker_file))
  io.write(docker_content)
  io.close(docker_file)
  local app_lua_content = [[
local lapis = require("lapis")
local app = lapis.Application()

app:get("/", function()
  return { json = { hello = "world"} }
end)

return app
  ]]

  local app_lua_file = io.open("app.lua", "w+")
  io.output(assert(app_lua_file))
  io.write(app_lua_content)
  io.close()
elseif tonumber(project_type) == 2 or project_type == "full" then
  local template_type

  if arg[4] then
    template_type = string.lower(arg[4])
  else
    print("Tempalting type?")
    print("etlua [1] or lapis lua [2]")
    template_type = io.read()
  end

  if tonumber(template_type) == 1 or template_type == "etlua" then
    local hasetlua, _ = pcall(require, "etlua")
    if not hasetlua then
      print("etlua not installed, installing...")
      os.execute("luarocks install etlua --lua-version=5.1")
    end
    local app_lua_content = [[
local lapis = require("lapis")
local app = lapis.Application()
app:enable("etlua")
app.layout = require "views.layout"

app:get("/", function()
  return {render = "index"}
end)

return app
  ]]

    local app_lua_file = io.open("app.lua", "w+")
    io.output(assert(app_lua_file))
    io.write(app_lua_content)
    io.close()

    lfs.mkdir("views")
    lfs.chdir("views")

    local index_etlua_content = [[
<h1>
  Welcome to
  <a href="https://leafo.net/lapis/" target="_blank">Lapis <%= require("lapis.version")%></a>
</h1>
<p>Edit the index.etlua file in ./views to begin</p>
    ]]

    local index_etlua_file = io.open("index.etlua", "w")
    io.output(assert(index_etlua_file))
    io.write(index_etlua_content)
    io.close()

    local app_etlua_layout_content = [[
<!DOCTYPE HTML>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title><%= Page_title or "Lapis Page" %></title>
    <link rel="stylesheet" href="/static/css/reset.css" />
  </head>
  <body>
    <main>
      <% content_for("inner") %>
    </main>
  </body>
</html>
    ]]

    local app_etlua_layout_file = io.open("layout.etlua", "w")
    io.output(assert(app_etlua_layout_file))
    io.write(app_etlua_layout_content)
    io.close()

    lfs.chdir("..")

    local docker_content
    if is_db then
      docker_content = [[
FROM openresty/openresty:jammy

WORKDIR /app

RUN apt update
RUN apt install -y libsqlite3-dev
RUN apt install -y sqlite3
RUN apt install -y libssl-dev

RUN luarocks install luasec
RUN luarocks install lapis
RUN luarocks install etlua
RUN luarocks install lsqlite3
RUN luarocks install tableshape

COPY . .

RUN lapis migrate production

EXPOSE 8080

CMD ["lapis", "server", "production"]
  ]]
    else
      docker_content = [[
FROM openresty/openresty:jammy

WORKDIR /app

RUN apt update
RUN apt install -y libssl-dev

RUN luarocks install luasec
RUN luarocks install lapis
RUN luarocks install etlua
RUN luarocks install tableshape

COPY . .

RUN lapis migrate production

EXPOSE 8080

CMD ["lapis", "server", "production"]
  ]]
    end
    local docker_file = io.open("Dockerfile", "w")
    io.output(assert(docker_file))
    io.write(docker_content)
    io.close(docker_file)
  elseif tonumber(template_type) == 2 or template_type == "lua" then
    local app_lua_content = [[
local lapis = require("lapis")
local app = lapis.Application()
app.layout = require "views.layout"

app:get("/", function()
  return {render = "index"}
end)

return app
  ]]

    local app_lua_file = io.open("app.lua", "w+")
    io.output(assert(app_lua_file))
    io.write(app_lua_content)
    io.close()

    lfs.mkdir("views")
    lfs.chdir("views")

    local index_lua_content = [[
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  h1(function()
    text("Welcome to ")
    a({ href = "https://leafo.net/lapis/", target = "_blank" }, "lapis " .. require("lapis.version"))
  end)
  p("Edit the index.lua file in ./views to begin")
end)

  ]]

    local index_lua_file = io.open("index.lua", "w")
    io.output(assert(index_lua_file))
    io.write(index_lua_content)
    io.close()

    local app_lua_layout_content = [[
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
	raw("<!DOCTYPE html>")
  html(function()
    head(function()
      meta({ charset = "UTF-8" })
      meta({ name = "viewport", content = "width=device-width, initial-scale=1" })
      title(self.page_title or "Lapis Page")
      link({ rel = "stylesheet", href = "/static/css/reset.css" })
    end)
    body(function()
      main(function()
        self:content_for("inner")
      end)
    end)
  end)
end)
    ]]

    local app_lua_layout_file = io.open("layout.lua", "w")
    io.output(assert(app_lua_layout_file))
    io.write(app_lua_layout_content)
    io.close()
    lfs.chdir("..")
    local docker_content
    if is_db then
      docker_content = [[
FROM openresty/openresty:jammy

WORKDIR /app

RUN apt update
RUN apt install -y libsqlite3-dev
RUN apt install -y sqlite3
RUN apt install -y libssl-dev

RUN luarocks install luasec
RUN luarocks install lapis
RUN luarocks install lsqlite3
RUN luarocks install tableshape

COPY . .

RUN lapis migrate production

EXPOSE 8080

CMD ["lapis", "server", "production"]
  ]]
    else
      docker_content = [[
FROM openresty/openresty:jammy

WORKDIR /app

RUN apt update
RUN apt install -y libssl-dev

RUN luarocks install luasec
RUN luarocks install lapis
RUN luarocks install tableshape

COPY . .

RUN lapis migrate production

EXPOSE 8080

CMD ["lapis", "server", "production"]
  ]]
    end

    local docker_file = io.open("Dockerfile", "w")
    io.output(assert(docker_file))
    io.write(docker_content)
    io.close(docker_file)
  else
    print("Invalid input")
    return
  end
  os.execute("mkdir -p static/css static/assets static/js")

  lfs.chdir("static")
  lfs.chdir("css")

  local reset_css_content = [[
  :root {
  --clr-dark-900: black;
  --clr-light-900: white;
}

@media (prefers-color-scheme: light) {
  :root {
    --font-color: var(--clr-dark-900);
    --font-color-inverse: var(--clr-light-900);
  }
  body {
    background-color: white;
  }
}
@media (prefers-color-scheme: dark) {
  :root {
    --font-color: var(--clr-light-900);
    --font-color-inverse: var(--clr-dark-900);
  }
  body {
    background-color: #1c1b22;
  }
}

* {
  font-family:
    system-ui,
    -apple-system,
    BlinkMacSystemFont,
    "Segoe UI",
    Roboto,
    Oxygen,
    Ubuntu,
    Cantarell,
    "Open Sans",
    "Helvetica Neue",
    sans-serif;
  padding: 0;
  margin: 0;
  color: inherit;
}

*,
*::after,
*::before {
  box-sizing: inherit;
}

html {
  color-scheme: dark light;
  box-sizing: border-box;
}

@media (prefers-reduced-motion: no-preference) {
  html {
    scroll-padding-top: 4rem;
    scroll-behavior: smooth;
  }
}

body {
  color: var(--font-color);
  min-height: 100vh;
  min-height: 100svh;
}

img,
video,
svg,
picture {
  display: block;
  width: 100%;
}

button {
  cursor: pointer;
}

code,
kbd {
  font-family: monospace;
}
  ]]

  local reset_css_file = io.open("reset.css", "w")
  io.output(assert(reset_css_file))
  io.write(reset_css_content)
  io.close()
  lfs.chdir("..")
  lfs.chdir("..")
else
  print("Invalid response")
  return
end

if is_db then
  os.execute("lapis migrate")
end
os.execute("git add .")
print()
print("To start your server, run:")
print("cd " .. project_name .. "/")
print("lapis server")
print("Open your browser at  http://localhost:8080")
