--// Use the game to test it ingame, there are animations and server part which exists there. thanks.
local Player = game:GetService('Players').LocalPlayer --// This is our localplayer, US
local UserInputService = game:GetService("UserInputService") --// Roblox InputService
local RunService = game:GetService("RunService") --// Roblox RunService
local Character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait() --// We are Getting the Character :)
local Humanoid = Character:WaitForChild("Humanoid") --// Waiting for Humanoid, so we can do stuff
local hrp = Character:WaitForChild("HumanoidRootPart") --// Our Root Part
local RootJoint = Character:WaitForChild('HumanoidRootPart'):WaitForChild('RootJoint') --// Root Joint Getting
local RootJointC0 = RootJoint.C0
local cam = workspace.CurrentCamera --// This would be our current local camera
--// VARIABLES
local doubleJumpEnabled = false --// bool
local Sliding = false --// Bool
local jumpCooldown = 3.0 --// Cooldown Number
local Jumped = false -- Cooldown Debounce
local Force = nil --// Variable for force dash
local Direction = nil --// Variable for direction dash
local V1 = 0
local V2 = 0
local Remote = script:WaitForChild('RemoteEvent') --// Our Precious Remote EVent
--// Our Left Mouse Button Animations
local LMBs = {
	LMB1 = "rbxassetid://14048124895";
	LMB2 = "rbxassetid://14048124895";
	LMB3 = "rbxassetid://14048124895";
};
local MaxLMBs = 3 --// Max LMBS
local HeavyAnim = Humanoid:LoadAnimation(script:WaitForChild('Heavy')) --// Animation
local ParryAnim = Humanoid:LoadAnimation(script:WaitForChild('Parry')) --// animation
local LMBsAnim = {} --// Table
for i,v in pairs(LMBs) do --// We are making it into animations, adding it to a table to be played later :)
	local anim = Instance.new('Animation')
	anim.AnimationId = v
	local Load = Humanoid:LoadAnimation(anim)
	LMBsAnim[i] = Load
end
local NormalCD = false --// Cooldown
local HeavyCD = false --// cooldown
local ParryCD = false --// Cooldown
--// Animations, make sure they exists
local Animations = { --// more Animations
	["AirDash"] = script:WaitForChild('AirDash');
	["Roll"] = script:WaitForChild('Roll');
	["Slide"] = script:WaitForChild('Slide');
}
local anim = {} --// same Loading as above
for i,v in pairs(Animations) do
	if v then
		local load = Humanoid:LoadAnimation(v)
		anim[i] = load
	end
