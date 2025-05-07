local __CIA_Internals = {
    --- @type { [string]: Item}
    _registeredItems = {},
    VERSION = "1.0.0α",
    NormalSkullModel = nil
}
local __CIA_Helpers = {}


local CustomItemAPI = {
    __CIA_Internals = __CIA_Internals,
    Helpers = __CIA_Helpers
}
local keys = {
    use = keybinds:fromVanilla("key.use"),
    hit = keybinds:fromVanilla("key.attack")
}

--- @alias ItemTransformMatrix { FirstPerson: Matrix4, FirstPersonOffhand: Matrix4, Dropped: Matrix4, Inventory: Matrix4, ThirdPerson: Matrix4, ThirdPersonOffhand: Matrix4 }
--- @alias OnUseFunction fun(self: Item, itemStack: ItemStack, hand: LivingEntity.hand, modifiers: Event.Press.modifiers): boolean?
--- @alias OnHitFunction fun(self: Item, hit: LivingEntity | BlockState | nil, itemStack: ItemStack, hand: LivingEntity.hand, modifiers: Event.Press.modifiers): boolean?
--- @alias ItemOpts { HeldItemModel: ModelPart?, HotbarItemModel: ModelPart?, Transforms: ItemTransformMatrix}
--- @alias Item { OnUse: OnUseFunction, OnHit: OnHitFunction, getName: fun(self: Item): string; setNamePattern: fun(self: Item, pattern: string): Item; setOnUse: fun(self: Item, func: OnUseFunction): Item; setOnHit: fun(self: Item, func: OnHitFunction): Item; Options: ItemOpts  }

---Register a custom item. Registering an item with the same name as another will overwrite that item.
---@param name string
---@param opts ItemOpts
---@return Item
function CustomItemAPI:register(name, opts)
    local item = __CIA_Internals._createItem(name, opts)
    __CIA_Internals._registeredItems[name] = item
    if opts.HeldItemModel then
        opts.HeldItemModel:setVisible(false)
        opts.HeldItemModel:setParentType("ITEM")
    end
    if opts.HotbarItemModel then
        opts.HotbarItemModel:setVisible(false)
        opts.HotbarItemModel:setParentType("SKULL")
        removeLighting(opts.HotbarItemModel)
    end
    return item
end



---Sets the normal model that is to be hidden when rendering items.
---@param mdl ModelPart
---@return table
function CustomItemAPI:setNormalSkull(mdl)
    __CIA_Internals.NormalSkullModel = mdl
    return self
end

---comment
---@param mat Matrix4
---@param vector Vector3|Vector2
---@return Matrix4
function __CIA_Helpers:rotateMatrix(mat, vector)
    vector = vec(vector.x or 0, vector.y or 0, vector.z or 0)
    return mat * matrices.mat4():rotateX(vector.x) * matrices.mat4():rotateY(vector.y) * matrices.mat4():rotateZ(vector.z)
end

function removeLighting(model)
    for _,texture in pairs(model:getAllVertices()) do
      for _,vertex in pairs(texture) do
        vertex:setNormal(vec(0,1,0))
      end
    end
    for _, part in pairs(model:getChildren()) do
      removeLighting(part)
    end
  end

---Unregisters a custom item.
---@param name string
function CustomItemAPI:unregister(name)
    __CIA_Internals._registeredItems[name] = nil
end

---@param name string
---@param opts ItemOpts
---@return Item
function __CIA_Internals._createItem(name, opts)
    local item = {
        _pattern = name,
        _name = name,
        Options = opts,
        OnUse = function() end,
        OnHit = function() end,
    }
    ---Gets the name of the item.
    ---@param self Item
    ---@return string
    function item:getName()
        return self._name
    end
    
    ---Sets the pattern used for recognizing the item.
    ---Defaults to `:getName()`
    ---@param self Item
    ---@param pattern string the pattern
    ---@return Item self
    function item:setNamePattern(pattern)
        self._pattern = pattern
        return self
    end

    ---Sets the function to be called upon using the item.
    ---@param self Item
    ---@param func OnUseFunction
    ---@return Item self
    function item:setOnUse(func)
        self.OnUse = func
        return self
    end

    ---Sets the function to be called upon attacking with the item.
    ---@param self Item
    ---@param func OnUseFunction
    ---@return Item self
    function item:setOnHit(func)
        self.OnHit = func
        return self
    end
    
    return item
