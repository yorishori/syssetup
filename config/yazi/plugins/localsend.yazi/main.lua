-- Send the selected files (or the hovered one) with localsend-cli.
--
-- Opens localsend-cli's own device list with the files preselected
-- (`localsend-cli -f <file> ...`); picking a device starts the transfer and
-- the CLI exits when it is done, handing the terminal back to yazi.
--
-- localsend-cli 1.18.x only sends regular files in this mode, so directories
-- are refused here instead of letting the CLI fail.

local M = {}

local get_targets = ya.sync(function()
   local targets = {}
   for _, url in pairs(cx.active.selected) do
      targets[#targets + 1] = tostring(url)
   end
   if #targets == 0 and cx.active.current.hovered then
      targets[1] = tostring(cx.active.current.hovered.url)
   end
   return targets
end)

local function notify(content, level)
   ya.notify { title = "LocalSend", content = content, timeout = 5, level = level or "info" }
end

function M:entry()
   local targets = get_targets()
   if #targets == 0 then
      return notify("Nothing to send", "warn")
   end

   local args = {}
   for _, path in ipairs(targets) do
      local cha = fs.cha(Url(path), true)
      if not cha or cha.is_dir then
         return notify("Only files can be sent, not directories: " .. path, "warn")
      end
      args[#args + 1] = "-f"
      args[#args + 1] = path
   end

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
   elseif not status.success then
      notify("localsend-cli exited with an error", "error")
   end
end

return M
