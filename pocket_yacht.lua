--Yacht 1.0 (Pocket Version)
--Author: Viriss (@gmail.com)
--Date: 9/24/2022

term.setPaletteColor(colors.cyan, 0xD0D0D0)
term.setPaletteColor(colors.green, 0xadaa5d)
action = ""

function setColors(text, background) term.setBackgroundColor(background) term.setTextColor(text) end
function blitAt(x, y, text, textColor, bgColor) term.setCursorPos(x, y) term.blit(text, textColor, bgColor) end
function shuffle(tbl) for i = #tbl, 2, -1 do local j = math.random(i) tbl[i], tbl[j] = tbl[j], tbl[i] end return tbl end
function drawHeader()
	setColors(colors.black, colors.white)
	term.clear()
	paintutils.drawFilledBox(1, 1, 36, 2, colors.green)
	term.setCursorPos(3, 1)
	term.write("Yacht: A Game of Dice")
end
function drawIntro()
	drawHeader()
	local initials = ""

	setColors(colors.black, colors.white)

	term.setCursorPos(3, 5) term.write("How to play: Roll five")
	term.setCursorPos(3, 6) term.write("dice and try to score")
	term.setCursorPos(3, 7) term.write("points in each of 12")
	term.setCursorPos(3, 8) term.write("different categories.")
	term.setCursorPos(3, 9) term.write("Each round you may")
	term.setCursorPos(3, 10) term.write("\"lock\" any number of")
	term.setCursorPos(3, 11) term.write("dice and reroll up") 
	term.setCursorPos(3, 12) term.write("to two times.")
	
	term.setCursorBlink(true)
	while string.len(initials) < 3 do
		term.setCursorPos(3, 15)
		term.write("Enter initials: "..initials..string.rep("-", 3 - string.len(initials)))
		term.setCursorPos(19 + string.len(initials), 15)
		local event,key = os.pullEvent("key")
		if (key > 32 and key < 127) then
			initials = initials..string.char(key)
		end
		if key == 259 and string.len(initials) > 0 then
			initials = string.sub(initials, 1, string.len(initials)-1)
		end
	end
	
	term.setCursorBlink(false)
	term.setCursorPos(3, 15)
	term.write("Enter initials: "..initials)
	sleep(1.5)
	game.initials = initials;
end
function drawRandomDice()
	setColors(colors.black, colors.white)
	for y = 1, 10, 1 do
		for i = 1, 5, 1 do
			if dice[i].isLocked == false then
				term.setCursorPos(2 + ((i-1) * 2), 8)
				term.write(""..math.random(6))
			end
		end
		sleep(0.01)
	end
end
function drawBoard()
	drawHeader()
	paintutils.drawFilledBox(1, 3, 11, 24, colors.cyan)
	blitAt(1, 4, "Click # to", "ffffffffff", "9999999999")
	blitAt(1, 5, "lock/unlock", "0000fffffff", "eeee9000000")
	
	dice:drawAll(2, 8)
	
	setColors(colors.black, colors.white)
	if game.rerollCount < 2 then blitAt(1, 11, "Reroll", "ffffff", "444444") else blitAt(1, 11, "Reroll", "999999", "888888") end
	if game.rerollCount == 0 then blitAt(8, 11, "1", "f", "9") else blitAt(8, 11, "x", "e", "9") end
	if game.rerollCount < 2 then blitAt(10, 11, "2", "f", "9") else blitAt(10, 11, "x", "e", "9") end
	
	blitAt(1, 12, "or", "88", "99")
	blitAt(1, 13, "Pick a slot", "fffffffffff", "99999999999")
	blitAt(1, 14, "to score  "..string.char(16), "fffffffffff", "99999999999")

	paintutils.drawFilledBox(22, 4, 26, 15, colors.gray)

	local t = slots:getTotal()
	if t == 0 then blitAt(13, 17, "Total   ", "ffffffff", "00000999") else blitAt(13, 17, "Total"..string.rep(" ", 3-string.len(t))..t, "ffffffff", "00000999") end
