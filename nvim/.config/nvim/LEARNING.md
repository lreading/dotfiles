# Neovim Learning Plan

This is a concrete plan for learning the tools already in this config before adding more plugins.

## 1. Terminal Workflow

Goal: stop treating terminal usage as a single throwaway float and start using the multiple-terminal features you already have through `toggleterm`.

Status: complete

Current config:
- `<C-t>` toggles your default floating terminal.
- `<C-y>` toggles your dedicated Aider floating terminal.
- `<Esc>` in terminal mode returns to terminal-normal mode.

Important existing `toggleterm` features you are not using yet:
- `:2ToggleTerm`, `:3ToggleTerm`, etc. open numbered terminals.
- `:TermSelect` shows a terminal picker.
- `:ToggleTermToggleAll` opens/closes all toggleterm terminals.
- `:TermExec cmd="pnpm dev"` runs a command in a terminal.
- `:2TermExec cmd="pnpm dev" dir=~/dev/slide-spec/app` runs a command in terminal 2 in a chosen directory.
- `:3TermExec cmd="pnpm dev" dir=~/dev/slide-spec/cli` runs another command in terminal 3.
- `:ToggleTermSetName api` lets you name a terminal, which helps when using `:TermSelect`.

Recommended practice:
1. Open `~/dev/slide-spec`.
2. Run `:2TermExec cmd="pnpm dev" dir=~/dev/slide-spec/app`.
3. Run `:3TermExec cmd="pnpm dev" dir=~/dev/slide-spec/cli`.
4. Use `:TermSelect` to switch between them.
5. Use `:ToggleTermToggleAll` to understand how multiple terminals behave together.

If this feels good, the next improvement is adding a few explicit keymaps for `:TermSelect` and one or two named long-lived terminals. Do that only after the commands feel natural.

## 2. Merge Conflicts

Goal: stop editing raw conflict markers by hand and use a dedicated Neovim merge tool.

Status: next

Dedicated merge helper:
- `diffview.nvim`

Top-level keymaps:
- `<leader>dv`: toggle Diffview
- `<leader>dV`: current-file history in Diffview

Practice repo already prepared:
- `/tmp/nvim-merge-conflict-demo`

Current conflict file:
- `/tmp/nvim-merge-conflict-demo/policy.ts`

How to practice:
1. `cd /tmp/nvim-merge-conflict-demo`
2. Open Neovim in the repo root.
3. Press `<leader>dv` to open Diffview.
4. Select the conflicted file from the file panel.
5. Use Diffview's merge actions to keep ours, theirs, base, all, or none for each conflict region.
6. Save the merged file with `:w`.
7. Close Diffview with `<leader>dv`.
8. Finish the merge in git with `git add policy.ts`.

Useful Diffview merge actions to learn:
- `g?`: open Diffview help
- `<leader>ko`: keep ours for the current conflict
- `<leader>kt`: keep theirs for the current conflict
- `<leader>kb`: keep base for the current conflict
- `<leader>ka`: keep all variants for the current conflict
- `<leader>kn`: keep none for the current conflict
- `2do` / `3do`: pull the current hunk from ours / theirs in 3-way layouts

Meaning of "keep none":
- This removes the entire conflict region from the merged result.
- Use it when neither side's text should survive as-is.
- That is exactly the same mental model as "keep none".

What this demo represents:
- `main` changed the password policy to require symbols and a 10-character minimum.
- `feature` changed the minimum length to 12.
- A sensible manual resolution would likely be:
  `return { minLength: 12, requireNumber: true, requireSymbol: true }`

If you end up liking this workflow, the next optional step is setting `git config merge.tool nvimdiff` and `git config mergetool.nvimdiff.cmd 'nvim -d \"$LOCAL\" \"$BASE\" \"$REMOTE\" \"$MERGED\"'` on your machine. That is optional; learn raw `nvim -d` first.

## 3. Test Runner

Goal: use a proper test UI with a summary tree, per-test actions, and real runner adapters for the frameworks you actually use.

Current plugin:
- `neotest`

Installed adapters:
- `neotest-vitest`
- `neotest-jest`
- `neotest-mocha`
- `neotest-rust`
- `neotest-vim-test` as a fallback for a few non-JS ecosystems

Current keymaps:
- `<leader>tt`: run nearest test
- `<leader>tf`: run the current file
- `<leader>ta`: run the current project for the active file
- `<leader>tl`: rerun the last test
- `<leader>ts`: toggle the test summary tree
- `<leader>to`: toggle the test output panel
- `<leader>tw`: toggle watch mode for the current file
- `<leader>td`: debug the nearest test with DAP

How to practice in `~/dev/slide-spec`:
1. Open `~/dev/slide-spec` at the repo root.
2. Open `app/src/views/PresentationsView.spec.ts`.
3. Press `<leader>ts` to open the summary tree.
4. Put the cursor inside a test and press `<leader>tt`.
5. Press `<leader>to` to inspect the output panel if the run fails or you want the raw runner output.
6. Press `<leader>tf` to run the whole file.
7. Press `<leader>tl` to rerun the last test.
8. Repeat the same flow in `cli/src/validation/ProjectContentValidator.spec.ts`.

What this setup is doing:
- finds the nearest project root for the current file instead of assuming your Neovim cwd is the right test root
- uses the local project binary for `vitest` or `jest` when available
- gives you a real summary tree and per-test UI instead of only a terminal command

Rust note:
- `neotest-rust` expects `cargo-nextest` for the best experience
- install it with `cargo install cargo-nextest` if you want Rust support to work smoothly

## 4. Recommended Order

Work through these in order:
1. Terminal workflow using numbered `toggleterm` instances and `:TermExec`.
2. Merge conflict practice in `/tmp/nvim-merge-conflict-demo`.
3. Neotest workflow in `~/dev/slide-spec`.

## 5. What To Do Next

Next session, pick one:
- Terminal workflow: I can add a small set of terminal-management keymaps without turning your config into VS Code.
- Merge workflow: I can walk you step by step through resolving the demo conflict inside Neovim.
- Neotest: I can help you walk through the summary tree, output panel, and adapter behavior in a real repo.