end


---@param context Event.SkullRender.context
---@return "WORN" | "WORLD" | "HAND" | "INVENTORY" | "UNKNOWN" | "THIRD_PERSON" | "DROPPED"
function __CIA_Internals.GetBroaderContext(context)
    if context == "HEAD" then return "WORN" end
    if context == "BLOCK" then return "WORLD" end
    if context:find("FIRST_PERSON") then return "HAND" end
    if context == "OTHER" then return "INVENTORY" end
    if context:find("ITEM") then return "DROPPED" end
    if context:find("THIRD_PERSON") then return "THIRD_PERSON" end
    return "UNKNOWN"
end

---@param stack ItemStack
---@return Item?
function __CIA_Internals.getItemFromStack(stack)
    for key, value in pairs(__CIA_Internals._registeredItems) do
        if stack:getName():find(value._pattern) then
            return value
        end
    end
end

keys.use:onPress(function (modifiers, self)
    if host:isChatOpen() or host:isContainerOpen() or host:getScreen() or action_wheel:isEnabled() then return end
    local heldItem = player:getHeldItem()
    local heldItem2 = player:getHeldItem(true)
    local item1 = __CIA_Internals.getItemFromStack(heldItem)
    local item2 = __CIA_Internals.getItemFromStack(heldItem2)
    local cancel = true
    if item1 then
        local ret = item1:OnUse(heldItem, "MAIN_HAND", modifiers)
        if ret ~= nil then
            cancel = ret
        end
    end
    if item2 then
        local ret = item2:OnUse(heldItem2, "OFF_HAND", modifiers)
        if ret ~= nil then
            cancel = ret
        end
    end
    return not cancel
end)

keys.hit:onPress(function (modifiers, self)
    if host:isChatOpen() or host:isContainerOpen() or host:getScreen() or action_wheel:isEnabled() or not player:isLoaded() then return end
    local heldItem = player:getHeldItem()
    local heldItem2 = player:getHeldItem(true)
    local item1 = __CIA_Internals.getItemFromStack(heldItem)
    local item2 = __CIA_Internals.getItemFromStack(heldItem2)
    local cancel = true
    local hit = nil;
    local entityRc = player:getTargetedEntity(host:getReachDistance())
    hit = entityRc
    if not entityRc then
        local blockRc = player:getTargetedBlock(false, host:getReachDistance())
        hit = blockRc
    end

    if item1 then
        local ret = item1:OnHit(hit, heldItem, "MAIN_HAND", modifiers)
        if ret ~= nil then
            cancel = ret
        end
    end
    if item2 then
        local ret = item2:OnHit(hit, heldItem2, "OFF_HAND", modifiers)
        if ret ~= nil then
            cancel = ret
        end
    end
    return not cancel
end)

function __CIA_Internals.hideAllModels()
    for key, value in pairs(__CIA_Internals._registeredItems) do
        ---@type ItemOpts
        local opts = value.Options
        if opts.HeldItemModel ~= nil then
            opts.HeldItemModel:setVisible(false)
        end
        if opts.HotbarItemModel ~= nil then
            opts.HotbarItemModel:setVisible(false)
        end
    end
end

-- function events.ITEM_RENDER(item, mode, pos, rot, scale, lefthanded)
--     if mode == "HEAD" or mode:find("FIRST_PERSON") then return end
--     local cItem = __CIA_Internals.getItemFromStack(item)
--     if cItem ~= nil then
--         ---@type ItemOpts
--         local opts = cItem.Options
--         local mdl = opts.HeldItemModel
--         local irot = opts.Transforms.TPRot
--         local ipos = opts.Transforms.TPPos
--         local iscale = opts.Transforms.TPScale
--         mdl:setRot(irot)
--         mdl:setPos(ipos)
--         mdl:setScale(iscale)
--         mdl:setVisible(true)
--         mdl:setParentType("ITEM")
--         return mdl
--     end
-- end

