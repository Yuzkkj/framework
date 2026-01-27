local Janitor = require(script.Parent.Janitor)

export type Service = {
	Init: (Service) -> (),
	Start: (Service) -> (),
}

export type Controller = {
	Init: (Controller) -> (),
	Start: (Controller) -> (),
}

type Object<T> = typeof(setmetatable({} :: { _janitor: Janitor.Janitor }, {} :: Component<T>))

export type Component<T> = {
	Tag: string,
	new: (T) -> Object<T>,
	Destroy: (Object<T>) -> (),
}

export type Handler = () -> ()

export type UI = () -> ()

return {}
