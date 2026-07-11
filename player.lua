local Player = {}

function Player:Initialize(Tab)
    print("Player module loading...")
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    
    local Settings = {
        CustomWalkSpeed = false,
        WalkSpeed = 16,
        CustomJumpPower = false,
        JumpPower = 50,
        LoopSpeed = false,
        LoopJump = false,
        InfJump = false,
        FlyEnabled = false,
        FlySpeed = 50,
        NoClip = false
    }
    
    local FlyConnection = nil
    local LoopConnection = nil
    local InfJumpConnection = nil
    
    local Movement = Tab:AddLeftGroupbox("Movement")
    local FlyGroup = Tab:AddRightGroupbox("Fly")
    local Other = Tab:AddLeftGroupbox("Other")
    
    Movement:AddToggle("CustomWalkSpeed", {
        Text = "Custom Walk Speed",
        Default = false,
        Callback = function(v) 
            Settings.CustomWalkSpeed = v
        end
    })
    
    Movement:AddSlider("WalkSpeed", {
        Text = "Walk Speed",
        Default = 16,
        Min = 1,
        Max = 200,
        Rounding = 0,
        Callback = function(v) 
            Settings.WalkSpeed = v
        end
    })
    
    Movement:AddToggle("LoopSpeed", {
        Text = "Loop Speed",
        Default = false,
        Callback = function(v) 
            Settings.LoopSpeed = v
        end
    })
    
    Movement:AddToggle("CustomJumpPower", {
        Text = "Custom Jump Power",
        Default = false,
        Callback = function(v) 
            Settings.CustomJumpPower = v
        end
    })
    
    Movement:AddSlider("JumpPower", {
        Text = "Jump Power",
        Default = 50,
        Min = 1,
        Max = 500,
        Rounding = 0,
        Callback = function(v) 
            Settings.JumpPower = v
        end
    })
    
    Movement:AddToggle("LoopJump", {
        Text = "Loop Jump",
        Default = false,
        Callback = function(v) 
            Settings.LoopJump = v
        end
    })
    
    Movement:AddToggle("InfJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(v) 
            Settings.InfJump = v
        end
    })
    
    FlyGroup:AddToggle("FlyEnabled", {
        Text = "Fly",
        Default = false,
        Callback = function(v) 
            Settings.FlyEnabled = v
        end
    })
    
    FlyGroup:AddSlider("FlySpeed", {
        Text = "Fly Speed",
        Default = 50,
        Min = 1,
        Max = 200,
        Rounding = 0,
        Callback = function(v) 
            Settings.FlySpeed = v
        end
    })
    
    Other:AddToggle("NoClip", {
        Text = "No Clip",
        Default = false,
        Callback = function(v) 
            Settings.NoClip = v
        end
    })
    
    print("Player module loaded!")
    
    return {
        Cleanup = function()
            print("Player cleanup!")
        end
    }
end

return Player
