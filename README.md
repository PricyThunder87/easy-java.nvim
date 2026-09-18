# easy-java

Automatic Java file scaffolding for Neovim. When you create a `.java` file through any file explorer (mini.files, snacks explorer, netrw, oil.nvim, etc.), this plugin instantly populates it with the correct `package` declaration and class skeleton based on the file's path and name.

## How it works

1. You create `UserService.java` inside `src/main/java/com/example/service/`
2. The plugin detects the package root and computes: `com.example.service`
3. The file is populated with:

```java
package com.example.service;

public class UserService {

}
```

Suffix-based type detection is built in:
- `UserRepository.java` → `public class UserRepository`
- `UserServiceInterface.java` → `public interface UserServiceInterface`
- `UserRoleEnum.java` → `public enum UserRoleEnum`

## Installation

### lazy.nvim

```lua
{
  "noahsakko/easy-java",
  ft = "java",
  config = function()
    require("easy-java").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "noahsakko/easy-java",
  ft = "java",
  config = function()
    require("easy-java").setup()
  end,
}
```

### Manual

Clone or symlink into your Neovim runtime path:

```sh
git clone https://github.com/noahsakko/easy-java ~/.local/share/nvim/site/pack/plugins/start/easy-java
```

No setup call required — the plugin auto-activates with defaults.

## Demo

https://github.com/user-attachments/assets/df7ed04a-5756-422f-a28e-c8a841439e4d

## Configuration

```lua
require("easy-java").setup({
  -- Directories to search upward for when resolving the package path.
  -- The plugin walks the file path looking for these markers.
  src_roots = { "src/main/java", "src" },

  -- Fallback package when no src root is found in the path.
  default_package = "com.example",

  -- Set to false to disable the plugin entirely.
  enabled = true,
})
```

### `src_roots` explained

The plugin resolves the package by finding the first matching root directory in the absolute file path. Given:

```
/home/user/project/src/main/java/com/example/UserService.java
```

It finds `src/main/java`, then takes the relative path after it (`com/example/UserService.java`), strips the filename, and converts `/` to `.` → `com.example`.

If no root is found, `default_package` is used.

## Compatibility

Works with any file creation mechanism:

- **mini.files** — create file via its file creation UI
- **snacks explorer** — create file via its file creation UI
- **oil.nvim** — write buffer after adding a new entry
- **netrw** — `:Explore` and `%` to create
- **neo-tree** — create file via its UI
- **`:e path/to/NewFile.java`** — direct command
- **`vim.cmd("edit ...")`** from any plugin

The plugin uses multiple Neovim events for broad compatibility:
- `BufNewFile` — standard Neovim file creation
- `BufReadPost` — catches files opened by oil.nvim/mini.files after creation
- `MiniFilesActionCreate` — mini.files-specific event for file creation

## License

MIT
