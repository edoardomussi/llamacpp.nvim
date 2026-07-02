# llama-cpp.nvim

Minimal and lightweight llama-server integration for NeoVim.

## Architectural Principles

- **Zero Global State:** The plugin allocates tracking structures inside temporary RAM buffers (`bufhidden=wipe`). It does not read or write to disk (`/tmp`), avoiding storage leak pathways.
- **Asynchronous Execution:** Spawns single `curl` processes using native Libuv hooks (`vim.system`), guaranteeing zero UI freezes during multi-second inference streaming.
- **Native Alignment Engine:** Leverages NeoVim's integrated structural diffing tool (`diffthis`) to provide line-by-line workspace patch matching across localized splits.

## Prerequisites

- **NeoVim** >= 0.10.0
- **curl** (System binary accessible via shell `$PATH`)
- An active execution instance of **llama-server**

## Installation

Using `lazy.nvim`:

```lua
{
    "edoardomussi/llama-cpp.nvim",
    cmd = { "Llama" },
    config = function()
        require("llama-cpp").setup({
            endpoint = "http://localhost:8080/v1/chat/completions",
            model = "your-local-model",
            timeout = "30000"
        })
    end
}
```