end
function drawGameOver()
	drawBoard()
	slots:drawAll(13, 4)
	paintutils.drawFilledBox(1, 3, 11, 24, colors.cyan)
	blitAt(2, 4, "Game Over", "fffffffff", "999999999")
	
	table.insert(game.scoreboard, { score = slots:getTotal(), user = game.initials })

	sortScores()
	showScores()
	game:saveScore()
end
function pipPatt(p)
	local t = ""
	for c in dice:toString():gmatch"." do
		if c == p then t = t.."8" else t = t.."7" end
	end
	return t
end
function waitForScreenTouch() event, button, x, y = os.pullEvent("mouse_click") game:userAction(x, y) end
function sortScores()
	local done = false
	while done == false do
		done = true
		for i = 1, #game.scoreboard - 1, 1 do
			if game.scoreboard[i].score < game.scoreboard[i+1].score then
				done = false
				game.scoreboard[i], game.scoreboard[i+1] = game.scoreboard[i+1], game.scoreboard[i]
			end
		end
	end
end
function showScores()
	local t = ""
	for i = 1, #game.scoreboard, 1 do
		t = game.scoreboard[i].user.." "..game.scoreboard[i].score
		if game.scoreboard[i].score == slots:getTotal() and game.initials == game.scoreboard[i].user then
			blitAt(2, 5+i, t, string.rep("0", string.len(t)), string.rep("e", string.len(t)))
		else
			blitAt(2, 5+i, t, string.rep("f", string.len(t)), string.rep("9", string.len(t)))
		end
		if i == 10 then break end
	end
end

