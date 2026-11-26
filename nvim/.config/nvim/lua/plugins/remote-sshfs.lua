-- pacman -S sshfs
return {
    "nosduco/remote-sshfs.nvim",
    dependencies = {
        "nvim-telescope/telescope.nvim",
        "nvim-lua/plenary.nvim",
    },
    config = function()
        require("remote-sshfs").setup({})
        require("telescope").load_extension("remote-sshfs")
    end,
    keys = {
        {
            "<leader>rs",
            "<cmd>RemoteSSHFSConnect<cr>",
            desc = "Connect to remote server",
        },
    },
}
