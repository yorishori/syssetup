local M = {}

local function owner_of(url)
   local output = Command("stat"):arg({ "-c", "%U:%G", "--", tostring(url) }):output()
   if output and output.status.success then
      return (output.stdout:gsub("%s+$", ""))
   end
   return "-"
end

local function dir_stats(url)
   local entries = fs.read_dir(url, {}) or {}

   local it, size = fs.calc_size(url), 0
   while it do
      local chunk = it:recv()
      if not chunk then
         break
      end
      size = size + chunk
   end

   return #entries, size
end

function M:spot(job)
   local cha = job.file.cha
   local url = job.file.url

   local rows = {
      ui.Row({ "Info" }):style(ui.Style():fg("green")),
      ui.Row { "  Permissions:", cha:perm() or "-" },
      ui.Row { "  Owner:", owner_of(url) },
   }

   if cha.is_dir then
      local count, size = dir_stats(url)
      rows[#rows + 1] = ui.Row { "  Items:", tostring(count) }
      rows[#rows + 1] = ui.Row { "  Size:", ya.readable_size(size) }
   else
      rows[#rows + 1] = ui.Row { "  Size:", ya.readable_size(cha.len) }
   end

   rows[#rows + 1] = ui.Row {}
   rows[#rows + 1] = ui.Row({ "Base" }):style(ui.Style():fg("green"))
   rows[#rows + 1] =
      ui.Row { "  Created:", cha.btime and os.date("%Y-%m-%d %H:%M:%S", math.floor(cha.btime)) or "-" }
   rows[#rows + 1] =
      ui.Row { "  Modified:", cha.mtime and os.date("%Y-%m-%d %H:%M:%S", math.floor(cha.mtime)) or "-" }
   rows[#rows + 1] = ui.Row { "  Mimetype:", job.mime }

   ya.spot_table(
      job,
      ui.Table(rows)
         :area(ui.Pos { "center", w = 60, h = 20 })
         :row(1)
         :col(1)
         :col_style(th.spot.tbl_col)
         :cell_style(th.spot.tbl_cell)
         :widths { ui.Constraint.Length(14), ui.Constraint.Fill(1) }
   )
end

return M
