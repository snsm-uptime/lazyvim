return {
  {
    "jcarlos7121/herdr-sidekick-agents.nvim",
    cond = vim.env.HERDR_ENV == "1",
    main = "herdr-sidekick-agents",
    default_agent = "claude",
    agents = { claude = { kind = "claude" } },
    opts = {},
  }
}
