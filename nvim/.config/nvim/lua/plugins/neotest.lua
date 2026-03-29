return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "haydenmeade/neotest-jest",
      "marilari88/neotest-vitest",
      "adrigzr/neotest-mocha",
      "thenbe/neotest-playwright",
      "rouge8/neotest-rust",
    },
    config = function()
      local helper = require("neotest-project")
      local neotest = require("neotest")
      local lib = require("neotest.lib")
      local nio = require("nio")
      local read_playwright_report = require("neotest-playwright.report-io").readReport
      local parse_playwright_report = require("neotest-playwright.report").parseOutput

      -- Playwright discovery breaks in neotest's child subprocess when the repo
      -- needs project-specific binary/config resolution. Keep discovery in the
      -- main process so adapter callbacks can resolve from the active project.
      lib.subprocess.init = function() end
      lib.subprocess.enabled = function()
        return false
      end

      local function seed_workspace_projects()
        if not helper.use_workspace_projects(vim.uv.cwd()) then
          return
        end

        for _, seed in ipairs(helper.workspace_seed_paths(vim.uv.cwd())) do
          neotest.run.get_tree_from_args(seed, false)
        end
      end

      local vitest = require("neotest-vitest")({
        cwd = function(path)
          return helper.cwd(path)
        end,
        vitestCommand = function(path)
          return helper.vitest_command(path)
        end,
        vitestConfigFile = function(path)
          return helper.vitest_config(path)
        end,
        is_test_file = function(path)
          return helper.is_vitest_file(path)
        end,
      })
      vitest.root = function(path)
        return helper.has_vitest_project(path) and helper.cwd(path) or nil
      end
      vitest.is_test_file = function(path)
        return helper.is_vitest_file(path)
      end

      local jest = require("neotest-jest")({
        cwd = function(path)
          return helper.cwd(path)
        end,
        jestCommand = function(path)
          return helper.jest_command(path)
        end,
        jestConfigFile = function(path)
          return helper.jest_config(path)
        end,
        isTestFile = function(path)
          return helper.is_jest_file(path)
        end,
      })
      jest.root = function(path)
        return helper.has_jest_project(path) and helper.cwd(path) or nil
      end
      jest.is_test_file = function(path)
        return helper.is_jest_file(path)
      end

      local mocha = require("neotest-mocha")({
        cwd = function(path)
          return helper.cwd(path)
        end,
        command = function(path)
          return helper.mocha_command(path)
        end,
      })
      mocha.root = function(path)
        return helper.has_mocha_project(path) and helper.cwd(path) or nil
      end
      mocha.is_test_file = function(path)
        return helper.is_mocha_file(path)
      end

      local playwright = require("neotest-playwright").adapter({
        options = {
          enable_dynamic_test_discovery = true,
          get_playwright_binary = function()
            return helper.playwright_command(helper.playwright_discovery_target())
          end,
          get_playwright_config = function()
            return helper.playwright_config(helper.playwright_discovery_target())
          end,
          get_cwd = function()
            return helper.cwd(helper.playwright_discovery_target())
          end,
        },
      })

      playwright.root = function(path)
        return helper.has_playwright_project(path) and helper.cwd(path) or nil
      end

      playwright.filter_dir = function(name)
        return name ~= "node_modules"
      end

      playwright.is_test_file = function(path)
        return helper.is_playwright_file(path)
      end

      local playwright_build_spec = playwright.build_spec
      playwright.build_spec = function(args)
        local position = args.tree:data()
        local path = position.path
        local config = helper.playwright_config(path)
        if not config then
          return nil
        end

        local options = playwright.options
        local old_binary = options.get_playwright_binary
        local old_config = options.get_playwright_config
        local old_cwd = options.get_cwd

        options.get_playwright_binary = function()
          return helper.playwright_command(path)
        end
        options.get_playwright_config = function()
          return config
        end
        options.get_cwd = function()
          return helper.cwd(path)
        end

        local ok, spec = pcall(playwright_build_spec, args)

        options.get_playwright_binary = old_binary
        options.get_playwright_config = old_config
        options.get_cwd = old_cwd

        if not ok then
          error(spec)
        end

        return spec
      end

      local playwright_results = playwright.results
      playwright.results = function(spec, result, tree)
        local target = spec
          and spec.context
          and spec.context.file
          or (tree and tree:data() and tree:data().path)
        local report_path = spec and spec.context and spec.context.results_path

        if report_path then
          local ok_report, decoded = pcall(read_playwright_report, report_path)
          if ok_report and type(decoded) == "table" and decoded.suites and #decoded.suites > 0 then
            return parse_playwright_report(decoded)
          end
        end

        if not target then
          local ok, parsed = pcall(playwright_results, spec, result, tree)
          return ok and parsed or {}
        end

        local status = result and result.code == 0 and "passed" or "failed"
        return {
          [target] = {
            status = status,
            short = ("%s: %s"):format(vim.fs.basename(target), status),
            output = result and result.output or nil,
          },
        }
      end

      local rust = require("neotest-rust")
      local rust_build_spec = rust.build_spec
      rust.build_spec = function(args)
        local position = args.tree:data()
        if position.type == "dir" then
          return nil
        end
        return rust_build_spec(args)
      end

      local adapters = {
        playwright,
        vitest,
        jest,
        mocha,
        rust,
      }

      neotest.setup({
        adapters = adapters,
        output = {
          open_on_run = "short",
        },
        output_panel = {
          enabled = true,
          open = "botright 12split | setlocal nobuflisted",
        },
        summary = {
          open = "botright vsplit | vertical resize 50",
          mappings = {
            watch = "W",
          },
        },
      })

      vim.keymap.set("n", "<leader>tt", function()
        neotest.run.run()
      end, { desc = "Run nearest test" })

      vim.keymap.set("n", "<leader>tf", function()
        neotest.run.run(vim.fn.expand("%"))
      end, { desc = "Run file tests" })

      vim.keymap.set("n", "<leader>ta", function()
        neotest.run.run(helper.project_target(vim.api.nvim_buf_get_name(0)))
      end, { desc = "Run project tests" })

      vim.keymap.set("n", "<leader>tl", function()
        neotest.run.run_last()
      end, { desc = "Run last test" })

      vim.keymap.set("n", "<leader>ts", function()
        nio.run(function()
          seed_workspace_projects()
          vim.schedule(function()
            neotest.summary.toggle()
          end)
        end)
      end, { desc = "Toggle test summary" })

      vim.keymap.set("n", "<leader>to", function()
        neotest.output_panel.toggle()
      end, { desc = "Toggle test output panel" })

      vim.keymap.set("n", "<leader>tw", function()
        neotest.watch.toggle(vim.fn.expand("%"))
      end, { desc = "Toggle test watch" })

      vim.keymap.set("n", "<leader>td", function()
        neotest.run.run({ strategy = "dap" })
      end, { desc = "Debug nearest test" })
    end,
  },
}
