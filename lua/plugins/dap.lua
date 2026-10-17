-- JS/TS remote debugging (Node inspector protocol) via js-debug-adapter.
-- Pairs with finance-dashboard docker-compose.dev.yml `ui` service:
-- node --inspect=0.0.0.0:${UI_DEBUG_PORT:-9229} on the `next dev` CLI process,
-- published to host. Attach-only: the Node process is started inside the
-- container, not by nvim-dap.
--
-- `next dev`'s CLI process only supervises; it forks a second process
-- ("next-server") that actually runs route handlers/server components, with
-- its own auto-selected inspector on port+1 (${UI_DEBUG_WORKER_PORT:-9230}).
-- Breakpoints in app code only bind on THAT inspector, so we attach to
-- 9230, not 9229. See JS-DAP.md.
return {
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "js-debug-adapter" })
        end,
      },
    },
    ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    config = function()
      local dap = require("dap")

      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "js-debug-adapter",
          args = { "${port}" },
        },
      }
      dap.adapters["node"] = dap.adapters["pwa-node"]

      -- NOTE: assumes Neovim is opened at the finance-dashboard repo root;
      -- the bind mount is ./ui:/app, not the repo root itself.
      -- Base config shared by every checkout/worktree; only `name`/`port` differ
      -- (each checkout's UI_DEBUG_WORKER_PORT must match the entry you pick).
      local function attach_config(name, port)
        return {
          type = "pwa-node",
          request = "attach",
          name = name,
          address = "localhost",
          port = port,
          restart = true,
          sourceMaps = true,
          cwd = "${workspaceFolder}/ui",
          localRoot = "${workspaceFolder}/ui",
          remoteRoot = "/app",
          protocol = "inspector",
          -- NOT "**/.next/**": that's meant to skip Next's own framework code,
          -- but Turbopack compiles YOUR route handlers into
          -- .next/dev/server/chunks/*.js too — there's no separate output
          -- location for app code. A breakpoint that source-maps into a
          -- skipFiles-matched compiled file is silently ignored (verified,
          -- never pauses), which is why breakpoints never fired. See JS-DAP.md.
          skipFiles = { "<node_internals>/**", "**/node_modules/**" },
          resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
          -- js-debug injects NODE_OPTIONS=--require <bootloader.js> into the
          -- debuggee's env so its children auto-attach too. That path is on
          -- the HOST filesystem (Mason install dir) and doesn't exist inside
          -- the container, so any child the debuggee forks (e.g. jest-worker)
          -- crashes on MODULE_NOT_FOUND. We only need the next-server process
          -- itself debugged, not its jest-worker children. See JS-DAP.md.
          autoAttachChildProcesses = false,
        }
      end

      -- Two entries so main and a worktree stack can be debugged at once —
      -- pick whichever matches the checkout this Neovim instance is opened
      -- at. Ports must match that checkout's UI_DEBUG_WORKER_PORT (main:
      -- 9232 via .env; worktrees default to 9230 unless overridden). See
      -- JS-DAP.md §6.
      local js_config = {
        attach_config("Attach to Docker (Next.js ui) - main [9232]", 9232),
        attach_config("Attach to Docker (Next.js ui) - worktree [9230]", 9230),
      }

      for _, lang in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
        dap.configurations[lang] = js_config
      end
    end,
  },
}
