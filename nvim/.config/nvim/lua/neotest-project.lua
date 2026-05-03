local M = {}

local uv = vim.uv or vim.loop
local neoconf_cache = {}

local defaults = {
	cwd = nil,
	overrides = {},
	vitest = {
		enabled = true,
		command = nil,
		config = nil,
	},
	jest = {
		enabled = true,
		command = nil,
		config = nil,
	},
	mocha = {
		enabled = true,
		command = nil,
	},
	playwright = {
		enabled = true,
		command = nil,
		config = nil,
		configs = {},
		dynamic_test_discovery = false,
	},
	rust = {
		enabled = true,
	},
}

local function deepcopy(value)
	return vim.deepcopy(value)
end

function M.schema_defaults()
	return deepcopy(defaults)
end

local function normalize(path)
	return path and vim.fs.normalize(path) or nil
end

local function is_absolute(path)
	return type(path) == "string" and path:match("^/") ~= nil
end

local function join(...)
	return normalize(table.concat({ ... }, "/"))
end

local function path_exists(path)
	return path and uv.fs_stat(path) ~= nil
end

local function is_dir(path)
	local stat = path and uv.fs_stat(path) or nil
	return stat and stat.type == "directory" or false
end

local function read_file(path)
	if not path_exists(path) then
		return nil
	end

	local fd = uv.fs_open(path, "r", 438)
	if not fd then
		return nil
	end

	local stat = uv.fs_fstat(fd)
	if not stat then
		uv.fs_close(fd)
		return nil
	end

	local data = uv.fs_read(fd, stat.size, 0)
	uv.fs_close(fd)
	return data
end

local function decode_json(path)
	local data = read_file(path)
	if not data or data == "" then
		return nil
	end

	local ok, parsed = pcall(vim.json.decode, data)
	return ok and parsed or nil
end

local function current_path(path)
	if path and path ~= "" then
		return normalize(path)
	end

	local buf = vim.api.nvim_get_current_buf()
	local name = vim.api.nvim_buf_get_name(buf)
	if name ~= "" then
		return normalize(name)
	end

	return normalize(uv.cwd())
end

local function workspace_root(path)
	local resolved = current_path(path)
	local start = is_dir(resolved) and resolved or vim.fs.dirname(resolved)

	for _, markers in ipairs({
		{ ".neoconf.json" },
		{ "package.json", "Cargo.toml", "go.mod", "pyproject.toml", "Gemfile", "composer.json" },
		{ ".git" },
	}) do
		local found = vim.fs.find(markers, { path = start, upward = true })[1]
		if found then
			return normalize(vim.fs.dirname(found))
		end
	end

	return normalize(uv.cwd())
end

local function decode_jsonc(data)
	local ok_jsonc, jsonc = pcall(require, "neoconf.json.jsonc")
	if ok_jsonc then
		local ok, parsed = pcall(jsonc.decode_jsonc, data)
		return ok and parsed or nil
	end

	local ok, parsed = pcall(vim.json.decode, data)
	return ok and parsed or nil
end

local function local_neoconf(root)
	local file = join(root, ".neoconf.json")
	local stat = uv.fs_stat(file)
	local mtime = stat and stat.mtime and stat.mtime.sec or 0
	local cached = neoconf_cache[root]
	if cached and cached.mtime == mtime then
		return cached.data
	end

	local parsed = {}
	local data = read_file(file)
	if data and data ~= "" then
		parsed = decode_jsonc(data) or {}
	end

	neoconf_cache[root] = {
		mtime = mtime,
		data = parsed,
	}

	return parsed
end

local function relpath(root, path)
	local relative = vim.fs.relpath(root, path)
	return relative and normalize(relative) or normalize(path)
end

local function matches_override(override, path, root)
	local relative = relpath(root, path)

	if override.path and vim.startswith(relative, normalize(override.path)) then
		return true
	end

	if override.match and relative:match(override.match) then
		return true
	end

	return false
end