end
local function GetHitbox(Range) --// A Very Simple Magnitude Based Hitbox -- READ BELOW IF YOU DONT UNDERSTAND
	local tab = {}
	for i,v in pairs(workspace:GetChildren()) do --// Getting Childrens in workspace
		if v:IsA('Model') and v:FindFirstChild('Humanoid') and v.Humanoid.Health > 0 --// checking if model and has health higher than 0
			and v ~= Character and v:FindFirstChild('HumanoidRootPart') and
			(v.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Magnitude < Range --// Range functional argument check
		then
			table.insert(tab, v) --// Adding it to the table then
		end
	end
	return tab --// returning table :D
end
local Functions; --// nil for now, but will be a table.
Functions = { --// Above table
	["CreateCooldown"] = function(Name, Time)
		local ins = Instance.new('StringValue')
		ins.Name = Name
		ins.Parent = Character
		game.Debris:AddItem(ins, Time)
		return ins
	end,
	["CreateKey"] = function(Key)
		local ins = Instance.new('StringValue')
		ins.Name = Key
		ins.Parent = Character
	end;
	["Dash"] = function(Speed, Time)
		if Character:FindFirstChild("Dash") then return end
		local bodyVel = Instance.new("BodyVelocity") --// IF YOU SAY ITS DEPRECATED, IT DOESN'T MATTER, IT WORKS AND CAN BE USED, I AM NOT SCRIPTING A PAID SERVICE HERE, IT IS JUST FOR VERIFICATION.
		bodyVel.Name = "Dash" --// Body Velocity Name
		game.Debris:AddItem(bodyVel, Time) --// Adding to debris
		local direction = Character.Humanoid.MoveDirection * Vector3.new(2.3,0,2.3) --// Direction
		if direction == Vector3.new(0,0,0) then
			direction = Character.Head.CFrame.LookVector * Vector3.new(2.3,0,2.3)
		end
		anim.AirDash:Play()
		local mousecf = game.Players.LocalPlayer:GetMouse().Hit 
		direction = Character.Humanoid.MoveDirection * Vector3.new(2.3,2.3,2.3)
		bodyVel.Parent = Character.PrimaryPart
		bodyVel.MaxForce = Vector3.new(25000,0,25000)
		local mass = 0
		for _,v in pairs(Character:GetChildren()) do --// Making character baseparts massless
			if v:IsA("BasePart") and v.Massless == false then
				mass += v.Mass
			end
		end
		bodyVel.Velocity = direction * (mass * Speed)
		Functions.CreateCooldown("Dash", 1)
		--// Just read above, please
	end,
	["Double Jump"] = function() --// Double jump, change state and stuff if state is freefal and no cooldown
		if doubleJumpEnabled then
			if Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				if Character:FindFirstChild("DoubleJump") then return end
				Functions.CreateCooldown("DoubleJump", 2.5)
				Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				doubleJumpEnabled = false
			end
		end
	end,
	["Slide"] = function() --// Sliding with body velocity, same thing different animation and better control
		if Character:FindFirstChild("Slide") then return end
		local EHMMM = 5
		local Power = 16
		Sliding = true
		local bodyVel = Instance.new("BodyVelocity")
		bodyVel.Name = "Sliding"
		local direction = Character.Humanoid.MoveDirection * Vector3.new(3,0,3)
		if direction == Vector3.new(0,0,0) then
			direction = Character.HumanoidRootPart.CFrame.LookVector * Vector3.new(3,0,3)
		end
		anim.Slide:Play()
		Character.HumanoidRootPart.CFrame = CFrame.new(Character.HumanoidRootPart.CFrame.p, Character.HumanoidRootPart.CFrame.p + direction)
		bodyVel.Parent = Character.HumanoidRootPart
		bodyVel.MaxForce = Vector3.new(25000,1000,25000)
		local mass = 0
		for _,v in pairs(Character:GetChildren()) do
			if v:IsA("BasePart") and v.Massless == false then
				mass += v.Mass
			end
		end
		bodyVel.Velocity = (direction + Vector3.new(0,2,0)) * (mass * 1.2)
		repeat task.wait(0.1) 
			EHMMM += 1 
			bodyVel.Velocity = (direction + Vector3.new(0,2,0)) * (mass * ((EHMMM/20)/(EHMMM/20))/((EHMMM/20)*((EHMMM/20)/2))/10) 
		until EHMMM == Power --or not character:FindFirstChild('C')
		game:GetService("Debris"):AddItem(bodyVel, 0.15) 
		Functions.CreateCooldown("Slide", 0.15)
		task.wait(0.1)
		Sliding = false	
	end,
}
local function Normal() --// Normal Combo M1s, Play Animation & Then get hitbox/attack
	if NormalCD then return end
	local Combo = Character:FindFirstChild('Combo')
	if Combo then
		local old = Combo.Value
		Combo:Destroy()
		Combo= Instance.new('NumberValue')
		game.Debris:AddItem(Combo, 0.5)
		Combo.Name = "Combo"
		Combo.Value = old+1
		Combo.Parent = Character 
	else
		Combo= Instance.new('NumberValue')
		game.Debris:AddItem(Combo, 0.5)
		Combo.Name = "Combo"
		Combo.Value = 1
		Combo.Parent = Character
	end
	print('LMB'..Combo.Value)
	if Combo.Value < MaxLMBs then
		LMBsAnim["LMB"..Combo.Value]:Play()
		task.wait(0.25) --// how fast
		local hit = GetHitbox(8)
		Remote:FireServer("DoDamage", hit, 15)
	elseif Combo.Value >= MaxLMBs then
		Combo:Destroy()
		LMBsAnim["LMB"..Combo.Value]:Play()
		task.wait(0.25) --// how fast
		local hit = GetHitbox(8)
		Remote:FireServer("DoDamage", hit, 15)
		NormalCD = true
		task.wait(2.5)
		NormalCD = false
	end
end
local function Heavy() --// Heavy same as above but heavy more damage
	if HeavyCD then return end
	HeavyCD = true
	HeavyAnim:Play()
	task.wait(0.15)
	local hit = GetHitbox(8)
	print('Heavy')
	Remote:FireServer("DoDamage", hit, 15)
	task.wait(2.5)
	HeavyCD = false
end
local function Parry() --// Parry check backend
	if HeavyCD then return end
	ParryCD = true
	print('Parry')
	Remote:FireServer("Parry")
	wait(2.5)
	ParryCD = false
end
local func = Functions
--// State Change
Humanoid.StateChanged:Connect(function(_oldState, newState) --// Double Jump & for slide
	if newState == Enum.HumanoidStateType.Jumping then
		if Sliding then
			local Push = Character.HumanoidRootPart:FindFirstChild('Sliding')
			if Push then
				Push:Destroy()
				Sliding = false
			end
		end
		if not doubleJumpEnabled then
			task.wait(0.2)
			if Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				doubleJumpEnabled = true
			end
		end
	end
end)
--// Jump Cooldown
UserInputService.JumpRequest:Connect(function() --// Jump Cooldown
	local char = Player.Character
	if not Jumped then
		if char.Humanoid.FloorMaterial == Enum.Material.Air then return end
		Jumped = true
		char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) 
		task.wait(jumpCooldown)
		Jumped = false
	else
		char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	end
end)
--// Below is input handling
local crouching = false --// Crouch CD
local Crouch = Humanoid:LoadAnimation(script.Crouch) --// animations
local walkAnim = Humanoid:LoadAnimation(script.CrouchWalk) --// walk animation
UserInputService.InputBegan:Connect(function(inputObject, gc)
	if gc then return end
	task.spawn(function()
		if inputObject.KeyCode and inputObject.KeyCode ~= Enum.KeyCode.Unknown then
			local a = inputObject.KeyCode
			local key = tostring(a):split(".")
			func.CreateKey(tostring(key[3])) --// this is to detect keys, could be done better but wtv
		end
	end)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then --// M1s
		Normal()
	end
	if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then --// Heavy
		Heavy()
	end

	if inputObject.KeyCode == Enum.KeyCode.R then --// Parry
		Parry()
	end
	if inputObject.KeyCode == Enum.KeyCode.Space then --// double Jump
		func["Double Jump"]()
	end
	if inputObject.KeyCode == Enum.KeyCode.Q then --// Dash with arguments
		func.Dash(4.5, 0.25)
	end
	if inputObject.KeyCode == Enum.KeyCode.T then ---// Slide
		func.Slide()
	end
	if inputObject.KeyCode == Enum.KeyCode.C then --// Couch with crouch walk etc
		if crouching == false then
			Crouch:Play()
			Humanoid.WalkSpeed = 7
			Humanoid.JumpHeight = 0
			Humanoid.JumpPower = 0
			crouching = true
		else
			walkAnim:Stop()
			Crouch:Stop()
			crouching = false
			Humanoid.WalkSpeed = 17
			Humanoid.JumpHeight = 50
			Humanoid.JumpPower = 50
		end
	end
end)
UserInputService.InputEnded:Connect(function(inputObject, gc) --// Input Ended, End the key created
	if gc then return end
	task.spawn(function()
		local a = inputObject.KeyCode
		local key = tostring(a):split(".")
		if Character:FindFirstChild(tostring(key[3])) then
			Character:FindFirstChild(tostring(key[3])):Destroy()
		end
	end)
end)
RunService.RenderStepped:Connect(function() --// Tilting
	Force = hrp.Velocity * Vector3.new(1,0,1)
	if Force.Magnitude > 2 then
		Direction = Force.Unit
		V1 = hrp.CFrame.RightVector:Dot(Direction)
		V2 = hrp.CFrame.LookVector:Dot(Direction)
	else
		V1 = 0
		V2 = 0
	end
	RootJoint.C0 = RootJoint.C0:Lerp(RootJointC0 * CFrame.Angles(math.rad(-V2 * 10), math.rad(-V1 * 10), 0), 0.2)
end)

--// Okay thank you, I hope you understood all of it. This is just to verify coding skills on Hidden Developers.
--// Created by husya.com (Yuki-Sam-Snow)
