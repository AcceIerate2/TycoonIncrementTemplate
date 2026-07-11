-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local PanelController = knit.CreateController({
	Name = "PanelController",
	TogglePanel = Signal.new(),
	PanelStateChanged = Signal.new(), -- {Visible: boolean, PanelName: string}
	ActivePanel = nil :: string?,
})

function PanelController:togglePanel(panelName: string)
	self.TogglePanel:Fire(panelName)
end

function PanelController:updateActivePanel(panelName: string)
	self.ActivePanel = panelName
end

function PanelController:waitForPanelToClose(panelName: string, timeoutSeconds: number?)
	local hasClosed = false
	local panelStateChangedConnection: RBXScriptConnection? = nil

	local function disconnect()
		if not panelStateChangedConnection then
			return
		end

		panelStateChangedConnection:Disconnect()
		panelStateChangedConnection = nil
	end

	panelStateChangedConnection = self.PanelStateChanged:Connect(function(state: {
		Visible: boolean,
		PanelName: string,
	})
		if state.PanelName ~= panelName or state.Visible then
			return
		end

		hasClosed = true
		disconnect()
	end)

	local startTimeSeconds = os.clock()

	while not hasClosed do
		if timeoutSeconds and (os.clock() - startTimeSeconds) >= timeoutSeconds then
			disconnect()
			return false
		end
		task.wait()
	end
	return true
end

function PanelController:KnitInit() end

return PanelController
