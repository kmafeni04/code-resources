local function csrf_widget(self)
  local csrf = require("lapis.csrf")
  local Widget = require("lapis.html").Widget
  local csrf_token = csrf.generate_token(self)
  self.csrf = Widget:extend(function()
    input({ type = "hidden", value = csrf_token, name = "csrf_token" })
  end)
end

return csrf_widget
