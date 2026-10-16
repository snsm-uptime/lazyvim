-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = LazyVim.safe_keymap_set

map("n", "<Space>ac", function() require("herdr-sidekick-agents").toggle("claude") end,
  { desc = "Toggle Claude Pane (herdr)" })
map("n", "<Space>af", function() require("herdr-sidekick-agents").focus("claude", { zoom = false }) end,
  { desc = "Focus Claude Pane (herdr)" })
map({ "n", "v" }, "<Space>as", function() require("herdr-sidekick-agents").send() end,
  { desc = "Send file/selection ref to agent pane" })
