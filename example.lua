
local CIA = require("CIA")
CIA:register("Dusk's Epitaph", {
    HeldItemModel = models.models.dusksEpitaph.DusksEpitaphV3,
    HotbarItemModel = models.models.dusksEpitaphInv.DusksEpitaphInventory,
    Transforms = {
        FirstPerson = matrices.mat4():translate(-6,4,0),
        FirstPersonOffhand = matrices.mat4():translate(6,4,0),
        Dropped = matrices.mat4():translate(-8,0,0),
        Inventory = matrices.mat4():rotate(45,-45 ,0):translate(11.5,0.5,0) * matrices.mat4():scale(-1,1,1),
        ThirdPerson = matrices.mat4():rotate(45,-45,0):scale(2):translate(6,8,-6),
        ThirdPersonOffhand = matrices.mat4():rotate(45,45,0):scale(2):translate(-6,8,-6)
    }
})
    :setOnHit(function (self, hit, itemStack, hand, modifiers)
        print(hit, itemStack, hand, modifiers)
    end)
    :setOnUse(function (self, itemStack, hand, modifiers)
        print(itemStack, hand, modifiers)
    end)