local function merged_settings(path)
	local root = workspace_root(path)
	local settings = deepcopy(defaults)
	local parsed = local_neoconf(root)
	settings = vim.tbl_deep_extend("force", settings, parsed.neotest or {})

	for _, override in ipairs(settings.overrides or {}) do
		if matches_override(override, current_path(path), root) then
			settings = vim.tbl_deep_extend("force", settings, override)
		end
	end

	settings.overrides = nil
	return settings, root
end

local function resolve_path(path, value, base)
	if not value or value == "" then
		return nil
	end

	if is_absolute(value) then
		return normalize(value)
	end

	return join(base or workspace_root(path), value)
end

local function resolve_command(path, value)
	if not value or value == "" then
		return nil
	end

	if value:find("%s") then
		return value
	end

	if is_absolute(value) or value:match("^%.") then
		return resolve_path(path, value, M.cwd(path))
	end

	return value
end

function M.cwd(path)
	local settings, root = merged_settings(path)
	return resolve_path(path, settings.cwd, root) or root or normalize(uv.cwd())
end

local function package_json(path)
	return decode_json(join(M.cwd(path), "package.json"))
end

local function has_dependency(path, names)
	local pkg = package_json(path)
	if not pkg then
		return false
	end

	local buckets = {
		pkg.dependencies,
		pkg.devDependencies,
		pkg.peerDependencies,
		pkg.optionalDependencies,
	}

	for _, bucket in ipairs(buckets) do
		if bucket then
			for _, name in ipairs(names) do
				if bucket[name] then
					return true
				end
			end
		end
	end

	return false
end

local function has_script(path, name, pattern)
	local pkg = package_json(path)
	if not (pkg and pkg.scripts and type(pkg.scripts[name]) == "string") then
		return false
	end

	return not pattern or pkg.scripts[name]:match(pattern) ~= nil
end

local function local_bin(path, name)
	local bin = join(M.cwd(path), "node_modules", ".bin", name)
	return path_exists(bin) and bin or name
end

local function is_test_file(path)
	return path:match("__tests__") or path:match("%.spec%.[cm]?[jt]sx?$") or path:match("%.test%.[cm]?[jt]sx?$")
end

local function parse_test_dir(config_path)
	local content = read_file(config_path)
	if not content then
		return nil
	end

	local relative = content:match("testDir%s*[:=]%s*['\"]([^'\"]+)['\"]")
	if not relative then
		return nil
	end

	return resolve_path(config_path, relative, vim.fs.dirname(config_path))
end

local function playwright_entries(path)
	local settings = merged_settings(path)
	local cwd = M.cwd(path)
	local configured = settings.playwright.configs or {}
	local entries = {}

	if settings.playwright.config then
		table.insert(entries, {
			config = resolve_path(path, settings.playwright.config, cwd),
			test_dir = settings.playwright.test_dir and resolve_path(path, settings.playwright.test_dir, cwd) or nil,
		})
	elseif #configured > 0 then
		for _, entry in ipairs(configured) do
			table.insert(entries, {
				config = resolve_path(path, entry.config, cwd),
				test_dir = entry.test_dir and resolve_path(path, entry.test_dir, cwd) or nil,
			})
		end
	else
		local handle = uv.fs_scandir(cwd)
		if handle then
			while true do
				local name, kind = uv.fs_scandir_next(handle)
				if not name then
					break
				end

				if kind == "file" and name:match("^playwright.*%.config%.[cm]?[jt]s$") then
					local config = join(cwd, name)
					table.insert(entries, {
						config = config,
						test_dir = parse_test_dir(config),
					})
				end
			end
		end
	end

	table.sort(entries, function(a, b)
		local a_default = vim.fs.basename(a.config):match("^playwright%.config%.")
		local b_default = vim.fs.basename(b.config):match("^playwright%.config%.")
		if a_default ~= b_default then
			return a_default and not b_default
		end
		return a.config < b.config
	end)

	if #entries == 1 and not entries[1].test_dir then
		entries[1].test_dir = cwd
	end

	return entries
end

