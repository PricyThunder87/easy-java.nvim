if vim.g.loaded_easy_java then
  return
end
vim.g.loaded_easy_java = true

-- Auto-setup with defaults if the user hasn't called setup() yet.
-- This ensures the BufNewFile hook is registered even without explicit config.
local easy_java = require("easy-java")
if not easy_java._setup_called then
  easy_java.setup()
end
