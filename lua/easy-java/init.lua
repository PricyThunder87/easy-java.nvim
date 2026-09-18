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

  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    pattern = "*.java",
    desc = "EasyJava: scaffold empty Java buffers (oil.nvim/mini.files compat)",
    callback = function(args)
      vim.schedule(function()
        local bufnr = args.buf
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        if #lines == 0 or (#lines == 1 and lines[1] == "") then
          require("easy-java")._on_new_file(bufnr)
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "MiniFilesActionCreate",
    desc = "EasyJava: scaffold files created via mini.files",
    callback = function(args)
      local path = args.data
      if type(path) == "table" then
        path = path.to or path.from
      end
      if path and tostring(path):match("%.java$") then
        vim.schedule(function()
          local bufnr = vim.fn.bufadd(tostring(path))
          if bufnr and bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_call(bufnr, function()
              require("easy-java")._on_new_file(bufnr)
            end)
          end
        end)
      end
    end,
  })
end

--- Internal handler for BufNewFile. Wraps scaffold in pcall for safety.
---@param bufnr number
function M._on_new_file(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  if vim.b[bufnr]._easy_java_scaffolded then
    return
  end
  vim.b[bufnr]._easy_java_scaffolded = true
  local ok, err = pcall(require("easy-java.scaffold").scaffold, bufnr)
  if not ok then
    vim.notify("[easy-java] scaffold error: " .. tostring(err), vim.log.levels.WARN)
  end
end

return M