game = {
	attemptNum = 1,
	rerollCount = 0,
	scoreboard = {},
	initials = "",
	init = function(self)
		if fs.exists("yacht_scores") then
			local f = fs.open("yacht_scores", "r")
			local s = f.readAll()
			if s and #s > 0 then
				self.scoreboard = textutils.unserialize(s)
			end
			f.close()
		end
	end,
	saveScore = function(self)
		local f = fs.open("yacht_scores", "w")
		f.write(textutils.serialize(self.scoreboard))
		f.close()
	end,
	doSetup = function(self)
		self.createSlots()
		dice:init()
	end,
	doRoll = function()
		dice:doRoll()
		dice:sort()
		dice:scan()
	end,
	doReroll = function(self) 
		self.rerollCount = self.rerollCount + 1
		self.doRoll()
		slots:reset()
	end,
	doNextRoll = function(self)
		self.attemptNum = self.attemptNum + 1
		self.rerollCount = 0
		slots:reset()
		dice:unlock()
		self.doRoll()
	end,
	createSlots = function()
		slots:addSlot("1's", "1")
		slots:addSlot("2's", "2")
		slots:addSlot("3's", "3")
		slots:addSlot("4's", "4")
		slots:addSlot("5's", "5")
		slots:addSlot("6's", "6")
		slots:addSlot("House", "88888", 25)
		slots:addSlot("4 Kind", "4k")
		slots:addSlot("Little", "88888", 30)
		slots:addSlot("Big", "88888", 30)
		slots:addSlot("Choice", "88888")
		slots:addSlot("Yacht", "88888", 50)
	end,
	userAction = function(self, x, y)
		--toggle lock
		if (x == 2 or x == 4 or x == 6 or x == 8 or x == 10) and y == 8 and self.rerollCount < 2 then
			action = "lock"
			dice[x/2]:toggleLock()
		end
		--reroll
		if x > 0 and x < 7 and y == 11 and self.rerollCount < 2 then
			action = "reroll"
		end
		--score good
		if x > 12 and x < 21 and y > 3 and y < 16 then
			action = "score"
			setColors(colors.yellow, colors.red)
			term.setCursorPos(x,y)
			if slots[y-3].status == "scoreable" then
				term.write(string.char(7))
				slots[y-3]:doScoreSlot(true)
			else
				--score bad
				if self.rerollCount == 2 and slots:hasScoreable() == false and slots[y-3].status ~= "scored" then
					term.write(string.char(8))
					slots[y-3]:doScoreSlot(false)
				else
					action = ""
				end
			end
			sleep(0.5)
		end
	end,
	checkForScoreable = function()
		if dice:hasAnyOnes() > 0 then slots[1]:isScoreable(dice:hasAnyOnes()) end
		if dice:hasAnyTwos() > 0 then slots[2]:isScoreable(dice:hasAnyTwos() * 2) end
		if dice:hasAnyThrees() > 0 then slots[3]:isScoreable(dice:hasAnyThrees() * 3) end
		if dice:hasAnyFours() > 0 then slots[4]:isScoreable(dice:hasAnyFours() * 4) end
		if dice:hasAnyFives() > 0 then slots[5]:isScoreable(dice:hasAnyFives() * 5) end
		if dice:hasAnySixes() > 0 then slots[6]:isScoreable(dice:hasAnySixes() * 6) end
		if dice:hasTwoKind() > 0 and dice:hasThreeKind() > 0 then slots[7]:isScoreable() end
		if dice:hasFourKind() > 0 or dice:hasFiveKind() > 0 then
			if dice:hasFiveKind() > 0 then
				slots[8]:isScoreable(dice:hasFiveKind() * 4) 
			else
				slots[8]:isScoreable(dice:hasFourKind() * 4) 
			end
		end
		if dice:toString() == "12345" then slots[9]:isScoreable() end
		if dice:toString() == "23456" then slots[10]:isScoreable() end
		slots[11]:isScoreable(dice:sum())
		if dice:hasFiveKind() > 0 then slots[12]:isScoreable() end
	end
}
dice = {
	data = {0, 0, 0, 0, 0, 0},
	init = function(self) for i = 1, 5, 1 do self:addDie(i) end end,
	doRoll = function(self) for i = 1, 5, 1 do self[i]:roll() end end, 
	drawAll = function(self, x, y) for i = 1, 5, 1 do self[i]:draw(x + ((i - 1) * 2), y) end end,
	unlock = function(self) for i = 1, 5, 1 do self[i]:unlock() end end,
	addDie = function(self, index)
		table.insert(self, { 
			val = index,
			isLocked = false, 
			roll = function(self) if self.isLocked == false then self.val = math.random(6) end end, 
			lock = function(self) self.isLocked = true end, 
			unlock = function(self) self.isLocked = false end,
			toggleLock = function(self) if self.isLocked then self:unlock() else self:lock() end end,
			draw = function(self, x, y) 
				setColors(colors.black, colors.white)
				if self.isLocked then setColors(colors.white, colors.red) end
				term.setCursorPos(x, y)
				term.write(""..self.val)
			end
		})
	end,
	scan = function(self) 
		for i = 1, 6, 1 do 
			self.data[i] = 0
			for y = 1, 5, 1 do if self[y].val == i then self.data[i] = self.data[i] + 1 end end
		end
	end,
	sort = function(self) 
		local isClean = false
		while not isClean do
			isClean = true
			for i = 1, 4, 1 do if self[i].val > self[i+1].val then isClean = false self[i], self[i+1] = self[i+1], self[i] end end
		end
	end,
	hasOneKind = function(self) for i = 1, 6, 1 do if self.data[i] == 1 then return i end end return 0 end,
	hasTwoKind = function(self) for i = 1, 6, 1 do if self.data[i] == 2 then return i end end return 0 end,
	hasThreeKind = function(self) for i = 1, 6, 1 do if self.data[i] == 3 then return i end end return 0 end,
	hasFourKind = function(self) for i = 1, 6, 1 do if self.data[i] == 4 then return i end end return 0 end,
	hasFiveKind = function(self) for i = 1, 6, 1 do if self.data[i] == 5 then return i end end return 0 end,
	hasAnyOnes = function(self) return self.data[1] end,
	hasAnyTwos = function(self) return self.data[2] end,
	hasAnyThrees = function(self) return self.data[3] end,
	hasAnyFours = function(self) return self.data[4] end,
	hasAnyFives = function(self) return self.data[5] end,
	hasAnySixes = function(self) return self.data[6] end,
	sum = function(self) local t = 0 for i = 1, 5, 1 do t = t + self[i].val end return t end,
	toString = function(self) return ""..self[1].val..self[2].val..self[3].val..self[4].val..self[5].val end
}

