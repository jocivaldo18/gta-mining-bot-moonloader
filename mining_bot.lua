-- Bot Minerador Automático para GTA SA com MoonLoader
-- Versão 1.0
-- Autor: jocivaldo18

script_name("Mining Bot")
script_author("jocivaldo18")
script_version("1.0")

local imgui = require 'imgui'
local encoding = require 'encoding'
encoding.default = 'UTF-8'
u8 = encoding.UTF8

local mining_bot = {
    enabled = false,
    mining = false,
    returning = false,
    carrying_ore = false,
    current_ore = 0,
    max_ore = 100,
    
    -- Coordenadas
    mine_location = {x = 629.5, y = -544.8, z = 17.6}, -- Local da mina
    dump_location = {x = 2794.5, y = -1438.2, z = 106.5}, -- Local de descarga
    
    -- Velocidade de navegação
    speed = 30,
    
    -- Status
    status = "Parado",
    logs = {}
}

local ui_state = {
    show_window = true,
    mine_x = mining_bot.mine_location.x,
    mine_y = mining_bot.mine_location.y,
    mine_z = mining_bot.mine_location.z,
    dump_x = mining_bot.dump_location.x,
    dump_y = mining_bot.dump_location.y,
    dump_z = mining_bot.dump_location.z,
    max_ore_input = mining_bot.max_ore,
    speed_input = mining_bot.speed
}

function mining_bot:addLog(message)
    table.insert(self.logs, "[" .. os.date("%H:%M:%S") .. "] " .. message)
    if #self.logs > 50 then
        table.remove(self.logs, 1)
    end
end

function mining_bot:distance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end

function mining_bot:navigate(target_x, target_y, target_z)
    if not doesCharExist(PLAYER_PED) then return false end
    
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local distance = self:distance(px, py, pz, target_x, target_y, target_z)
    
    if distance < 5 then
        return true
    end
    
    -- Calcular direção
    local dx = target_x - px
    local dy = target_y - py
    local angle = math.atan2(dy, dx)
    
    -- Movimentar jogador
    setCharCoordinates(PLAYER_PED, px + math.cos(angle) * self.speed * 0.016, py + math.sin(angle) * self.speed * 0.016, pz)
    
    return false
end

function mining_bot:mine()
    if not doesCharExist(PLAYER_PED) then return end
    
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local distance = self:distance(px, py, pz, self.mine_location.x, self.mine_location.y, self.mine_location.z)
    
    if distance > 10 then
        self.status = "Indo para mina..."
        if self:navigate(self.mine_location.x, self.mine_location.y, self.mine_location.z) then
            self.status = "Coletando minério..."
            self.current_ore = self.current_ore + 5
            if self.current_ore >= self.max_ore then
                self.current_ore = self.max_ore
                self.carrying_ore = true
                self:addLog("Mina cheia! " .. self.current_ore .. "/" .. self.max_ore)
            end
        end
    else
        self.status = "Coletando minério..."
        self.current_ore = math.min(self.current_ore + 1, self.max_ore)
        
        if self.current_ore >= self.max_ore then
            self.carrying_ore = true
            self.mining = false
            self.returning = true
            self:addLog("Mina completa! Retornando...")
        end
    end
end

function mining_bot:dump()
    if not doesCharExist(PLAYER_PED) then return end
    
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local distance = self:distance(px, py, pz, self.dump_location.x, self.dump_location.y, self.dump_location.z)
    
    if distance > 10 then
        self.status = "Retornando para descarga..."
        if self:navigate(self.dump_location.x, self.dump_location.y, self.dump_location.z) then
            self.status = "Descarregando..."
            self.current_ore = 0
            self.carrying_ore = false
            self.returning = false
            self.mining = true
            self:addLog("Minério descarregado!")
        end
    else
        self.status = "Descarregando..."
        self.current_ore = 0
        self.carrying_ore = false
        self.returning = false
        self.mining = true
        self:addLog("Minério descarregado!")
    end
end

function mining_bot:update()
    if not self.enabled then return end
    
    if not doesCharExist(PLAYER_PED) then
        self.status = "Jogador não encontrado"
        return
    end
    
    if self.carrying_ore or self.current_ore >= self.max_ore then
        self.mining = false
        self.returning = true
    end
    
    if self.returning then
        self:dump()
    elseif self.mining then
        self:mine()
    else
        self.status = "Aguardando..."
    end
