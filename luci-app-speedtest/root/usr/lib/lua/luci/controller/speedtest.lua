-- LuCI controller for the better-speedtest front-end.
--
-- Written against the luci-lua-runtime compat shim shipped by LuCI 26.x
-- (OpenWrt 25.12+), and still valid on the classic Lua dispatcher of
-- OpenWrt <= 24.10. Note: with the ucode dispatcher, any error raised
-- here while building the page tree breaks the WHOLE of LuCI, so this
-- file must stay defensively simple and syntax-clean.

module("luci.controller.speedtest", package.seeall)

local http = require "luci.http"
local util = require "luci.util"
local uci  = require "luci.model.uci"

local BACKEND = "/usr/libexec/speedtest/backend"

local function shell_quote(s)
	-- safe single-quote wrapper for POSIX sh (no embedded single quotes allowed)
	s = tostring(s):gsub("'", "")
	return "'" .. s .. "'"
end

local function exec_json(...)
	local parts = { BACKEND }
	local _, a
	for _, a in ipairs({...}) do
		-- keep empty strings as '' (a flag/value pair must stay paired: an
		-- empty --node used to be dropped, making --node swallow --dur and
		-- failing every auto start). Only truly-nil args are skipped.
		if a ~= nil then
			parts[#parts + 1] = " " .. shell_quote(a)
		end
	end
	local out = util.exec(table.concat(parts)) or ""
	out = util.trim(out)
	if out == "" then
		return '{"ok":false,"error":"后端无输出"}'
	end
	return out
end

function index()
	entry({"admin", "network", "speedtest"},
		template("speedtest/index"), _("网络测速"), 60)

	-- API endpoints (GET-based so they work across LuCI versions without
	-- CSRF-token plumbing; they are still protected by the admin session).
	-- NOTE: `.leaf` must be set on its own statement - the old
	-- `page = entry(...).leaf = true` form is a Lua syntax error and used
	-- to take the whole LuCI down at page-tree build time.
	local _, name
	for _, name in ipairs({
		"status", "start", "stop", "log", "nodes", "ip", "config",
		"errlog", "version",
	}) do
		local endpoint = entry({"admin", "network", "speedtest", name},
			call("action_" .. name), nil)
		endpoint.leaf = true
	end
end

function action_status()
	http.prepare_content("application/json; charset=utf-8")
	http.write(exec_json("status"))
end

function action_log()
	local f = io.open("/tmp/speedtest/run.ndjson", "r")
	local body = f and f:read("*a") or ""
	if f then f:close() end
	http.prepare_content("text/plain; charset=utf-8")
	http.write(body)
end

function action_start()
	local src   = http.formvalue("src") or "auto"
	local node  = (http.formvalue("node") or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local dur   = http.formvalue("dur") or "10"
	local mode  = http.formvalue("mode") or "both"
	local multi = http.formvalue("multi") or "1"
	http.prepare_content("application/json; charset=utf-8")
	http.write(exec_json("start",
		"--src", src,
		"--node", node,
		"--dur", dur,
		"--mode", mode,
		"--multi", multi))
end

function action_stop()
	http.prepare_content("application/json; charset=utf-8")
	http.write(exec_json("stop"))
end

function action_nodes()
	local src = http.formvalue("src") or "all"
	http.prepare_content("application/json; charset=utf-8")
	http.write(exec_json("nodes", "--src", src))
end

function action_ip()
	http.prepare_content("application/json; charset=utf-8")
	http.write(exec_json("ip"))
end

function action_errlog()
	http.prepare_content("text/plain; charset=utf-8")
	http.write(exec_json("errlog"))
end

function action_version()
	http.prepare_content("text/plain; charset=utf-8")
	http.write(exec_json("version"))
end

function action_config()
	local u = uci.cursor()
	local c = {}
	local _, k
	for _, k in ipairs({"src", "dur", "mode", "multi", "node", "wan_iface"}) do
		c[k] = u:get("speedtest", "defaults", k) or ""
	end
	http.prepare_content("application/json; charset=utf-8")
	http.write_json(c)
end
