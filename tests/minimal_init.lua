-- minimal init for plenary test runner
vim.cmd("set rtp+=.")
vim.cmd("set rtp+=~/.local/share/nvim/lazy/plenary.nvim")
package.path = package.path .. ";./tests/?.lua;./tests/?/init.lua"