slots = {
	statusColor = { open = "000000", scoreable = "555555", scored = "888888" },
	addSlot = function(self, name, scorePattern, points)
		table.insert(self, {
			text = name, 
			status = "open",
			score = 0,
			score_pips = "",
			score_pattern = "",
			pattern = scorePattern,
			points = points,
			potentialPoints = 0,
			isOpen = function(self) self.status = "open" end,
			isScoreable = function(self, possibleScore) 
				if self.status ~= "scored" then
					if possibleScore then self.potentialPoints = possibleScore end 
						self.status = "scoreable" 
					end
				end,
			doScoreSlot = function(self, success)
				self.status = "scored" 
				self.score_pips = dice:toString()
				self.score_pattern = self.pattern
				if string.len(self.pattern) == 1 then self.score_pattern = pipPatt(self.pattern) end
				if self.pattern == "4k" then 
					if dice:hasFiveKind() > 0 then self.score_pattern = "88887" end
					if dice:hasFourKind() then
						if dice:hasFourKind() > dice:hasOneKind() then self.score_pattern = "78888" else self.score_pattern = "88887" end
					end
				end
				self.score_pips = dice:toString()
				if success then
					self.score = self.potentialPoints
					if self.points then self.score = self.points end
				else
					self.score = 0
					self.score_pattern = "77777"
				end
			end,
			reset = function(self) self.score = 0 self.potentialPoints = 0 self:isOpen() end,
			draw = function(self, x, y)
					local p = 0
					if points then p = points end
					if self.potentialPoints > p then p = self.potentialPoints end
					term.setCursorPos(x, y)
					if self.status == "open" then
						term.blit(self.text..string.rep(" ", 6 - string.len(self.text)), "ffffff", slots.statusColor["open"])
						term.setCursorPos(x + 6, y)
						term.blit("  ", "ff", "99")
					end
					if self.status == "scoreable" then
						term.blit(self.text..string.rep(" ", 6 - string.len(self.text)), "ffffff", slots.statusColor["scoreable"])
						term.setCursorPos(x + 6, y)
						term.blit(string.rep(" ", 2-string.len(p))..p, "ff", "55")
					end
					if self.status == "scored" then
						term.blit(self.text..string.rep(" ", 6 - string.len(self.text)), "ffffff", slots.statusColor["scored"])
						term.setCursorPos(x + 6, y)
						term.blit(string.rep(" ", 2-string.len(self.score))..self.score, "88", "77")

						--draw pattern if scored?
						setColors(colors.purple, colors.orange)
						blitAt(x+9, y, self.score_pips, "fffff", self.score_pattern)
					end
				end
		})
	end,
	reset = function(self) 
		for i = 1, #self, 1 do 
			if self[i].status ~= "scored" then self[i]:reset() end
		end 
	end,
	fullReset = function(self)
		for i = 1, #self, 1 do 
			self[i]:reset()
		end 
	end,
	drawAll = function(self, x, y)
		for i = 1, #self, 1 do self[i]:draw(x, y + (i - 1)) end
	end,
	hasScoreable = function(self) 
		for i = 1, #self, 1 do if self[i].status == "scoreable" then return true end end return false
	end,
	getTotal = function(self)
		local t = 0
		for i = 1, #self, 1 do
			if self[i].status == "scored" then t = t + self[i].score end
		end
		return t
	end
}

setColors(colors.white, colors.black)
term.clear()
term.setCursorPos(1,1)
math.randomseed(os.clock())

game:init()
game:doSetup()

drawIntro()

game:doRoll()

while true do
	game.checkForScoreable()
	drawBoard()
	slots:drawAll(13, 4)

	action = "wait"
	while action == "wait" do
		parallel.waitForAny(waitForScreenTouch)
		if action == "lock" then action = "" end
		if action == "reroll" then drawRandomDice() action = "" game:doReroll()  end
		if action == "nextroll" then action = "" slots:reset() end
		if action == "score" then 
			action = "" 
			game:doNextRoll() 
			--end game?
			if game.attemptNum > 12 then
				--clean up final screen
				drawGameOver()
				
				parallel.waitForAny(waitForScreenTouch)
				--reset values of stuff
				slots:fullReset()
				game.attemptNum = 1
			end
		end
	end
end
