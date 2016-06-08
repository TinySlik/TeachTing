local Levels = import("..data.MyLevels")
local Cell   = import("..views.Cell")

local Board = class("Board", function()
    return display.newNode()
end)

local NODE_PADDING   = 100 * GAME_CELL_STAND_SCALE
local NODE_ZORDER    = 0

local COIN_ZORDER    = 1000

function Board:ctor(levelData)
    cc.GameObject.extend(self):addComponent("components.behavior.EventProtocol"):exportMethods()
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))

    self.batch = display.newNode()
    self.batch:setPosition(display.cx, display.cy)
    self:addChild(self.batch)

    self.grid = clone(levelData.grid)
    self.rows = levelData.rows
    self.cols = levelData.cols
    self.cells = {}
    self.flipAnimationCount = 0

    if self.cols <= 8 then
        local offsetX = -math.floor(NODE_PADDING * self.cols / 2) - NODE_PADDING / 2
        local offsetY = -math.floor(NODE_PADDING * self.rows / 2) - NODE_PADDING / 2
        for row = 1, self.rows do
            local y = row * NODE_PADDING + offsetY
            for col = 1, self.cols do
                local x = col * NODE_PADDING + offsetX
                local nodeSprite = display.newSprite("#BoardNode.png", x, y)
                nodeSprite:setScale(GAME_CELL_STAND_SCALE)
                self.batch:addChild(nodeSprite, NODE_ZORDER)

                local node = self.grid[row][col]
                if node ~= Levels.NODE_IS_EMPTY then
                    local cell = Cell.new()
                    cell:setScale(GAME_CELL_STAND_SCALE * 1.65)
                    cell:setPosition(x, y)
                    cell.row = row
                    cell.col = col
                    self.grid[row][col] = cell
                    self.cells[#self.cells + 1] = cell
                    self.batch:addChild(cell, COIN_ZORDER)
                end
            end
        end
    else
        GAME_CELL_EIGHT_ADD_SCALE = 8.0 / self.cols
        NODE_PADDING = NODE_PADDING * GAME_CELL_EIGHT_ADD_SCALE
        local offsetX = -math.floor(NODE_PADDING * self.cols / 2) - NODE_PADDING / 2
        local offsetY = -math.floor(NODE_PADDING * self.rows / 2) - NODE_PADDING / 2
        GAME_CELL_STAND_SCALE = GAME_CELL_EIGHT_ADD_SCALE * GAME_CELL_STAND_SCALE 
        for row = 1, self.rows do
            local y = row * NODE_PADDING + offsetY
            for col = 1, self.cols do
                local x = col * NODE_PADDING + offsetX
                local nodeSprite = display.newSprite("#BoardNode.png", x, y)
                nodeSprite:setScale(GAME_CELL_STAND_SCALE)
                self.batch:addChild(nodeSprite, NODE_ZORDER)

                local node = self.grid[row][col]
                if node ~= Levels.NODE_IS_EMPTY then
                    local cell = Cell.new()
                    cell:setScale(GAME_CELL_STAND_SCALE * 1.65)
                    cell:setPosition(x, y)
                    cell.row = row
                    cell.col = col
                    self.grid[row][col] = cell
                    self.cells[#self.cells + 1] = cell
                    self.batch:addChild(cell, COIN_ZORDER)
                end
            end
        end
        GAME_CELL_EIGHT_ADD_SCALE = 1.0
        GAME_CELL_STAND_SCALE = GAME_CELL_EIGHT_ADD_SCALE * 0.75
        NODE_PADDING = 100 * 0.75
    end

    self:setNodeEventEnabled(true)
    self:setTouchEnabled(true)
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        return self:onTouch(event.name, event.x, event.y)
    end)

    self:checkAll()
end

function Board:checkLevelCompleted()
    local count = 0
    for _, coin in ipairs(self.cells) do
        if coin.isWhite then count = count + 1 end
    end
    if count == #self.cells then
        -- completed
        self:setTouchEnabled(false)
        self:dispatchEvent({name = "LEVEL_COMPLETED"})
    end
end

function Board:getCell(row, col)
    if self.grid[row] then
        return self.grid[row][col]
    end
end

function Board:flipCoin(coin, includeNeighbour)
    if not coin or coin == Levels.NODE_IS_EMPTY then return end

    self.flipAnimationCount = self.flipAnimationCount + 1
    coin:flip(function()
        self.flipAnimationCount = self.flipAnimationCount - 1
        self.batch:reorderChild(coin, COIN_ZORDER)
        if self.flipAnimationCount == 0 then
            self:checkLevelCompleted()
        end
    end)
    if includeNeighbour then
        audio.playSound(GAME_SFX.flipCoin)
        self.batch:reorderChild(coin, COIN_ZORDER + 1)
        self:performWithDelay(function()
            self:flipCoin(self:getCoin(coin.row - 1, coin.col))
            self:flipCoin(self:getCoin(coin.row + 1, coin.col))
            self:flipCoin(self:getCoin(coin.row, coin.col - 1))
            self:flipCoin(self:getCoin(coin.row, coin.col + 1))
        end, 0.25)
    end
end

function Board:checkAll()
    local padding = NODE_PADDING * GAME_CELL_EIGHT_ADD_SCALE * 1.65
    for _, cell in ipairs(self.cells) do
        self:checkCell(cell)
    end
end

function Board:checkCell(cell)
    local listH = {}
    listH [#listH + 1] = cell
    local i=cell.col
    --格子中左边对象是否相同的遍历
    while i > 1 do
        i = i -1
        local cell_left = self:getCell(cell.row,i)
        if cell.nodeType == cell_left.nodeType then
            listH [#listH + 1] = cell_left
        else
            break
        end
    end
    --格子中右边对象是否相同的遍历
    if cell.col ~= self.cols then
        for j=cell.col+1 , self.cols do
            local cell_right = self:getCell(cell.row,j)
            if cell.nodeType == cell_right.nodeType then
                listH [#listH + 1] = cell_right
            else
                break
            end
        end
    end
    --目前的当前格子的左右待消除对象(连同自己)

    --print(#listH)

    if #listH < 3 then
    else
        -- print("find a 3 coup H cell")
        for i,v in pairs(listH) do
            v.isNeedClean = true
        end

    end
    for i=2,#listH do
        listH[i] = nil
    end

    --判断格子的上边的待消除对象

    if cell.row ~= self.rows then
        for j=cell.row+1 , self.rows do
            local cell_up = self:getCell(j,cell.col)
            if cell.nodeType == cell_up.nodeType then
                listH [#listH + 1] = cell_up
            else
                break
            end
        end
    end

    local i=cell.row

    --格子中下面对象是否相同的遍历
    while i > 1 do
        i = i -1
        local cell_down = self:getCell(i,cell.col)
        if cell.nodeType == cell_down.nodeType then
            listH [#listH + 1] = cell_down
        else
            break
        end
    end

    if #listH < 3 then
    else
        for i,v in pairs(listH) do
            v.isNeedClean = true
        end
    end
end

function Board:onTouch(event, x, y)
    if event ~= "began" or self.flipAnimationCount > 0 then return end

    -- local padding = NODE_PADDING / 2
    -- for _, coin in ipairs(self.cells) do
    --     local cx, cy = coin:getPosition()
    --     cx = cx + display.cx
    --     cy = cy + display.cy
    --     if x >= cx - padding
    --         and x <= cx + padding
    --         and y >= cy - padding
    --         and y <= cy + padding then
    --         self:flipCoin(coin, true)
    --         break
    --     end
    -- end
end

function Board:check()
    local i = 1
    local j = 1
    while i <= self.rows do
        j = 1
        while j <= self.cols do
            local cell = self.grid[i][j]
            local sum = 1
            while j < self.cols and cell.nodeType == self.grid[i][j+1].nodeType do
                cell = self.grid[i][j+1]
                j = j + 1
                sum = sum + 1
            end
            if sum >= 3 then
                print(i,j)
            end
            j = j + 1
        end
        i = i + 1
    end

    i = 1
    j = 1
    while i <= self.cols do
        j = 1
        while j <= self.rows do
            local cell = self.grid[j][i]
            local sum = 1
            while j < self.rows and cell.nodeType == self.grid[j+1][i].nodeType do
                cell = self.grid[j+1][i]
                j = j + 1
                sum = sum + 1
            end
            if sum >= 3 then
                print(j,i)
            end
            j = j + 1
        end
        i = i + 1
    end
end

function Board:onEnter()
    self:setTouchEnabled(true)
end

function Board:onExit()
    self:removeAllEventListeners()
end

return Board