end

function drawImGui()
    if ui_state.show_window then
        imgui.SetNextWindowPos(imgui.ImVec2(10, 10), imgui.Cond_FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(400, 600), imgui.Cond_FirstUseEver)
        
        imgui.Begin("Mining Bot ##main", ui_state.show_window, imgui.WindowFlags_AlwaysAutoResize)
        
        -- Status principal
        imgui.Text("Status: " .. mining_bot.status)
        imgui.SameLine()
        imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), mining_bot.enabled and "ATIVO" or "INATIVO")
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        -- Botão de ativar/desativar
        if imgui.Button(mining_bot.enabled and "DESATIVAR BOT" or "ATIVAR BOT", imgui.ImVec2(200, 30)) then
            mining_bot.enabled = not mining_bot.enabled
            if mining_bot.enabled then
                mining_bot:addLog("Bot ativado!")
                mining_bot.mining = true
            else
                mining_bot:addLog("Bot desativado!")
            end
        end
        
        imgui.Spacing()
        
        -- Progresso de minério
        imgui.Text("Minério Coletado:")
        imgui.ProgressBar(mining_bot.current_ore / mining_bot.max_ore, imgui.ImVec2(350, 20))
        imgui.Text(mining_bot.current_ore .. " / " .. mining_bot.max_ore)
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        -- Configurações da Mina
        imgui.Text("Localização da Mina:")
        ui_state.mine_x = imgui.InputFloat("Mine X##1", ui_state.mine_x, 0.1)
        ui_state.mine_y = imgui.InputFloat("Mine Y##1", ui_state.mine_y, 0.1)
        ui_state.mine_z = imgui.InputFloat("Mine Z##1", ui_state.mine_z, 0.1)
        
        if imgui.Button("Definir Local Atual como Mina", imgui.ImVec2(350, 25)) then
            local px, py, pz = getCharCoordinates(PLAYER_PED)
            ui_state.mine_x = px
            ui_state.mine_y = py
            ui_state.mine_z = pz
            mining_bot.mine_location = {x = px, y = py, z = pz}
            mining_bot:addLog("Mina definida em: " .. string.format("%.1f, %.1f, %.1f", px, py, pz))
        end
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        -- Configurações da Descarga
        imgui.Text("Localização de Descarga:")
        ui_state.dump_x = imgui.InputFloat("Dump X##1", ui_state.dump_x, 0.1)
        ui_state.dump_y = imgui.InputFloat("Dump Y##1", ui_state.dump_y, 0.1)
        ui_state.dump_z = imgui.InputFloat("Dump Z##1", ui_state.dump_z, 0.1)
        
        if imgui.Button("Definir Local Atual como Descarga", imgui.ImVec2(350, 25)) then
            local px, py, pz = getCharCoordinates(PLAYER_PED)
            ui_state.dump_x = px
            ui_state.dump_y = py
            ui_state.dump_z = pz
            mining_bot.dump_location = {x = px, y = py, z = pz}
            mining_bot:addLog("Descarga definida em: " .. string.format("%.1f, %.1f, %.1f", px, py, pz))
        end
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        -- Configurações avançadas
        imgui.Text("Configurações:")
        ui_state.max_ore_input = imgui.InputInt("Máximo de Minério", ui_state.max_ore_input)
        mining_bot.max_ore = ui_state.max_ore_input
        
        ui_state.speed_input = imgui.InputFloat("Velocidade", ui_state.speed_input, 0.5)
        mining_bot.speed = ui_state.speed_input
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        -- Log
        imgui.Text("Log:")
        imgui.BeginChild("##log", imgui.ImVec2(350, 150), true)
        for _, log in ipairs(mining_bot.logs) do
            imgui.Text(log)
        end
        imgui.EndChild()
        
        imgui.End()
    end
end

function imgui.OnImGuiRender(draw_commands)
    drawImGui()
end

function main()
    if not isSampLoaded() then return end
    while not isSampLoaded() do wait(100) end
    
    mining_bot:addLog("Bot carregado com sucesso!")
    
    while true do
        wait(16) -- ~60 FPS
        
        if imgui.GetIO().WantCaptureMouse then
            consumeClick()
        end
        
        mining_bot:update()
    end
end

imgui.OnFrame(
    function() return ui_state.show_window end,
    function(player)
        drawImGui()
    end
)
