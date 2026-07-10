vim.print(require('functool').any())
vim.print(require('functool').randomString(7))


vim.g.mark_ns = vim.api.nvim_create_namespace('test')
vim.g.mark_ex = vim.api.nvim_buf_set_extmark(0, vim.g.mark_ns, 2, 0, { virt_text = {{"some", "DiagnosticWarn"}, {" body", "DiagnosticOk"}}, virt_text_pos = "overlay" })


vim.api.nvim_buf_del_extmark(0, vim.g.mark_ns, vim.g.mark_ex)


vim.print(vim.api.nvim_buf_get_extmark_by_id(0, vim.g.mark_ns, vim.g.mark_ex, {}))



vim.api.nvim_buf_set_extmark()
