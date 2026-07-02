if vim.g.loaded_llama_cpp_nvim then
    return
end
vim.g.loaded_llama_cpp_nvim = true

-- Point directly to the streamlined .execute() pipeline
vim.api.nvim_create_user_command("Llama", function(opts)
    require("llama-cpp").execute(opts)
end, { nargs = "*", range = true , desc = "Trigger the llama.cpp generation engine" })
