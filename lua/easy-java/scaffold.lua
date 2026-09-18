local M = {}

--- Find the Java source root by walking up from a filepath looking for
--- configured root markers (e.g. "src/main/java", "src").
---@param filepath string absolute path to the .java file
---@param roots string[] list of root directory names to search for
---@return string|nil root the matched source root directory
---@return string|nil relpath relative path from root to the file's parent dir
function M.find_java_root(filepath, roots)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  local normalized = filepath:gsub("\\", "/")

  for _, root_name in ipairs(roots) do
    local pattern = "/" .. root_name .. "/"
    local idx = normalized:find(pattern, 1, true)
    if idx then
      local root_dir = normalized:sub(1, idx - 1) .. root_name
      local after = normalized:sub(idx + #pattern)
      local relpath = after:match("^(.+)/[^/]+$")
      return root_dir, relpath or ""
    end
  end

  return nil, nil
end

--- Convert a relative directory path to a Java package name.
--- e.g. "com/example/project" -> "com.example.project"
---@param relpath string
---@return string
function M.path_to_package(relpath)
  return relpath:gsub("/", ".")
end

--- Detect the class type from the filename suffix.
--- - Ends with "Interface" -> "interface"
--- - Ends with "Enum" -> "enum"
---@param filename string base name without extension
---@return string one of "class", "interface", "enum"
function M.detect_type(filename)
  if filename:match("Interface$") then
    return "interface"
  elseif filename:match("Enum$") then
    return "enum"
  end
  return "class"
end

--- Generate the Java file skeleton.
---@param package string full package name (e.g. "com.example")
---@param class_name string class name (e.g. "UserService")
---@param class_type string "class" | "interface" | "enum"
---@return string[] lines
function M.generate_skeleton(package, class_name, class_type)
  local lines = {}

  if package and package ~= "" then
    table.insert(lines, "package " .. package .. ";")
    table.insert(lines, "")
  end

  table.insert(lines, "public " .. class_type .. " " .. class_name .. " {")
  table.insert(lines, "")
  table.insert(lines, "}")
  table.insert(lines, "")

  return lines
end

--- Main scaffolding entry point. Called on BufNewFile for *.java files.
--- Determines package and class from the file path, then inserts a skeleton.
---@param bufnr number buffer handle
---@param opts? table optional overrides
function M.scaffold(bufnr, opts)
  opts = opts or {}
  local config = require("easy-java").config

  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == "" then
    return
  end

  local normalized = filepath:gsub("\\", "/")
  local filename = vim.fn.fnamemodify(normalized, ":t") -- e.g. "UserService.java"
  local class_name = filename:match("^(.+)%.java$")
  if not class_name then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if #lines > 1 or (#lines == 1 and lines[1] ~= "") then
    return
  end

  local roots = config.src_roots or { "src/main/java", "src" }
  local root, relpath = M.find_java_root(normalized, roots)

  local pkg
  if relpath and relpath ~= "" then
    pkg = M.path_to_package(relpath)
  else
    pkg = config.default_package or ""
  end

  local class_type = opts.class_type or M.detect_type(class_name)
  local skeleton = M.generate_skeleton(pkg, class_name, class_type)

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, skeleton)
  vim.bo[bufnr].modified = false
end

return M
