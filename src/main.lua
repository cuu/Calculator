--io.stdout:setvbuf("no") --enables live console output in sublime


--LOGIC ITEMS
local numOnHold = 0  -- After pressing +, -, *, /, =, previous number is kept in here.

local operatorJustSelected = false -- whether or not the most recent button press by a user, was on an operator
local justCalculated = false --Whether or not the user has just pressed enter or return to calculate.
local hasDecimal = false --Whether or not the calcDispStr number has a decimal point. If it does, we can't add any more decimal points
local maxCalcDispLen = 18 --If I didn't have this, the user could just keep typing numbers forever. This is the max, pleasant-to-see, digits that the calculator will display.
local currentButtonPressedIndex = 0 -- The index in buttonTable of whatever button is currently being held down. 0 means nothing is pressed right now because lua arrays start at 1

--FONTS
local buttonTextFont -- Font of all button text here
local calcDispStrFont-- Font of calcDispStr
local operatorButtonFont -- Font of + - * / =
local operatorDispFont -- Font of display in top right

--STRINGS & TEXT, CORRESPONDING
--You can set, but not get, the string displayed by LOVE2D's TEXT object. Therefore, we need a string and text for every item to display
local calcDispStr = "" -- string, to display on the face of the calculator, also needs to keep track of positive/negative as +/-
local calcDispText -- Text object to display numbers
local opDispStr = "" -- string to display
local opDispText -- Displays + - * / on the top right

local windowX, windowY = love.graphics.getDimensions() --width and height of window

--COLORS OF SHAPES AND TEXT
local backgroundColor = {64,64,64}
local rectangleColor = {41,41,41}
local buttonColor = {56,56,56}
local blackColor = {1,125,254}
local focusColor = {255,255,255}

--Basic arithmetic operations, to put in opTable and make the conditionals less wordy
local add = function(a, b) return a + b end
local subtract = function(a, b) return a - b end
local multiply = function(a, b)
	c =  a * b
	if c == 0 then
		c = 0
	end -- lua relies on the c compiler, which can produce negative 0, which is sure to confuse the user. this if statement gets rid of negative zero.
	return c
end
local divide = function(a, b) return a / b end

