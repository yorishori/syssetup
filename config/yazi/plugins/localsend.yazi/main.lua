-- Send the selected files (or the hovered one) with localsend-cli.
--
-- Shows a menu of the devices paired in localsend-cli, then sends headlessly
-- with `localsend-cli send --to <alias>`. The last menu entry opens the CLI's
-- own picker instead, for devices that are not paired yet (pair them there
-- with P when accepting a transfer, or from its device list).

local M = {}

-- Keys handed out to devices in order; "." is kept for the CLI picker entry.
local KEYS = "123456789abcdefghijklmnopqrstuvwxyz"
local CLI_PICKER_KEY = "."

local get_targets = ya.sync(function()
   local paths = {}
   for _, url in pairs(cx.active.selected) do
      paths[#paths + 1] = tostring(url)
   end
   if #paths == 0 and cx.active.current.hovered then
      paths[1] = tostring(cx.active.current.hovered.url)
   end
   return paths
end)

local function paired_file()
   local base = os.getenv("XDG_CONFIG_HOME")
   if not base or base == "" then
      base = os.getenv("HOME") .. "/.config"
   end
   return base .. "/localsend-cli/paired-v2.json"
end

-- Aliases of the paired devices, sorted and deduplicated. A missing or
-- unreadable file just means no paired devices yet.
local function paired_aliases()
   local output = Command("jq")
      :arg({ "-r", ".devices[]?.alias", paired_file() })
      :output()
   if not output or not output.status.success then
      return {}
   end

   local seen, aliases = {}, {}
   for alias in output.stdout:gmatch("[^\n]+") do
      if not seen[alias] then
         seen[alias] = true
         aliases[#aliases + 1] = alias
      end
   end
   table.sort(aliases)
   return aliases
end

local function notify(content, level)
   ya.notify { title = "LocalSend", content = content, timeout = 5, level = level or "info" }
end

-- Runs localsend-cli in the foreground, with yazi hidden until it exits.
local function run(args)
   local permit = ui.hide()
   local status, err = Command("localsend-cli")
      :arg(args)
      :stdin(Command.INHERIT)
      :stdout(Command.INHERIT)
      :stderr(Command.INHERIT)
      :status()
   permit:drop()

   if not status then
      notify("Could not run localsend-cli: " .. tostring(err), "error")
   end
   return status
end

function M:entry()
   local paths = get_targets()
   if #paths == 0 then
      return notify("Nothing to send", "warn")
   end

   local aliases = paired_aliases()
   local cands = {}
   for i, alias in ipairs(aliases) do
      if i > #KEYS then
         break
      end
      cands[#cands + 1] = { on = KEYS:sub(i, i), desc = alias }
   end
   cands[#cands + 1] = { on = CLI_PICKER_KEY, desc = "Other device (open localsend-cli picker)" }

   local choice = ya.which { cands = cands }
   if not choice then
      return
   end

   local args = { "send" }
   local alias = aliases[choice]
   if choice < #cands and alias then
      args[#args + 1] = "--to"
      args[#args + 1] = alias
   end
   args[#args + 1] = "--"
   for _, path in ipairs(paths) do
      args[#args + 1] = path
   end

   local status = run(args)
   if status and alias and choice < #cands then
      if status.success then
         notify(string.format("Sent %d item(s) to %s", #paths, alias))
      else
         notify(string.format("Sending to %s failed", alias), "error")
      end
   end
end

return M