local function path_in_dir(path, dir)
	local resolved_path = normalize(path)
	local resolved_dir = normalize(dir)
	return resolved_path
		and resolved_dir
		and (resolved_path == resolved_dir or vim.startswith(resolved_path, resolved_dir .. "/"))
end

function M.playwright_config(path)
	local entries = playwright_entries(path)
	local target = current_path(path)

	for _, entry in ipairs(entries) do
		if entry.test_dir and path_in_dir(target, entry.test_dir) then
			return entry.config
		end
	end

	return entries[1] and entries[1].config or nil
end

function M.playwright_command(path)
	local settings = merged_settings(path)
	return settings.playwright.command and resolve_command(path, settings.playwright.command)
		or local_bin(path, "playwright")
end

function M.playwright_discovery_target(path)
	local target = current_path(path)
	if M.has_playwright_project(target) then
		return target
	end

	for _, project in ipairs(M.workspace_projects(target)) do
		if M.has_playwright_project(project.root) then
			return project.root
		end
	end

	return target
end

function M.has_playwright_project(path)
	local settings = merged_settings(path)
	return settings.playwright.enabled ~= false and #playwright_entries(path) > 0
end

function M.is_playwright_file(path)
	if not M.has_playwright_project(path) or not is_test_file(path) then
		return false
	end

	local entries = playwright_entries(path)
	if #entries == 0 then
		return false
	end

	for _, entry in ipairs(entries) do
		if entry.test_dir and path_in_dir(path, entry.test_dir) then
			return true
		end
	end

	return #entries == 1 and entries[1].test_dir == M.cwd(path)
end

function M.vitest_command(path)
	local settings = merged_settings(path)
	return settings.vitest.command and resolve_command(path, settings.vitest.command) or local_bin(path, "vitest")
end

function M.has_vitest_project(path)
	local settings = merged_settings(path)
	return settings.vitest.enabled ~= false and has_dependency(path, { "vitest", "@vitest/ui", "@vitest/coverage-v8" })
end

function M.vitest_config(path)
	local settings = merged_settings(path)
	if settings.vitest.config then
		return resolve_path(path, settings.vitest.config, M.cwd(path))
	end

	for _, name in ipairs({
		"vitest.config.ts",
		"vitest.config.js",
		"vite.config.ts",
		"vite.config.js",
		"vitest.config.mts",
		"vitest.config.mjs",
		"vite.config.mts",
		"vite.config.mjs",
	}) do
		local candidate = join(M.cwd(path), name)
		if path_exists(candidate) then
			return candidate
		end
	end

	return nil
end

function M.is_vitest_file(path)
	if not M.has_vitest_project(path) or M.is_playwright_file(path) or not is_test_file(path) then
		return false
	end

	return true
end

function M.jest_command(path)
	local settings = merged_settings(path)
	return settings.jest.command and resolve_command(path, settings.jest.command) or local_bin(path, "jest")
end

function M.jest_config(path)
	local settings = merged_settings(path)
	if settings.jest.config then
		return resolve_path(path, settings.jest.config, M.cwd(path))
	end

	for _, name in ipairs({
		"jest.config.ts",
		"jest.config.js",
		"jest.config.cjs",
		"jest.config.mjs",
		"jest.config.json",
	}) do
		local candidate = join(M.cwd(path), name)
		if path_exists(candidate) then
			return candidate
		end
	end

	return nil
end

function M.has_jest_project(path)
	local settings = merged_settings(path)
	return settings.jest.enabled ~= false
		and (has_dependency(path, { "jest", "@jest/globals", "ts-jest" }) or has_script(path, "test", "jest"))
end

function M.is_jest_file(path)
	if not M.has_jest_project(path) or M.is_playwright_file(path) or not is_test_file(path) then
		return false
	end

	if M.is_vitest_file(path) then
		return false
	end

	return true
end

function M.mocha_command(path)
	local settings = merged_settings(path)
	return settings.mocha.command and resolve_command(path, settings.mocha.command) or local_bin(path, "mocha")