function events.SKULL_RENDER(delta, block, item, entity, ctx)
    __CIA_Internals.hideAllModels()
    local bctx = __CIA_Internals.GetBroaderContext(ctx)
    if bctx == "WORLD" and __CIA_Internals.NormalSkullModel ~= nil then
        __CIA_Internals.NormalSkullModel:setVisible(true)
    end
    if bctx == "WORN" then
        if __CIA_Internals.NormalSkullModel ~= nil then
            __CIA_Internals.NormalSkullModel:setVisible(true)
        end
        return
    end
    if bctx ~= "INVENTORY" and bctx ~= "HAND" and bctx ~= "THIRD_PERSON" and bctx ~= "DROPPED" then return end
    if item ~= nil then
        if bctx == "THIRD_PERSON" and ctx:find("RIGHT") and player:isLoaded() then
            item = entity:getItem(1)
        end
        local cItem = __CIA_Internals.getItemFromStack(item)
        if cItem == nil then 
            if __CIA_Internals.NormalSkullModel ~= nil then
                __CIA_Internals.NormalSkullModel:setVisible(true)
            end
            return
        end
        ---@type ItemOpts
        local opts = cItem.Options
        local mdl = nil
        if bctx == "INVENTORY" or bctx == "DROPPED" then
            mdl = opts.HotbarItemModel
        elseif bctx == "HAND" then
            mdl = opts.HeldItemModel
        else
            mdl = opts.HeldItemModel
        end
        mdl:setParentType("SKULL")

        if mdl ~= nil then
            mdl:setVisible(true)
            if opts.Transforms ~= nil then
                if bctx == "INVENTORY" then
                    local transform = opts.Transforms.Inventory:copy()
                    mdl:setMatrix(transform)
                elseif bctx == "HAND" then
                    local transform = opts.Transforms.FirstPerson:copy()
                    if ctx:find("LEFT") then 
                        transform = opts.Transforms.FirstPersonOffhand:copy()                    end
                    mdl:setMatrix(transform)
                elseif bctx == "DROPPED" then
                    local transform = opts.Transforms.Dropped:copy()
                    mdl:setMatrix(transform)
                elseif bctx == "THIRD_PERSON" then
                    local transform = opts.Transforms.ThirdPerson:copy()
                    if ctx:find("LEFT") then 
                        transform = opts.Transforms.ThirdPersonOffhand:copy()
                    end
                    mdl:setMatrix(transform)
                end
            end
        end
        if __CIA_Internals.NormalSkullModel then
            __CIA_Internals.NormalSkullModel:setVisible(false)
        end
    end
end


-- local debugs = {}
-- function _debug(thing)
--     thing = tostring(thing)
--     debugs[#debugs+1] = thing
--     if #debugs == 6 then
--         table.remove(debugs, 1)
--     end
--     local final = ""
--     for index, value in ipairs(debugs) do
--         final = final .. value .. "    "
--     end
--     host:actionbar(final)
-- end


-- -- test
-- CustomItemAPI:register("Divine Dominance", {
--     HeldItemModel = models.charter.dusksEpitaph.DusksEpitaphV3,
--     HotbarItemModel = models.charter.dusksEpitaph.DusksEpitaphV3,
--     Transforms = {
--         HotbarItemPos = vec(9,6,0),
--         HotbarItemRot = vec(-45,45,0),
--         HotbarItemScale = 0.5,

--         HeldItemPos = vec(-5,5,-2),
--         HeldItemRot = vec(0,0,0),
--         HeldItemScale = 1,

--         TPPos = vec(0.5, 0, 0),
--         TPRot = vec(0,0,0),
--         TPScale = 1
--     }
-- }):setOnUse(function (self, itemStack, hand, modifiers)
--     print(self, itemStack, hand, modifiers)
--     return false
-- end)

return CustomItemAPI