local Player = {}

function Player:Initialize(Tab)
    print("Player module loading...")
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    local Movement = Tab:AddLeftGroupbox("Movement")
    
    Movement:AddSlider("WalkSpeed", {
        Text = "Walk Speed",
        Default = 16,
        Min = 1,
        Max = 200,
        Rounding = 0,
        Callback = function(v)
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum.WalkSpeed = v
                    print("WalkSpeed set to:", v)
                end
            end
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