--List of lists. Each list is associated (conceptually, not actually codewise) with a button. Each list has six elements, which are in order: {x position, y position,  width, height, radius of the corners of the button's rounded rectangles, string to be printed on button}
--Draw these like love.graphics.rectangle("fill", windowX*v[1], windowY*v[2], windowX*v[3], windowY*v[4], windowX*v[5])
--Set the color as black for text, then love.graphics.print(" "..v[6], windowX*v[1], windowY*v[2])
--Where you are looping through everything in buttonTable and v is each inner table
local buttonTable = {
	{0.025, 0.634, 0.18, 0.17, 0, "1", 20, 5, 1, 3},
	{0.210, 0.634, 0.18, 0.17, 0, "2", 20, 5, 2, 3},
	{0.395, 0.634, 0.18, 0.17, 0, "3", 20, 5, 3, 3},
	{0.025, 0.457, 0.18, 0.17, 0, "4", 20, 5, 1, 2},
	{0.210, 0.457, 0.18, 0.17, 0, "5", 20, 5, 2, 2},
	{0.395, 0.457, 0.18, 0.17, 0, "6", 20, 5, 3, 2},
	{0.025, 0.280, 0.18, 0.17, 0, "7", 20, 5, 1, 1},
	{0.210, 0.280, 0.18, 0.17, 0, "8", 20, 5, 2, 1},
	{0.395, 0.280, 0.18, 0.17, 0, "9", 20, 5, 3, 1},
	{0.025, 0.813, 0.18, 0.17, 0, "(-)", 12, 2.5, 1, 4},
	{0.210, 0.813, 0.18, 0.17, 0, "0", 20, 5, 2, 4},
	{0.395, 0.813, 0.18, 0.17, 0, ".", 24, 2, 3, 4},
	{0.620, 0.280, 0.177, 0.232, 0, "/", 23, 7, 4, 1},
	{0.803, 0.280, 0.177, 0.232, 0, "*", 20, 15, 5, 1},
	{0.620, 0.520, 0.177, 0.232, 0, "+", 15, 7, 4, 2},
	{0.803, 0.520, 0.177, 0.232, 0, "-", 23, 7, 5, 2},
	{0.620, 0.760, 0.177, 0.225, 0, "c", 17, 7, 4, 3}, --clear, delete, whatever you want to call it 
	{0.803, 0.760, 0.177, 0.225, 0, "=", 17, 7, 5, 3}
}

local currFocus = {x=2,y=1}

--CALLBACK
function love.load()
	love.graphics.setBackgroundColor(backgroundColor)
	buttonTextFont = love.graphics.newFont(30)
	calcDispStrFont = love.graphics.newFont(21)
	operatorButtonFont = love.graphics.newFont(36)
	operatorDispFont = love.graphics.newFont(17)
	calcDispText = love.graphics.newText(calcDispStrFont, calcDispStr)
	opDispText = love.graphics.newText(operatorDispFont, opDispStr)
end	

--CALLBACK
function love.resize(w, h)
  windowX = w
  windowY = h
end

--CALLBACK
function love.draw()
	--Border edge offset of 0.01

	-- Draws the number buttons area
	love.graphics.setColor(rectangleColor)
	love.graphics.rectangle("fill", windowX * 0.02, windowY * 0.27, windowX * 0.56, windowY * 0.72, windowX * 0)

	-- Draws the operator buttons area
	love.graphics.setColor(rectangleColor)
	love.graphics.rectangle("fill", windowX * 0.61, windowY * 0.27, windowX * 0.38, windowY * 0.72, windowX * 0)

	--draws the actual buttons
	for _, v in ipairs(buttonTable) do
		love.graphics.setColor(buttonColor)
		love.graphics.rectangle("fill", windowX*v[1], windowY*v[2], windowX*v[3], windowY*v[4], windowX*v[5])
		love.graphics.setFont(buttonTextFont)
		love.graphics.setColor(blackColor)
		love.graphics.print(tostring(v[6]), windowX*v[1]+v[7], windowY*v[2]+v[8])

		if currFocus.x == v[9] and currFocus.y == v[10] then -- Button is focused
			love.graphics.setColor(focusColor)
			love.graphics.rectangle("line", windowX*v[1], windowY*v[2], windowX*v[3], windowY*v[4], windowX*v[5])
		end
	end

	-- Draws the number display area
	love.graphics.setColor(rectangleColor)
	love.graphics.rectangle("fill", windowX * 0.01, windowY * 0.01, windowX * 0.98, windowY * 0.25, windowX * 0.01)

	-- create love.graphics.newText and displays calcDispStr, and another for the + - * /
	love.graphics.setColor(blackColor)
	love.graphics.draw(calcDispText, windowX * 0.98 - calcDispText:getWidth(), windowY * 0.24 - calcDispText:getHeight())
	love.graphics.draw(opDispText, windowX * 0.98 - opDispText:getWidth(), windowY * 0.12 - opDispText:getHeight())
end

--All key pressing AND button pressing gets relegated to this function
function love.keypressed( key )
	if key == "escape" then
		love.event.quit()
	end
	
	if key == "j" then -- A Button
		for _,btn in pairs(buttonTable) do
			if btn[9] == currFocus.x and btn[10] == currFocus.y then
				buttonPressed(btn[6])
			end
		end
	end
	
	if key == "left" then
		moveFocus(-1, 0)
	end
	
	if key == "right" then
		moveFocus(1, 0)
	end
	
	if key == "up" then
		moveFocus(0, -1)
	end
	
	if key == "down" then
		moveFocus(0, 1)
	end
end

function buttonPressed(key)
	if  key ~= "(-)" then
		handleNumberAndOperatorInputs(key)
	elseif calcDispStr ~= "" then
		if calcDispStr:sub(1, 1) == "-" then
			calcDispStr = calcDispStr:sub(2)
		else
			calcDispStr = "-"..calcDispStr
		end
		calcDispText:set(calcDispStr)
	end
end

function moveFocus(xDir, yDir)
	if currFocus.y == 3 and currFocus.x == 3 and xDir == 1 then -- movement from btn "3" to "+" when going right
		currFocus.y = 2
	end
	
	if currFocus.y == 3 and currFocus.x == 4 and xDir == -1 then -- movement from btn "c" to "." when going left
		currFocus.y = 4
	end
	
	currFocus.x = currFocus.x + xDir
	currFocus.y = currFocus.y + yDir
	
	if currFocus.x <= 0 then
		currFocus.x = 1
	end
	
	if currFocus.x >= 6 then
		currFocus.x = 5
	end
	
	if currFocus.y <= 0 then
		currFocus.y = 1
	end
	
	if currFocus.y >= 5 and currFocus.x < 4 then
		currFocus.y = 4
	end
	
	if currFocus.y >= 4 and currFocus.x > 3 then
		currFocus.y = 3
	end
end

function handleNumberAndOperatorInputs(key)
	--handles numpad and home keyboard inputs
	local numTable = {["0"]=0,["1"]=1,["2"]=2,["3"]=3,["4"]=4,["5"]=5,["6"]=6,["7"]=7,["8"]=8,["9"]=9, ["."]=".", kp0=0,kp1=1,kp2=2,kp3=3,kp4=4,kp5=5,kp6=6,kp7=7,kp8=8,kp9=9,["kp."]="."}

	local opTable = {["+"]=add,["-"]=subtract,["*"]=multiply,["/"]=divide,["kp+"]=add,["kp-"]=subtract,["kp*"]=multiply,["kp/"]=divide}

	--timesIAppreciatedSwitchStatements++;

	--KEY IS DELETE
	if key == "backspace" or key == "delete" or key == "c" then
		--clear everything
		calcDispStr = ""
		calcDispText:set(calcDispStr)
		opDispStr = ""
		opDispText:set(opDispStr)
		operatorJustSelected = false
		numOnHold = 0
		hasDecimal = false
		justCalculated = false

	-- KEY IS CALCULATE
	elseif key == "return" or key == "kpenter" or key == "=" then
		--calculate anything if operator is selected
		--if no selection, display what is currently displaying
		if opDispStr == "" then
			--nothing
		else
			--some operation happened, loop through possible operations
			--but if operator has just been selected, don't do anything
			if not operatorJustSelected then
				local tempNum = opTable[opDispStr](numOnHold, tonumber(calcDispStr))
				numOnHold, calcDispStr = tempNum, tostring(tempNum)
				opDispStr = ""
				opDispText:set(opDispStr)
						calcDispText:set(calcDispStr)
				hasDecimal = false
				justCalculated = true
			end
		end

	--KEY IS OPERATE
	elseif opTable[key] ~= nil then
		if key:len() > 1 then
		  key = key:sub(3)
		end

		--If just selected operator, replace that operator
		--If we haven't just selected the operator and the operator display string ain't empty,
			--perform opDispStr with numOnHold and calcDispStr, put in numOnHold and calcDispStr
			--and set opDispStr as key, set operatorJustSelected to true
		--If we haven't just selected the operator and opDispStr is empty, opDispText
		  -- set operatorJustSelected to true
		  -- set opDispStr as key
		if operatorJustSelected then
			opDispStr = key
			opDispText:set(opDispStr)
		elseif opDispStr ~= "" then
			operatorJustSelected = true
			local tempNum = opTable[opDispStr](numOnHold, tonumber(calcDispStr))
			numOnHold, calcDispStr = tempNum, tostring(tempNum)
			calcDispText:set(calcDispStr)
			opDispStr = key
			hasDecimal = false
		else --opDispStr == ""
			numOnHold = tonumber(calcDispStr)
			operatorJustSelected = true
			hasDecimal = false
			opDispStr = key
			opDispText:set(opDispStr)
		end

	--KEY IS NUMBER
	elseif numTable[key] ~= nil and not ((numTable[key] == ".") and hasDecimal) then
		if numTable[key] == "." then
			hasDecimal = true
		end
  
		--if just selected operator, add replace calcDispStr with new number, but the old calcDispStr should still be in numOnHold
		if operatorJustSelected or justCalculated then
			calcDispStr = tostring(numTable[key])
			operatorJustSelected = false
			justCalculated = false
		elseif calcDispStr:len() < maxCalcDispLen then
			calcDispStr = calcDispStr .. numTable[key]
		end
    
		--Below if statement prevents arithmetic involving only a decimal point
		if calcDispStr == "." then
		  calcDispStr = "0."
		end

		calcDispText:set(calcDispStr)
	end
end
