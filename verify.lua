--// Use the game to test it ingame, there are animations and server part which exists there. thanks.
local Player = game:GetService('Players').LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local cam = workspace.CurrentCamera
local hrp = Character:WaitForChild("HumanoidRootPart")
local doubleJumpEnabled = false
local Sliding = false
local jumpCooldown = 3.0
local plr = game.Players.LocalPlayer
local Jumped = false --Debounce
local RootJoint = Character:WaitForChild('HumanoidRootPart'):WaitForChild('RootJoint')
local Force = nil
local Direction = nil
local V1 = 0
local V2 = 0
local RootJointC0 = RootJoint.C0
local Remote = script:WaitForChild('RemoteEvent')
local LMBs = {
	LMB1 = "rbxassetid://138072732459393";
	LMB2 = "rbxassetid://138072732459393";
	LMB3 = "rbxassetid://138072732459393";
};
local MaxLMBs = 3 --// Max LMBS
local HeavyAnim = Humanoid:LoadAnimation(script:WaitForChild('Heavy'))
local ParryAnim = Humanoid:LoadAnimation(script:WaitForChild('Heavy'))
local LMBsAnim = {}
for i,v in pairs(LMBs) do
	local anim = Instance.new('Animation')
	anim.AnimationId = v
	local Load = Humanoid:LoadAnimation(anim)
	LMBsAnim[i] = Load
end

local function GetHitbox(Range)
	local tab = {}
	for i,v in pairs(workspace:GetChildren()) do
		if v:IsA('Model') and v:FindFirstChild('Humanoid') and v.Humanoid.Health > 0
			and v ~= Character and v:FindFirstChild('HumanoidRootPart') and
			(v.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Magnitude < Range
		then
			table.insert(tab, v)
		end
	end
	return tab
end
local NormalCD = false
local HeavyCD = false
local ParryCD = false
--// Animations, make sure they exists
local Animations = {
	["AirDash"] = script:WaitForChild('AirDash');
	["Roll"] = script:WaitForChild('Roll');
	["Slide"] = script:WaitForChild('Slide');
}
local anim = {}
for i,v in pairs(Animations) do
	if v then
		local load = Humanoid:LoadAnimation(v)
		anim[i] = load
	end
end
local Functions;
--// Functions
Functions = {
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
		local bodyVel = Instance.new("BodyVelocity")
		bodyVel.Name = "Dash"
		game.Debris:AddItem(bodyVel, Time)
		local direction = Character.Humanoid.MoveDirection * Vector3.new(2.3,0,2.3)
		if direction == Vector3.new(0,0,0) then
			direction = Character.Head.CFrame.LookVector * Vector3.new(2.3,0,2.3)
		end
		anim.AirDash:Play()
		local mousecf = game.Players.LocalPlayer:GetMouse().Hit
		direction = Character.Humanoid.MoveDirection * Vector3.new(2.3,2.3,2.3)
		bodyVel.Parent = Character.PrimaryPart
		bodyVel.MaxForce = Vector3.new(25000,0,25000)
		local mass = 0
		for _,v in pairs(Character:GetChildren()) do
			if v:IsA("BasePart") and v.Massless == false then
				mass += v.Mass
			end
		end
		bodyVel.Velocity = direction * (mass * Speed)
		Functions.CreateCooldown("Dash", 1)
	end,
	["Double Jump"] = function()
		if doubleJumpEnabled then
			if Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				if Character:FindFirstChild("DoubleJump") then return end
				Functions.CreateCooldown("DoubleJump", 2.5)
				Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				doubleJumpEnabled = false
			end
		end
	end,
	["Slide"] = function()
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
		wait(0.1)
		Sliding = false	
	end,
}
local function Normal()
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
		wait(0.25) --// how fast
		local hit = GetHitbox(8)
		Remote:FireServer("DoDamage", hit, 15)
	elseif Combo.Value >= MaxLMBs then
		Combo:Destroy()
		LMBsAnim["LMB"..Combo.Value]:Play()
		wait(0.25) --// how fast
		local hit = GetHitbox(8)
		Remote:FireServer("DoDamage", hit, 15)
		NormalCD = true
		wait(2.5)
		NormalCD = false
	end
end
local function Heavy()
	if HeavyCD then return end
	HeavyCD = true
	HeavyAnim:Play()
	wait(0.15)
	local hit = GetHitbox(8)
	print('Heavy')
	Remote:FireServer("DoDamage", hit, 15)
	wait(2.5)
	HeavyCD = false
end
local function Parry()
	if HeavyCD then return end
	ParryCD = true
	print('Parry')
	Remote:FireServer("Parry")
	wait(2.5)
	ParryCD = false
end
local func = Functions
--// State Change
Humanoid.StateChanged:Connect(function(_oldState, newState)
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
UserInputService.JumpRequest:Connect(function()
	local char = plr.Character
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
local crouching = false
local Crouch = Humanoid:LoadAnimation(script.Crouch)
local walkAnim = Humanoid:LoadAnimation(script.CrouchWalk)
UserInputService.InputBegan:Connect(function(inputObject, gc)
	if gc then return end
	task.spawn(function()
		if inputObject.KeyCode and inputObject.KeyCode ~= Enum.KeyCode.Unknown then
			local a = inputObject.KeyCode
			local key = tostring(a):split(".")
			func.CreateKey(tostring(key[3]))
		end
	end)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		Normal()
	end
	if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
		Heavy()
	end

	if inputObject.KeyCode == Enum.KeyCode.R then
		Parry()
	end
	if inputObject.KeyCode == Enum.KeyCode.Space then
		func["Double Jump"]()
	end
	if inputObject.KeyCode == Enum.KeyCode.Q then
		func.Dash(4.5, 0.25)
	end
	if inputObject.KeyCode == Enum.KeyCode.T then
		func.Slide()
	end
	if inputObject.KeyCode == Enum.KeyCode.C then
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
UserInputService.InputEnded:Connect(function(inputObject, gc)
	if gc then return end
	task.spawn(function()
		local a = inputObject.KeyCode
		local key = tostring(a):split(".")
		if Character:FindFirstChild(tostring(key[3])) then
			Character:FindFirstChild(tostring(key[3])):Destroy()
		end
	end)
end)
RunService.RenderStepped:Connect(function()
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
