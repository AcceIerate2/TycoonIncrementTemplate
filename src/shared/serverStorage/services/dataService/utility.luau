-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local deepCopyDict = require(ReplicatedStorage.src.utility.deepCopyDict)

-->
local utility = {}

local function resolveTarget(root, directory)
	if directory ~= nil then
		root[directory] = root[directory] or {}
		return root[directory]
	end
	return root
end

function utility.createValueObject(
	name,
	value,
	profileStoreDataConnection,
	updateClient: (key: string, newValue: any?) -> ()
)
	local bindableEvent = Instance.new("BindableEvent")
	return {
		Key = name,
		Value = value,
		Profile = profileStoreDataConnection,

		Get = function(_self)
			return TypeCheck.table(_self["Value"]) and deepCopyDict(_self["Value"]) or _self["Value"]
		end,

		Set = function(_self, newValue)
			_self.Value = newValue
			_self.Profile[_self.Key] = newValue
			_self.BindableEvent:Fire(newValue)
			updateClient(_self.Key, newValue)
		end,

		Insert = TypeCheck.table(value) and function(_self, directory, key, data)
			local cached = deepCopyDict(_self.Value)
			local target = resolveTarget(cached, directory)

			if key then
				local entry = target[key]
				if entry and entry.UsesLeft then
					entry.UsesLeft += 1
				else
					target[key] = data
				end
			else
				table.insert(target, data)
			end

			_self:Set(cached)
		end,

		Remove = TypeCheck.table(value) and function(_self, directory, key, reference, referenceKey)
			local cached = deepCopyDict(_self.Value)
			local target = resolveTarget(cached, directory)

			if key then
				local entry = target[key]
				if TypeCheck.table(entry) and entry.UsesLeft and entry.UsesLeft > 1 then
					entry.UsesLeft -= 1
				else
					target[key] = nil
				end
			elseif reference then
				local idx = table.find(target, reference)
				if idx then
					table.remove(target, idx)
				elseif referenceKey then
					for i, v in ipairs(target) do
						if v[referenceKey] == reference then
							table.remove(target, i)
							break
						end
					end
				end
			end

			_self:Set(cached)
		end,

		Clear = TypeCheck.table(value) and function(_self, directory)
			local cached = deepCopyDict(_self.Value)

			if directory ~= nil then
				cached[directory] = {}
			else
				table.clear(cached)
			end

			_self:Set(cached)
		end,

		Update = TypeCheck.table(value) and function(_self, mutator)
			assert(typeof(mutator) == "function", "Update requires a function")

			local cached = deepCopyDict(_self.Value)
			mutator(cached)
			_self:Set(cached)
		end,

		BindableEvent = bindableEvent,
		Changed = bindableEvent.Event,

		Destroy = function(_self)
			_self.BindableEvent:Destroy()
			_self.BindableEvent = nil
			_self.Changed = nil
			_self.Key = nil
			_self.Value = nil
			_self.Profile = nil
			_self.Get = nil
			_self.Set = nil
			_self.Destroy = nil
		end,
	}
end

return utility
