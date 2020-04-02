local BASE_PATH = "pac3/"
local ICON_FILE = "icon16/group_add.png"
local ICON_FOLDER = "icon16/folder.png"

local blacklist = {
	["objcache"] = true,
	["__backup"] = true,
	["__backup_save"] = true,
	["__animations"] = true,
}

local frame = vgui.Create("DFrame")
frame:SetSize(ScrW() * 0.35, ScrH() * 0.45)
frame:Center()
frame:MakePopup()
frame:SetTitle("PAC Link Changer")

local box = frame:Add("DPanel")
box:Dock(TOP)

local textentry = box:Add("DTextEntry")
textentry:Dock(LEFT)
textentry:SetWide(frame:GetWide() * 0.8)

local scroll = frame:Add("DScrollPanel")
scroll:Dock(FILL)
scroll:DockMargin(0, 25, 0, frame:GetTall() * 0.1)
scroll:GetCanvas().Paint = function(pnl, w, h)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, w, h)
end

local cached_urls = {}
local function recursiveLinkFinder(tbl)
	for k, v in pairs(tbl) do
		if istable(v) then
			recursiveLinkFinder(v)
		elseif isstring(v) then
			if v:match("https?://[^%s%\"]+") then
				if cached_urls[v] then
					if #cached_urls[v].tbls > 1 then
						cached_urls[v].label:SetText("Multiple")
						--local str = table.concat(cached_urls[v].classes, ", ")
						--cached_urls[v].label:SetTooltip(str)
					end
					table.insert(cached_urls[v].classes, tbl.ClassName)
					table.insert(cached_urls[v].tbls, tbl)
					return
				end
				local box = scroll:Add("DPanel")
				box:Dock(TOP)

				local label = box:Add("DLabel")
				if cached_urls[v] then
					print(cached_urls[v].tbls)
				end

				label:SetText(tbl.ClassName[1]:upper() .. tbl.ClassName:sub(2))
				label:Dock(LEFT)
				label:SetContentAlignment(5)
				label:SetTextColor(Color(0, 0, 0))

				local textentry = box:Add("DTextEntry")
				textentry.tbls = {}
				table.insert(textentry.tbls, tbl)
				textentry.label = label
				textentry.classes = {}
				table.insert(textentry.classes, tbl.ClassName)
				textentry:SetText(v)
				textentry:Dock(FILL)
				textentry:DockMargin(0, 0, 0, 5)
				textentry:SetUpdateOnType(true)
				cached_urls[v] = textentry

				textentry.original = v
				textentry.OnValueChange = function(self, value)
					if textentry.original == value then
						self:SetTextColor(Color(0, 0, 0))
					else
						self:SetTextColor(Color(255, 0, 0))
					end
				end
				textentry.OnEnter = function(self)
					for _, tbl in ipairs(self.tbls) do
						tbl[k] = self:GetText()
					end
					self:SetTextColor(Color(255, 200, 0))
					if self.original ~= self:GetText() then
						self:SetTooltip("Before: " .. v)
					else
						self:SetToolTip(false)
					end
				end
				textentry.OnFocusChanged = function(self, focus)
					if not focus and self.original ~= self:GetText() then
						self:OnEnter()
					end
				end

				box.textentry = textentry
				box.label = label
			end
		end
	end
end

local loaded_pac
local loaded_path
local load = box:Add("DButton")
load:Dock(RIGHT)
load:DockMargin(0, 0, 0, 0)
load:SetWide((frame:GetWide() - textentry:GetWide()) / 2)
load:SetText("Load")
load.DoClick = function()
	if textentry:GetText() == "" then return end
	assert(file.Exists(textentry:GetText(), "DATA"), "file does not exist?")

	loaded_pac = pace.luadata.ReadFile(textentry:GetText(), "DATA")
	scroll:Clear()
	recursiveLinkFinder(loaded_pac)
	cached_urls = {}
	frame.save:SetDisabled(false)
end

local browse = box:Add("DButton")
browse:Dock(RIGHT)
browse:DockMargin(0, 0, 0, 0)
browse:SetWide(load:GetWide() - 10) --+ 20)
browse:SetText("Browse")

local function recursiveMenu(path, menu)
	local files, dirs = file.Find(BASE_PATH .. path .. "*", "DATA")

	for _, dir in ipairs(dirs) do
		if blacklist[dir] then continue end

		local m, icon = menu:AddSubMenu(dir)
		icon:SetImage(ICON_FOLDER)
		recursiveMenu(dir .. "/", m)
	end

	for _, file in ipairs(files) do
		menu:AddOption(file, function() textentry:SetText(BASE_PATH .. path .. file) end):SetImage(ICON_FILE)
	end
end

browse.DoClick = function()
	local menu = DermaMenu()
	recursiveMenu("", menu)
	menu:Open()
end

local save = frame:Add("DButton")
save:Dock(BOTTOM)
save:SetText("Save")
save:SetDisabled(true)
save.DoClick = function(self)
	if self:GetDisabled() then return end

	for k, tbl in ipairs(scroll:GetCanvas():GetChildren()) do
		tbl.textentry:SetTextColor(Color(0, 255, 0))
	end
	pace.luadata.WriteFile(textentry:GetText(), loaded_pac)
end

frame.save = save