local sadb
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SoundAlerter")
local self, SoundAlerter = SoundAlerter, SoundAlerter

local function initOptions()
	if SoundAlerter.options.args.general then
		return
	end
	SoundAlerter:OnOptionsCreate()
	for k, v in SoundAlerter:IterateModules() do
		if type(v.OnOptionsCreate) == "function" then
			v:OnOptionsCreate()
		end
	end
	AceConfig:RegisterOptionsTable("SoundAlerter", SoundAlerter.options)
end
function SoundAlerter:ShowConfig()
	initOptions()
	AceConfigDialog:Open("SoundAlerter")
end

function SoundAlerter:ChangeProfile()
	sadb = self.db1.profile
	for k,v in SoundAlerter:IterateModules() do
		if type(v.ChangeProfile) == 'function' then
			v:ChangeProfile()
		end
	end
end

function SoundAlerter:AddOption(key, table)
	self.options.args[key] = table
end

local function setOption(info, value)
	local name = info[#info]
	sadb[name] = value
	PlaySoundFile(sadb.sapath..name..".mp3");
end
local function getOption(info)
	local name = info[#info]
	return sadb[name]
end

function listOption(spellList, listType, ...)
	local args = {}
	for k,v in pairs(spellList) do
		if SoundAlerter.spellList[listType][v] then
			rawset(args, SoundAlerter.spellList[listType][v], self:spellOptions(k, v))
		else
			print(v)
		end
	end
	return args
end

function SpellTexture(sid)
	local spellname,_,icon = GetSpellInfo(sid)
	if spellname ~= nil then
		return "\124T"..icon..":24\124t"
	end
end

function SpellTextureName(sid)
	local spellname,_,icon = GetSpellInfo(sid)
	if spellname ~= nil then
		return "\124T"..icon..":24\124t"..spellname
	end
end

function SoundAlerter:OnOptionsCreate()
	sadb = self.db1.profile
	self:AddOption("profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db1))
	self.options.args.profiles.order = -1
	self:AddOption('General', {
		type = 'group',
		name = L["General"],
		desc = L["General Options"],
		order = 1,
		args = {
			enableArea = {
				type = 'group',
				inline = true,
				name = L["General Options"],
				set = setOption,
				get = getOption,
				args = {
					all = {
						type = 'toggle',
						name = L["Enable Everything"],
						desc = L["Enables Sound Alerter for BGs, world and arena"],
						order = 1,
					},
					arena = {
						type = 'toggle',
						name = L["Arena"],
						desc = L["Enabled in the arena"],
						disabled = function() return sadb.all end,
						order = 2,
					},
					battleground = {
						type = 'toggle',
						name = L["Battleground"],
						desc = L["Enable Battleground"],
						disabled = function() return sadb.all end,
						order = 3,
					},
					field = {
						type = 'toggle',
						name = L["World"],
						desc = L["Enabled outside Battlegrounds and arenas"],
						disabled = function() return sadb.all end,
						order = 4,
					},
					AlertConditions = {
						type = 'group',
						inline = true,
						order = 9,
						name = L["Alert Conditions"],
						args = {
							myself = {
								type = 'toggle',
								name = L["Target and Focus only"],
								disabled = function() return sadb.enemyinrange end,
								desc = L["Alert works only when your current target casts a spell, or an enemy casts a spell on you"],
								order = 5,
							},
							enemyinrange = {
								type = 'toggle',
								name = L["All Enemies in Range"],
								desc = L["Alerts are enabled for all enemies in range"],
								disabled = function() return sadb.myself end,
								order = 6,
							},
						},
					},
					volumecontrol = {
						type = 'group',
						inline = true,
						order = 10,
						name = L["Volume Control"],
						args = {
							volumn = {
								type = 'range',
								max = 1,
								min = 0,
								isPercent = true,
								step = 0.1,
								name = L["Master Volume"],
								desc = L["Sets the master volume so sound alerts can be louder/softer"],
								set = function (info, value) SetCVar ("Sound_MasterVolume",tostring (value)) end,
								get = function () return tonumber (GetCVar ("Sound_MasterVolume")) end,
								order = 1,
							},
							volumn2 = {
								type = 'execute',
								width = 'normal',
								name = L["Addon sounds only"],
								desc = L["Sets other sounds to minimum, only hearing the addon sounds"],
								func = function() 
										SetCVar ("Sound_AmbienceVolume",tostring ("0")); SetCVar ("Sound_SFXVolume",tostring ("0")); SetCVar ("Sound_MusicVolume",tostring ("0")); 
										print("|cffFF7D0ASoundAlerter|r: Addons will only be heard by your Client. To undo this, click the 'reset sound options' button.");
									end,
								order = 2,
							},
							volumn3 = {
								type = 'execute',
								width = 'normal',
								name = L["Reset volume options"],
								desc = L["Resets sound options"],
								func = function() 
										SetCVar ("Sound_MasterVolume",tostring ("1")); SetCVar ("Sound_AmbienceVolume",tostring ("1")); SetCVar ("Sound_SFXVolume",tostring ("1")); SetCVar ("Sound_MusicVolume",tostring ("1")); 
										print("|cffFF7D0ASoundAlerter|r: Sound options reset.");
									end,
								order = 3,
							},
							sapath = {
								type = 'select',
								name = L["Language"],
								desc = L["Language of Sounds"],
								values = self.SA_LANGUAGE,
								order = 3,
							},
						},
					},
					advance = {
						type = 'group',
						inline = true,
						name = L["Advanced options"],
						order = 11,
						args = {
							debugmode = {
								type = 'toggle',
								name = L["Debug Mode"],
								desc = L["Enable Debugging"],
								order = 3,
							},
						},
					},
					debugopts = {
						type = 'group',
						inline = true,
						order = 11,
						hidden = function() return not sadb.debugmode end,
						name = L["Debug options"],
						args = {
							cspell = {
								type = 'input',
								name = L["Custom spells entry name"],
								order = 1,
							},
							spelldebug = {
								type = 'toggle',
								name = L["Spell ID output debugging"],
								order = 2,
							},
							csname = {
								type = 'input',
								name = L["Spell Name"],
								order = 2,
							},
						},
					},
					importexport = {
						type = 'group',
						inline = true,
						hidden = function() return not sadb.debugmode end,
						name = L["Import/Export"],
						desc = L["Import or export custom sound alerts"],
						order = 12,
						args = {
							import = {
								type = 'execute',
								name = L["Import custom sound alerts"],
								order = 1,
								confirm = true,
								confirmText = L["Are you sure? This will remove all of your current sound alerts"],
								func = function()
									sadb.custom = nil
								end,
							},
							export = {
								type = 'execute',
								name = L["Export encapsulation"],
								order = 2,
								func = function()
								local thisw = "@"
									for k,css in pairs (sadb.custom) do
										thisw = thisw.."|"..css.name..","..css.soundfilepath..","..(css.spellid and css.spellid or "0")..","
										for j,l in pairs (sadb.custom[k].eventtype) do
											thisw = thisw..j..","..tostring(l)..","
										end
									end
									sadb.exportbox = thisw.."#"
								end,
							},
							exportbox = {
								type = 'input',
								name = L["Export custom sound alerts"],
								order = 3,
							},
						},
					}
				},
			},
		}
	})
	self:AddOption('Spells', {
		type = 'group',
		name = L["Spells"],
		desc = L["Spell Options"],
		order = 2,
		args = {
			spellGeneral = {
				type = 'group',
				name = L["Spell Disables"],
				desc = L["Enable certain spell types"],
				inline = true,
				set = setOption,
				get = getOption,
				order = -1,
				args = {
					aruaApplied = {
						type = 'toggle',
						name = L["Disable buff applied"],
						desc = L["Disables sound notifications of buffs applied"],
						order = 1,
					},
					auraRemoved = {
						type = 'toggle',
						name = L["Disable Buff down"],
						desc = L["Disables sound notifications of buffs down"],
						order = 2,
					},
					castStart = {
						type = 'toggle',
						name = L["Disable spell casting"],
						desc = L["Disables spell casting notifications"],
						order = 3,
					},
					castSuccess = {
						type = 'toggle',
						name = L["Disable enemy cooldown abilities"],
						desc = L["Disbles sound notifications of cooldown abilities"],
						order = 4,
					},
					chatalerts = {
						type = 'toggle',
						name = L["Disable Chat Alerts"],
						desc = L["Disbles Chat notifications of special abilities in the chat bar"],
						order = 5,
					},
					interrupt = {
						type = 'toggle',
						name = L["Disable Interrupted Spells"],
						desc = L["Check this option to disable notifications of friendly interrupted spells"],
						order = 6,
					},
					dSelfDebuff = {
						type = 'toggle',
						name = L["Disable Self Debuff alerts"],
						desc = L["Check this option to disable notifications of self debuff/CC alerts"],
						order = 7,
					},
					dArenaPartner = {
						type = 'toggle',
						name = L["Disable Arena Partner debuff/CC alerts"],
						desc = L["Check this option to disable notifications of Arena Partner debuff/CC alerts"],
						order = 8,
					},
					dEnemyDebuff = {
						type = 'toggle',
						name = L["Disable Enemy Debuff alerts"],
						desc = L["Check this option to disable notifications of enemy debuff/CC alerts"],
						order = 9,
					},
					dEnemyDebuffDown = {
						type = 'toggle',
						name = L["Disable Enemy Debuff down alerts"],
						desc = L["Check This option to disable notifications of enemy debuff/CC alerts"],
						order = 10,
					},
				},
			},
			chatalerter = {
				type = 'group',
				name = L["Chat Alerts"],
				desc = L["Alerts you and others via sending a chat message"],
				disabled = function() return sadb.chatalerts end,
				set = setOption,
				get = getOption,
				order = 1,
				args = {
					caonlyTF = {
						type = 'toggle',
						name = L["Target and Focus only"],
						desc = L["Alerts you when your target or focus is applicable to a sound alert"],
						order = 1,
					},
					chatgroup = {
						type = 'select',
						name = L["What channel to alert in"],
						desc = L["You send a message to either party, raid, say or battleground with your chat alert"],
						values = self.SA_CHATGROUP,
						order = 2,
					},
					spells = {
						type = 'group',
						inline = true,
						name = L["Spells"],
						order = 3,
						args = {
							interruptenemy = {
								type = 'toggle',
								name = L["Interrupt on Enemy"],
								desc = L["Sends a chat message if you have interrupted an enemy's spell."],
								order = 1,
							},
							interruptself = {
								type = 'toggle',
								name = L["Interrupt on Self"],
								desc = L["Sends a chat message if an enemy has interrupted you."],
								order = 2,
							},
							stealthenemy = {
								type = 'toggle',
								name = SpellTextureName(1784),
								desc = function ()
									GameTooltip:SetHyperlink(GetSpellLink(1784));
								end,
								order = 3,
							},
							vanishenemy = {
								type = 'toggle',
								name = SpellTextureName(26889),
								desc = L["Enemies that have casted Vanish will be alerted"],
								order = 4,
							},
							blindenemy = {
								type = 'toggle',
								name = SpellTexture(2094)..L["Blind on Enemy"],
								desc = L["Enemies you blind will be alerted in chat"],
								order = 5,
							},
							blindselffriend = {
								type = 'toggle',
								name = SpellTexture(2094)..L["Blind on Self/Friend"],
								desc = L["Enemies that have blinded you will be alerted"],
								order = 6,
							},
							sapenemy = {
								type = 'toggle',
								name = SpellTexture(6770)..L["Sap on Enemy"],
								desc = L["Enemies you sapped will be alerted"],
								order = 7,
							},
							sapselffriend = {
								type = 'toggle',
								name = SpellTexture(6770)..L["Sap on Self/friend"],
								desc = L["Enemies You sap will be alerted in chat"],
								order = 8,
							},
							cycloneenemy = {
								type = 'toggle',
								name = SpellTexture(33786)..L["Cyclone on Enemy"],
								desc = L["Enemies you cyclone will be alerted in chat"],
								order = 9,
							},
							cycloneselffriend = {
								type = 'toggle',
								name = SpellTexture(33786)..L["Cyclone on Self/Friend"],
								desc = L["Enemies You cyclone will be alerted in chat"],
								order = 10,
							},
							hexenemy = {
								type = 'toggle',
								name = SpellTexture(51514)..L["Hex on Enemy"],
								desc = L["Enemies you hex will be alerted in chat"],
								order = 11,
							},
							hexselffriend = {
								type = 'toggle',
								name = SpellTexture(51514)..L["Hex on Self/Friend"],
								desc = L["Enemies You hex will be alerted in chat"],
								order = 12,
							},
							fearenemy = {
								type = 'toggle',
								name = SpellTexture(5484)..L["Fear on Enemy"],
								desc = L["Enemies you fear will be alerted in chat"],
								order = 13,
							},
							fearselffriend = {
								type = 'toggle',
								name = SpellTexture(5484)..L["Fear on Self/friend"],
								desc = L["Enemies You fear will be alerted in chat"],
								order = 14,
							},
							polyenemy = {
								type = 'toggle',
								name = SpellTextureName(118),
								desc = L["Enemies that have casted Polymorph will be alerted"],
								order = 15,
							},
							bubbleenemy = {
								type = 'toggle',
								name = SpellTextureName(642),
								desc = L["Enemies that have casted Divine Shield will be alerted"],
								order = 16,
							},
							chatdownself = {
								type = 'toggle',
								name = L["Alert enemy debuff down (from self)"],
								desc = L["Sends a chat message when an enemies debuff is down that came from yourself (eg. Hex down)"],
								order = 17,
							},
							chatdownfriend = {
								type = 'toggle',
								name = L["Alert enemy debuff down (from friend)"],
								desc = L["Sends A chat message when an enemies debuff is down that came from yourself (eg. Hex down)"],
								order = 18,
							},
							trinketalert = {
								type = 'toggle',
								name = GetSpellInfo(42292),
								desc = function ()
									GameTooltip:SetHyperlink(GetSpellLink(42292));
								end,
								order = 19,
							},
						},
					},
					general = {
						type = "group",
						inline = true,
						name = L["General Chat Alerts"],
						args = {
							enemychat = {
								type = "input",
								name = L["To Enemy"],
								desc = L["Example: '#spell# up on #enemy#' = [Blind] up on Enemyname"],
								order = 1,
								width = "full",
							},
							friendchat = {
								type = "input",
								name = L["From Enemy to friend"],
								desc = L["Example: '#enemy# casted #spell# on #target# = Enemyname casted [Blind] on FriendName"],
								order = 2,
								width = "full",
							},
							selfchat = {
								type = "input",
								name = L["From Enemy to self"],
								desc = L["Example: '#enemy# casted #spell# on #target# = Enemyname casted [Blind] on FriendName"],
								order = 3,
								width = "full",
							},
							enemybuffchat = {
								type = "input",
								name = L["Enemy buffs/cooldowns"],
								desc = L["Example: '#enemy# casted #spell#  = Enemyname casted [Stealth]"],
								order = 4,
								width = "full",
							},
						},
					},
					saptextfriendg = {
						type = "group",
						inline = true,
						hidden = function() if sadb.sapselffriend then return false else return true end end,
						name = SpellTexture(6770)..L["Sap on self/friend"],
						order = 13,
						args = {
							sapselftext = {
								type = "input",
								name = L["Sap on Self (Avoid using '#enemy# due to unknown enemy when stealthed)"],
								order = 1,
								width = "full",
							},
							sapfriendtext = {
								type = "input",
								name = L["Sap on Friend (Avoid using '#enemy# due to unknown enemy when stealthed)"],
								order = 1,
								width = "full",
							},
						},
					},
					trinketalerttextg = {
						type = "group",
						inline = true,
						hidden = function() if sadb.trinketalert then return false else return true end end,
						name = L["PvP trinket text"],
						order = 14,	
						args = {
							trinketalerttext = {
								type = 'input',
								name = L["Example: '#enemy# casted #spell#!' = Enemyname casted [PvP Trinket]!"],
								order = 1,
								width = "full",
							},
						},
					},
					stealthalerttextg = {
						type = "group",
						inline = true,
						hidden = function() if sadb.stealthenemy then return false else return true end end,
						name = SpellTextureName(1784),
						order = 15,
						args = {
							stealthTF = {
								type = 'toggle',
								name = L["Ignore target/focus"],
								order = 2,
							},
						},
					},
					vanishalerttextg = {
						type = "group",
						inline = true,
						hidden = function() if sadb.vanishenemy then return false else return true end end,
						name = SpellTextureName(26889),
						order = 16,	
						args = {
							vanishTF = {
								type = 'toggle',
								name = L["Ignore target/focus"],
								order = 2,
							},
						},
					},
					bubblealerttextg = {
						type = "group",
						inline = true,
						hidden = function() if sadb.bubbleenemy then return false else return true end end,
						name = SpellTextureName(642),
						order = 17,	
						args = {
							bubbleTF = {
								type = 'toggle',
								name = L["Ignore target/focus"],
								order = 2,
							},
						},
					},
					InterruptTextg = {
						type = "group",
						inline = true,
						name = L["Interrupt Text"],
						order = 18,
						args = {
							InterruptEnemyText = {
								name = L["Interrupt on Enemy (eg. 'Interrupted #enemy# with #spell#')"],
								hidden = function() if sadb.interruptenemy then return false else return true end end,
								type = "input",
								order = 1,
								width = "full",
							},
							InterruptSelfText = {
								name = L["Interrupts from Enemy (eg. '#enemy# interrupted me with #spell#')"],
								hidden = function() if sadb.interruptself then return false else return true end end,
								type = "input",
								order = 1,
								width = "full",
							},
						},
					},
				},
			},
			spellauraApplied = {
				type = 'group',
				--inline = true,
				name = L["Enemy Buffs"],
				desc = L["Alerts you when your enemy gains a buff, or uses a cooldown"],
				set = setOption,
				get = getOption,
				disabled = function() return sadb.aruaApplied end,
				order = 2,
				args = {
					class = {
						type = 'toggle',
						name = L["Alert Class calling for trinketting in Arena"],
						desc = L["Alert when an enemy class trinkets in arena"],
						confirm = function() PlaySoundFile(sadb.sapath.."Paladin.mp3"); self:ScheduleTimer("PlayTrinket", 0.4); end,
						order = 2,
					},
					drinking = {
						type = 'toggle',
						name = L["Alert Drinking in Arena"],
						desc = L["Alert when an enemy drinks in arena"],
						order = 3,
					},
					general = {
						type = 'group',
						inline = true,
						name = L["General Spells"],
						order = 4,
						args = {
							trinket = {
								type = 'toggle',
								name = SpellTexture(42292)..L["PvP Trinket/Every Man for Himself"],
								desc = function ()
									GameTooltip:SetHyperlink(GetSpellLink(42292));
								end,
								descStyle = "custom",
								order = 1,
							},
						}
					},
					druid = {
						type = 'group',
						inline = true,
						name = L["|cffFF7D0ADruid|r"],
						order = 5,
						args = listOption({61336,29166,22812,17116,53312,22842,53201,50334,33357},"auraApplied"),	
					},
					paladin = {
						type = 'group',
						inline = true,
						name = L["|cffF58CBAPaladin|r"],
						order = 6,
						args = listOption({31821,10278,1044,642,6940,498,64205,54428},"auraApplied")
					},
					rogue = {
						type = 'group',
						inline = true,
						name = L["|cffFFF569Rogue|r"],
						order = 7,
						args = listOption({11305,14177,51713,31224,13750,26669},"auraApplied")
					},
					warrior	= {
						type = 'group',
						inline = true,
						name = L["|cffC79C6EWarrior|r"],
						order = 8,
						args = listOption({1719,55694,871,12975,18499,20230,23920,12328,46924,12292},"auraApplied")
					},
					priest	= {
						type = 'group',
						inline = true,
						name = L["|cffFFFFFFPriest|r"],
						order = 9,
						args = listOption({33206,10060,6346,47585,14751,47788},"auraApplied")
					},
					shaman	= {
						type = 'group',
						inline = true,
						name = L["|cff0070DEShaman|r"],
						order = 10,
						args = listOption({57960,49284,16188,16166,30823},"auraApplied"),
					},
					mage = {
						type = 'group',
						inline = true,
						name = L["|cff69CCF0Mage|r"],
						order = 11,
						args = listOption({45438,12042,12472,12043,28682},"auraApplied"),
					},
					dk	= {
						type = 'group',
						inline = true,
						name = L["|cffC41F3BDeath Knight|r"],
						order = 12,
						args = listOption({49039,48792,55233,48707,49222,49016},"auraApplied"),
					},
					hunter = {
						type = 'group',
						inline = true,
						name = L["|cffABD473Hunter|r"],
						order = 13,
						args = listOption({34471,19263,53480},"auraApplied"),
					},
					warlock	= {
						type = 'group',
						inline = true,
						name = L["|cff9482C9Warlock|r"],
						order = 14,
						args = listOption({17941},"auraApplied"),
					},
					races = {
						type = 'group',
						inline = true,
						name = L["|cffFFFFFFGeneral Races|r"],
						order = 15,
						args = listOption({316254,316405,316231,316380,316372,316413,316243,316271,316289,316294},"auraApplied"),
					},
				}
			},
			spellAuraRemoved = {
				type = 'group',
				--inline = true,
				name = L["Enemy Buff Down"],
				desc = L["Alerts you when enemy buffs or used cooldowns are off the enemy"],
				set = setOption,
				get = getOption,
				disabled = function() return sadb.auraRemoved end,
				order = 3,
				args = {
					druid = {
						type = 'group',
						inline = true,
						name = L["|cffFF7D0ADruid|r"],
						order = 4,
						args = listOption({53201},"auraRemoved"),
					},
					paladin = {
						type = 'group',
						inline = true,
						name = L["|cffF58CBAPaladin|r"],
						order = 5,
						args = listOption({498,10278,642},"auraRemoved"),
					},
					rogue = {
						type = 'group',
						inline = true,
						name = L["|cffFFF569Rogue|r"],
						order = 6,
						args = listOption({31224,26669},"auraRemoved"),
					},
					warrior = {
						type = 'group',
						inline = true,
						name = L["|cffC79C6EWarrior|r"],
						order = 7,
						args = listOption({1719,871,12292,46924,20230},"auraRemoved"),
					},
					priest	= {
						type = 'group',
						inline = true,
						name = L["|cffFFFFFFPriest|r"],
						order = 8,
						args = listOption({47585,33206},"auraRemoved"),
					},
					mage = {
						type = 'group',
						inline = true,
						name = L["|cff69CCF0Mage|r"],
						order = 10,
						args = listOption({45438},"auraRemoved"),
					},
					dk = {
						type = 'group',
						inline = true,
						name = L["|cffC41F3BDeath Knight|r"],
						order = 11,
						args = listOption({48707,48792,49039},"auraRemoved"),
					},
					hunter = {
						type = 'group',
						inline = true,
						name = L["|cffABD473Hunter|r"],
						order = 12,
						args = listOption({19263,34471},"auraRemoved"),
					},
				}
			},
			spellCastStart = {
				type = 'group',
				--inline = true,
				name = L["Enemy Spell Casting"],
				desc = L["Alerts you when an enemy is attempting to cast a spell on you or another player"],
				disabled = function() return sadb.castStart end,
				set = setOption,
				get = getOption,
				order = 4,
				args = {
					general = {
						type = 'group',
						inline = true,
						name = L["General Spells"],
						order = 2,
						args = {
							bigHeal = {
								type = 'toggle',
								name = SpellTexture(48782)..L["Big Heals"],
								desc = L["Heal, Holy Light, Healing Wave, Healing Touch"],
								order = 1,
							},
							resurrection = {
								type = 'toggle',
								name = SpellTexture(48950)..L["Resurrection spells"], 
								desc = L["Ancestral Spirit, Redemption, etc"],
								order = 2,
							},
						}
					},
					druid = {
						type = 'group',
						inline = true,
						name = L["|cffFF7D0ADruid|r"],
						order = 3,
						args = listOption({18658,33786, 48465},"castStart"),
					},
					paladin = {
						type = 'group',
						inline = true,
						name = L["|cffF58CBAPaladin|r"],
						order = 4,
						args = listOption({10326},"castStart"),
					},
					warrior	= {
						type = 'group',
						inline = true,
						name = L["|cffC79C6EWarrior|r"],
						order = 6,
						args = listOption({64382},"castStart"),
					},
					priest	= {
						type = 'group',
						inline = true,
						name = L["|cffFFFFFFPriest|r"],
						order = 7,
						args = listOption({8129,10955,64843,605},"castStart"),
					},
					shaman	= {
						type = 'group',
						inline = true,
						name = L["|cff0070DEShaman|r"],
						order = 8,
						args = listOption({51514,60043},"castStart"),
					},
					mage = {
						type = 'group',
						inline = true,
						name = L["|cff69CCF0Mage|r"],
						order = 9,
						args = listOption({118},"castStart"),
					},
					hunter = {
						type = 'group',
						inline = true,
						name = L["|cffABD473Hunter|r"],
						order = 11,
						args = listOption({982,14327},"castStart"),
					},
					warlock	= {
						type = 'group',
						inline = true,
						name = L["|cff9482C9Warlock|r"],
						order = 12,
						args = listOption({6215,17928,18647,712},"castStart"),
					},
				},
			},
			spellCastSuccess = {
				type = 'group',
				--inline = true,
				name = L["Enemy Cooldown Abilities"],
				desc = L["Alerts you when enemies have used cooldowns"],
				disabled = function() return sadb.castSuccess end,
				set = setOption,
				get = getOption,
				order = 5,
				args = {
					paladin = {
						type = 'group',
						inline = true,
						name = L["|cffF58CBAPaladin|r"],
						order = 5,
						args = listOption({20066,10308,31884},"castSuccess"),
					},
					rogue = {
						type = 'group',
						inline = true,
						name = L["|cffFFF569Rogue|r"],
						order = 6,
						args = listOption({51722,51724,2094,1766,14185,26889,13877,1784},"castSuccess"),
					},
					warrior	= {
						type = 'group',
						inline = true,
						name = L["|cffC79C6EWarrior|r"],
						order = 7,
						args = listOption({2457,2458,71,676,5246,6552,72},"castSuccess"),
					},
					priest	= {
						type = 'group',
						inline = true,
						name = L["|cffFFFFFFPriest|r"],
						order = 8,
						args = listOption({10890,34433,64044,48173,64843},"castSuccess"),
					},
					shaman	= {
						type = 'group',
						inline = true,
						name = L["|cff0070DEShaman|r"],
						order = 9,
						args = listOption({8143,16190,2484,8177,32182,2825},"castSuccess"),
					},
					mage = {
						type = 'group',
						inline = true,
						name = L["|cff69CCF0Mage|r"],
						order = 10,
						args = listOption({44445,12051,44572,11958,2139,66,1953},"castSuccess"),
					},
					dk	= {
						type = 'group',
						inline = true,
						name = L["|cffC41F3BDeath Knight|r"],
						order = 11,
						args = listOption({47528,47476,47568,49206,49203,49005},"castSuccess"),
					},
					hunter = {
						type = 'group',
						inline = true,
						name = L["|cffABD473Hunter|r"],
						order = 12,
						args = listOption({53271,23989,49012,34490,49050,14311,13810},"castSuccess"),
					},
					warlock = {
						type = 'group',
						inline = true,
						name = L["|cff9482C9Warlock|r"],
						order = 13,
						args = listOption({5138,19647,48020,47860,6358},"castSuccess"),
					},
					races = {
						type = 'group',
						inline = true,
						name = L["|cffFFFFFFGeneral Races|r"],
						order = 14,
						args = listOption({316465,316386,316393,316161,316367,316443,316455,316431,316418,316419,316420,316279,316421},"castSuccess"),
					},
				},
			},
			enemydebuff = {
				type = 'group',
				--inline = true,
				name = L["Enemy Debuff"],
				desc = L["Alerts you when you (or your arena partner) have casted a CC on an enemy"],
				disabled = function() return sadb.dEnemyDebuff end,
				set = setOption,
				get = getOption,
				order = 6,
				args = {
						fromself = {
						type = 'group',
						inline = true,
						name = L["|cffFFF569From Self|r"],
						order = 1,
						args = listOption({2094,51724,51514,12826,118,33786,316456},"enemyDebuffs"),
					},
					fromarenapartner = {
						type = 'group',
						inline = true,
						name = L["|cffFFF569From Arena Partner or affecting your Target|r"],
						order = 2,
						args = listOption({2094,51724,51514,12826,118,33786,316456},"friendCCenemy"),
					}
				},
			},
			enemydebuffdown = {
				type = 'group',
				--inline = true,
				name = L["Enemy Debuff Down"],
				desc = L["Alerts you when your (or your arena partner) casted CC's on an enemy is down"],
				disabled = function() return sadb.eEnemyDebuffDown end,
				set = setOption,
				get = getOption,
				order = 7,
				args = {
					fromself = {
						type = 'group',
						inline = true,
						name = L["|cffFFF569From Self|r"],
						order = 1,
						args = listOption({2094,51724,51514,12826,118,33786,316456},"enemyDebuffdown"),
					},
					fromarenapartner = {
						type = 'group',
						inline = true,
						name = L["|cffFFF569From Arena Partner or affecting your Target|r"],
						desc = L["Alerts you if your arena partner casts a spell or your target gets afflicted by a spell"],
						order = 2,
						args = listOption({2094,51724,51514,12826,118,33786,316456},"enemyDebuffdownAP"),
					}
				},
			},
			FriendDebuff = {
				type = 'group',
				--inline = true,
				name = L["Arena partner Enemy Spell Casting"],
				desc = L["Alerts you when an enemy is casting a spell targetted at your arena partner"],
				disabled = function() return sadb.dArenaPartner end,
				set = setOption,
				get = getOption,
				order = 8,
				args = listOption({51514,118,33786,6215},"friendCCs"),
			},
			FriendDebuffSuccess = {
				type = 'group',
				name = L["Arena partner CCs/Debuffs"],
				desc = L["Alerts you when your arena partner gets CC'd"],
				disabled = function() return sadb.dArenaPartner end,
				set = setOption,
				get = getOption,
				order = 9,
				args = listOption({14309,2094,10308,51514,12826,33786,6215,2139,51724},"friendCCSuccess"),
			},
			selfDebuffs = {
				type = 'group',
				--inline = true,
				name = L["Self Debuffs"],
				desc = L["Alerts you when you get afflicted by one of these spells when you aren't targeting the enemy."],
				disabled = function() return sadb.dSelfDebuff end,
				set = setOption,
				get = getOption,
				order = 10,
				args = listOption({33786,51514,118,6215,14309,13809,5246,17928,2094,51724,10308,47860,5138,44572,20066,34490,19434,47476,51722,49005,49012,6358,10890,316421,316431,316456,316443,316161,18647,676,64044,19647},"selfDebuff"),
			},
		},
	})
	self:AddOption('custom', {
		type = 'group',
		name = L["Custom Alerts"],
		desc = L["Create a custom sound or chat alert with text or a sound file"],
		order = 3,
		args = {
			newalert = {
				type = 'execute',
				name = function ()
					if sadb.custom[L["New Alert"]] then  
						return L["Rename the New Alert entry"]
					else
						return L["New Alert"]
					end
				end,
				order = -1,
				func = function()
					sadb.custom[L["New Alert"]] = {
						name = L["New Alert"],
						soundfilepath = L["New Alert"]..".[ogg/mp3/wav]",
						sourceuidfilter = "any",
						destuidfilter = "any",
						eventtype = {
							SPELL_CAST_SUCCESS = true,
							SPELL_CAST_START = false,
							SPELL_AURA_APPLIED = false,
							SPELL_AURA_REMOVED = false,
							SPELL_INTERRUPT = false,
							SPELL_SUMMON = false,
						},
						sourcetypefilter = COMBATLOG_FILTER_EVERYTHING,
						desttypefilter = COMBATLOG_FILTER_EVERYTHING,
						order = 0,
					}
					self:OnOptionsCreate()
				end,
				disabled = function ()
					if sadb.custom[L["New Alert"]] then
						return true
					else
						return false
					end
				end,
			},
		}
	})
	local function makeoption(key)
		local keytemp = key
		self.options.args.custom.args[key] = {
			type = 'group',
			name = sadb.custom[key].name,
			set = function(info, value) local name = info[#info] sadb.custom[key][name] = value end,
			get = function(info) local name = info[#info] return sadb.custom[key][name] end,
			order = sadb.custom[key].order,
			args = {
				name = {
					name = L["Spell Entry Name"],
					desc = L["Menu entry for the spell (eg. Hex down on arena partner)"],
					type = 'input',
					set = function(info, value)
						--if sadb.custom[value] then log(L["same name already exists"]) return end
						if sadb.custom[value] then log(L["same name already exists"]) return end
						sadb.custom[key].name = value
						sadb.custom[key].order = 100
						sadb.custom[value] = sadb.custom[key]
						sadb.custom[key] = nil
						--makeoption(value)
						self.options.args.custom.args[keytemp].name = value
						key = value
					end,
					order = 1,
				},
				spellname = {
					name = L["Spell Name"],
					type = 'input',
					order = 10,
					hidden = function() return not sadb.custom[key].acceptSpellName end,
				},
				spellid = {
					name = L["Spell ID"],
					desc = L["Can be found on OpenWoW, in the URL"],
					set = function(info, value)
					local name = info[#info] sadb.custom[key][name] = value
						if GetSpellInfo(value) then
							sadb.custom[key].spellname = GetSpellInfo(value)
							self.options.args.custom.args[keytemp].spellname = GetSpellInfo(value)
						else
						sadb.custom[key].spellname = "Invalid Spell ID"
						self.options.args.custom.args[keytemp].spellname = "Invalid Spell ID"
						end
					end,
					type = 'input',
					order = 20,
					pattern = "%d+$",
				},
				remove = {
					type = 'execute',
					order = 25,
					name = L["Remove"],
					confirm = true,
					confirmText = L["Are you sure?"],
					func = function() 
						sadb.custom[key] = nil
						self.options.args.custom.args[keytemp] = nil
					end,
				},
				acceptSpellName = {
					type = 'toggle',
					name = L["Use specific spell name"],
					desc = L["Use this in case there are multiple ranks for this spell"],
					order = 26,
				},
				chatAlert = {
					type = 'toggle',
					name = L["Chat Alert"],
					order = 27,
				},
				test = {
					type = 'execute',
					order = 28,
					name = L["Test"],
					desc = L["If you don't hear anything, try restarting WoW"],
					func = function() PlaySoundFile("Interface\\Addons\\SoundAlerter\\CustomSounds\\"..sadb.custom[key].soundfilepath) end,
					hidden = function() if sadb.custom[key].chatAlert then return true end end,
				},
				soundfilepath = {
					name = L["File Path"],
					desc = L["Place your ogg/mp3 custom sound in the CustomSounds folder in Interface/Addons/SoundAlerter/"],
					type = 'input',
					width = 'double',
					order = 27,
					hidden = function() if sadb.custom[key].chatAlert then return true end end,
				},
				chatalerttext = {
					name = L["Chat Alert Text"],
					desc = L["eg. #enemy# casted #spell# on me! (Use '%t' if you're casting a spell on an enemy. )"],
					type = 'input',
					width = 'double',
					order = 28,
					hidden = function() if not sadb.custom[key].chatAlert then return true end end,
				},
				eventtype = {
					type = 'multiselect',
					order = 50,
					name = L["Event type - it's best to have the least amount of event conditions"],
					values = self.SA_EVENT,
					get = function(info, k) return sadb.custom[key].eventtype[k] end,
					set = function(info, k, v) sadb.custom[key].eventtype[k] = v end,
				},
				sourceuidfilter = {
					type = 'select',
					order = 61,
					name = L["Source unit"],
					desc = L["Is the person who casted the spell your target/focus/mouseover?"],
					values = self.SA_UNIT,
				},
				sourcetypefilter = {
					type = 'select',
					order = 60,
					name = L["Source of the spell"],
					desc = L["Who casted the spell? Leave on 'any' if a spell got casted on you"],
					values = self.SA_TYPE,
				},
				sourcecustomname = {
					type= 'input',
					order = 62,
					name = L["Custom source name"],
					desc = L["Example: If the spell came from a specific player or boss"],
					disabled = function() return not (sadb.custom[key].sourceuidfilter == "custom") end,
				},
				destuidfilter = {
					type = 'select',
					order = 65,
					name = L["Spell destination unit"],
					desc = L["Was the spell destination towards your target/focus/mouseover? (Leave on 'player' if it's yourself)"],
					values = self.SA_UNIT,
				},
				desttypefilter = {
					type = 'select',
					order = 63,
					name = L["Spell Destination"],
					desc = L["Who was afflicted by the spell? Leave it on 'any' if it's a spell cast or a buff"],
					values = self.SA_TYPE,
				},
				destcustomname = {
					type= 'input',
					order = 68,
					name = L["Custom destination name"],
					disabled = function() return not (sadb.custom[key].destuidfilter == "custom") end,
				},
			}
		}
	end
	for key, v in pairs(sadb.custom) do
		makeoption(key)
	end
end