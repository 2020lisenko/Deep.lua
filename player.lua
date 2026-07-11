local Player = {}

function Player:Initialize(Tab)
    print("Player Initialize called!")
    print("Tab:", Tab)
    
    -- Простой тест - создаем одну кнопку
    local testGroup = Tab:AddLeftGroupbox("Test")
    testGroup:AddButton("Click Me", function()
        print("Button clicked!")
    end)
    
    -- Теперь добавляем реальные функции
    local Movement = Tab:AddLeftGroupbox("Movement")
    
    Movement:AddToggle("CustomWalkSpeed", {
        Text = "Custom Walk Speed",
        Default = false,
        Callback = function(v) 
            print("Walk Speed:", v)
        end
    })
    
    Movement:AddSlider("WalkSpeed", {
        Text = "Walk Speed",
        Default = 16,
        Min = 1,
        Max = 200,
        Rounding = 0,
        Callback = function(v) 
            print("Speed value:", v)
        end
    })
    
    local Fly = Tab:AddRightGroupbox("Fly")
    
    Fly:AddToggle("FlyEnabled", {
        Text = "Fly",
        Default = false,
        Callback = function(v) 
            print("Fly:", v)
        end
    })
    
    Fly:AddSlider("FlySpeed", {
        Text = "Fly Speed",
        Default = 50,
        Min = 1,
        Max = 200,
        Rounding = 0,
        Callback = function(v) 
            print("Fly speed:", v)
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
