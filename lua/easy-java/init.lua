local M = {}

---@class EasyJavaConfig
---@field src_roots string[] directories to search upward for (e.g. {"src/main/java", "src"})
---@field default_package string fallback package when path-based detection fails
---@field enabled boolean whether the plugin autocommands are active
---@field class_suffixes table<string, string> filename suffix -> class type mapping

M.config = {
  src_roots = { "src/main/java", "src" },
  default_package = "com.example",
  enabled = true,
  class_suffixes = {
    ["Interface"] = "interface",
    ["Enum"] = "enum",
  },
}

local group = vim.api.nvim_create_augroup("EasyJava", { clear = true })

--- Set up the plugin.
---@param opts? EasyJavaConfig user configuration overrides
function M.setup(opts)
  M._setup_called = true
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  if not M.config.enabled then
    return
  end

  vim.api.nvim_create_autocmd("BufNewFile", {
    group = group,
    pattern = "*.java",
    desc = "EasyJava: scaffold new Java files",
    callback = function(args)
      vim.schedule(function()
        require("easy-java")._on_new_file(args.buf)
      end)
    end,
  })
end

--- Internal handler for BufNewFile. Wraps scaffold in pcall for safety.
---@param bufnr number
function M._on_new_file(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local ok, err = pcall(require("easy-java.scaffold").scaffold, bufnr)
  if not ok then
    vim.notify("[easy-java] scaffold error: " .. tostring(err), vim.log.levels.WARN)
  end
end

return M