end

function M.has_mocha_project(path)
	local settings = merged_settings(path)
	return settings.mocha.enabled ~= false and (has_dependency(path, { "mocha" }) or has_script(path, "test", "mocha"))
end

function M.is_mocha_file(path)
	if not M.has_mocha_project(path) or M.is_playwright_file(path) or not is_test_file(path) then
		return false
	end

	if M.is_vitest_file(path) or M.is_jest_file(path) then
		return false
	end

	return true
end

function M.project_target(path)
	return M.cwd(path)
end

local function override_root(root, override)
	return resolve_path(root, override.cwd or override.path, root)
end

function M.use_workspace_projects(path)
	local root = workspace_root(path)
	local parsed = local_neoconf(root)
	local overrides = ((parsed or {}).neotest or {}).overrides or {}
	return normalize(current_path(path)) == root and #overrides > 0
end

function M.workspace_projects(path)
	local root = workspace_root(path)
	local parsed = local_neoconf(root)
	local projects = {}
	local seen = {}

	for _, override in ipairs(((parsed or {}).neotest or {}).overrides or {}) do
		local project_root = override_root(root, override)
		if project_root and is_dir(project_root) and not seen[project_root] then
			seen[project_root] = true
			projects[#projects + 1] = {
				root = project_root,
				match = override.match,
				path = override.path,
			}
		end
	end

	table.sort(projects, function(a, b)
		return a.root < b.root
	end)

	return projects
end

local function should_descend_dir(name)
	return name ~= ".git" and name ~= "node_modules"
end

local function scan_files(root, callback)
	local stack = { root }

	while #stack > 0 do
		local dir = table.remove(stack)
		local handle = uv.fs_scandir(dir)
		if handle then
			while true do
				local name, kind = uv.fs_scandir_next(handle)
				if not name then
					break
				end

				local full = join(dir, name)
				if kind == "directory" then
					if should_descend_dir(name) then
						stack[#stack + 1] = full
					end
				elseif kind == "file" then
					if callback(full) == true then
						return
					end
				end
			end
		end
	end
end

function M.workspace_seed_paths(path)
	local seeds = {}
	local seen = {}

	for _, project in ipairs(M.workspace_projects(path)) do
		local found = {
			vitest = false,
			jest = false,
			mocha = false,
			playwright = false,
		}

		scan_files(project.root, function(file)
			if not is_test_file(file) then
				return false
			end

			if not found.playwright and M.is_playwright_file(file) then
				found.playwright = true
				if not seen[file] then
					seen[file] = true
					seeds[#seeds + 1] = file
				end
			elseif not found.vitest and M.is_vitest_file(file) then
				found.vitest = true
				if not seen[file] then
					seen[file] = true
					seeds[#seeds + 1] = file
				end
			elseif not found.jest and M.is_jest_file(file) then
				found.jest = true
				if not seen[file] then
					seen[file] = true
					seeds[#seeds + 1] = file
				end
			elseif not found.mocha and M.is_mocha_file(file) then
				found.mocha = true
				if not seen[file] then
					seen[file] = true
					seeds[#seeds + 1] = file
				end
			end

			return found.playwright and found.vitest and found.jest and found.mocha
		end)
	end

	return seeds
end

function M.fix_subprocess_rtp()
	local ok_lib, lib = pcall(require, "neotest.lib")
	if not ok_lib then
		return
	end

	local ok_subprocess, subprocess = pcall(function()
		return lib.subprocess
	end)
	if not ok_subprocess or not subprocess then
		return
	end

	if not subprocess.enabled() then
		subprocess.init()
	end

	local paths = {}
	local lazy_root = join(vim.fn.stdpath("data"), "lazy")
	for _, name in ipairs({ "neotest-playwright", "nvim-treesitter" }) do
		local candidate = join(lazy_root, name)
		if path_exists(candidate) then
			table.insert(paths, candidate)
		end
	end

	if #paths > 0 then
		subprocess.add_paths_to_rtp(paths)
	end
end

return M
