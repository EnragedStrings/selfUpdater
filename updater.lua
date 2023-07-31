--Self Updater
local fs = require("filesystem")
local serial = require("serialization")
local shell = require("shell")
local internet = require("internet")

local program = {path="", autostart = false, github = ""}
local programsPath = "/etc/updaterPrograms"

local function save(path, data)
    local file = assert(io.open(path, "w"))
    file:write(data)
    file:close()
end
local function load(path)
    local file = assert(io.open(path, "r"))
    local data = file:read("*all")
    file:close()
    return data
end
local function create(path)
    local file = assert(io.open(path, "w"))
    file:close()
end

updater = {}

function updater.savePrograms(data)
    if fs.exists(programsPath) then
        save(programsPath, serial.serialize(data))
    else
        create(programsPath)
        save(programsPath, serial.serialize(data))
    end
end

function updater.loadPrograms()
    if fs.exists(programsPath) then
        return serial.unserialize(load(programsPath))
    else
        create(programsPath)
        return serial.unserialize(load(programsPath))
    end
end

function updater.newProgram(path, github, autostart)
    local newProgram = setmetatable({}, { __index = program })
    newProgram.path = path
    newProgram.github = github
    newProgram.autostart = autostart
    local Programs = updater.loadPrograms()
    if Programs == nil then
        Programs = {}
    end
    Programs[github] = newProgram
    updater.savePrograms(Programs)
end

function updater.updateProgram(program)
    if fs.exists(program.path) then
        shell.execute("rm "..program.path)
    end
    shell.execute("wget -Q "..program.github.." "..program.path)
end


local function start()
    local programs = updater.loadPrograms()
    local autostarts = {}
    if programs ~= nil then
        for github, program in pairs(programs) do
            updater.updateProgram(program)
            if program.autostart then
                table.insert(autostarts, program)
            end
        end
        for _, program in pairs(autostarts) do
            shell.execute(program.path)
        end
    end
end

start()
