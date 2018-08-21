------------------------------------------------------------------------------------------------
--
-- Maindocument van N00bfloria, bedoeld om programmeerlessen op te pakken uit mijn eerdere werk.
--
------------------------------------------------------------------------------------------------

local physics = require( "physics" )
physics.start()
physics.setGravity(0,0)
math.randomseed(os.time())
display.setStatusBar( display.HiddenStatusBar )

-- Displaygroepen aanmaken. 
local backgroundGroup = display.newGroup()
local baseGroup = display.newGroup()
local soldierGroup = display.newGroup()
local background = display.newImageRect( backgroundGroup, "Wood-Texture-Backgrounds.png", 1550, 2000 )
background.x = display.contentCenterX
background.y = display.contentCenterY

-- Game-instellingen
local soldierSpawnMax = 10
local gameMode = "hard"

-- Global initialisaties die nodig zijn om het geheel te kunnen draaien.
local baseArray = {}
local soldierArray = {}



-- Function die bases tekent en op een goeie plaats zet. Wordt bij het opstarten van de applicatie enkele keren aangeroepen. 
local function createBase( team )

    local sprite = "spell_fire_major.png"

    if ( team == "blue" ) then
        sprite = "spell_fire_minor.png"
    elseif ( team == "yellow" ) then
        sprite = "spell_fire_superior.png"
    end

local newBase = {}
newBase.image = display.newImageRect( baseGroup, sprite, 150, 150 )
newBase.image.parentObject = newBase


-- Wijs de base toe aan een team, en geef hem het objectType "base" voor makkelijke herkenning.
    newBase.team = team
    newBase.objectType = "base"

-- Bepaal een startlocatie voor de nieuwe base, rekening houdende met de lokaties van andere bases.
    local validBase = false

    while ( validBase == false ) do

        newBase.image.x = math.random( 100, display.contentWidth - 100 )
        newBase.image.y = math.random( 100, display.contentHeight - 100 )
        
        validBase = true
        
        if #baseArray >= 1 then   
            for i = 1, #baseArray do               
                if spotTaken( newBase.image.x, newBase.image.y, baseArray[i].image.x, baseArray[i].image.y ) == false then
                    validBase = false
                    break
                end
            end
        end

    end
-- newBase.isSelected wordt gebruikt voor het touch event waarmee je een base selecteert en vervolgens een commando aan haar soldaten kan geven. Hiervoor moet het veld gelijk al een waarde hebben.
    newBase.isSelected = false
    physics.addBody( newBase.image, "static", { radius=55 } )
    table.insert( baseArray, newBase )
end



function spotTaken( x1, y1, x2, y2 )

    -- Pythagoras: c = wortel van a2 + b2
    local distance = math.sqrt( ( x2 - x1 )^2  + ( y2 - y1 )^2 ) 

    -- Als afstand groot genoeg: return true, anders false.
    if ( distance > 300 ) then
        return true
    elseif ( distance <= 300 ) then
        return false 
    end
end



local function generateSoldiers()

    for i, base in ipairs( baseArray ) do
        
        if ( (base.team == "yellow" and gameMode == "easy" ) or base.team == "blue" ) then
            createSoldier( base )
        end
    end 
end


-- hardmode function. Deze function komt bij hard-mode bovenop de generateSoldiers functie.
local function generateSoldiersHardmode()

    for i, base in ipairs( baseArray ) do
        if( base.team == "yellow" and gameMode == "hard" ) then 
            createSoldier( base )
        end 
    end 
end 


-- Deze function creert 1 soldier voor 1 gegeven base.
function createSoldier( base )
    
-- Tel hoeveel soldaten er al om de huidige base heen vliegen.
    local currentSoldierCount = 0

    for i, soldier in ipairs( soldierArray ) do
        if soldier.currentBase == base then
            currentSoldierCount = currentSoldierCount + 1
        end
    end

-- Als de current soldier count lager is dan wat is toegestaan, mag er een nieuwe soldier aangemaakt worden.
    local randomImageNumber = math.random( 0, 1 )
    local newSoldier = {}

    if currentSoldierCount < soldierSpawnMax then
        
        if base.team == "blue" then
            if randomImageNumber == 0 then
                newSoldier.image = display.newImageRect( soldierGroup, "sapphire_1.png", 60, 60 )
            elseif randomImageNumber == 1 then
                newSoldier.image = display.newImageRect( soldierGroup, "sapphire_2.png", 60, 60 )
            end
        elseif base.team == "yellow" then
            if randomImageNumber == 0 then
                newSoldier.image = display.newImageRect( soldierGroup, "ruby_1.png", 60, 60 )
            elseif randomImageNumber == 1 then
                newSoldier.image = display.newImageRect( soldierGroup, "ruby_2.png", 60, 60 )
            end
        end

        newSoldier.image.parentObject = newSoldier

        newSoldier.currentBase = base
        newSoldier.team = base.team
        newSoldier.mode = "orbit"
        newSoldier.objectType = "soldier"

        if randomImageNumber == 0 then
            newSoldier.direction = "clockwise"
        else
            newSoldier.direction = "counterClockwise"
        end 

        newSoldier.speed = math.random( 1, 3 )
        newSoldier.orbitDistance = math.random( 80, 150 )
        newSoldier.orbitAngle = math.random( 0, ( 2 * math.pi ))
        physics.addBody( newSoldier.image, "dynamic", { radius = 15, isSensor = true })
        table.insert( soldierArray, newSoldier )
    end
end



-- Deze functie checkt elke 2 seconden of een gele base voldoende soldaten heeft om op de aanval over te gaan. 
local function considerInvading()

    for i, base in ipairs( baseArray ) do 

        if base.team == "yellow" then 

            local availableSoldiers = 0

            for j, soldier in ipairs( soldierArray ) do 

                if soldier.team == "yellow" and soldier.currentBase == base then
                    availableSoldiers = availableSoldiers + 1
                end
            end

            if availableSoldiers >= 10 then
                startInvasion( base )
            end
        end
    end
end 



-- Deze function handelt het aanvallen van andere bases vanuit een gele base af. 
function startInvasion( originBase )

    local validTarget = false
    local targetBase

-- Bepaal randomly een targetbase voor je soldier movement. Je kan niet zelf de target zijn. 
    while ( validTarget == false ) do 

        targetBase = baseArray[ math.random( 1, 6 ) ]

        if targetBase ~= originBase then
            validTarget = true
        end
    end


-- Als we eenmaal een target hebben, stuur 5 soldaten daarheen.
    local soldiersToSend = 5

    for i, soldier in ipairs( soldierArray ) do 
        if soldier.team == "yellow" and soldier.currentBase == originBase and soldiersToSend > 0 and soldier.mode == "orbit" then
            soldier.targetBase = targetBase
            soldier.mode = "travel"
            soldiersToSend = soldiersToSend - 1
        end
    end
end 



-- Function die door de gameLoop wordt aangeroepen om alle movement voor soldiers te bepalen en te berekenen.
local function soldierMovement()
    
    for i, soldier in ipairs( soldierArray ) do

        soldier.image.x = soldier.targetX
        soldier.image.y = soldier.targetY

-- Bepaal voor soldiers in orbit wat hun volgende x en y gaat zijn.
        if soldier.mode == "orbit" then

            -- Bepaalt de nieuwe hoek tov de base, adhv de richting van de soldier, de vorige hoek en de snelheid.
            if soldier.direction == "clockwise" then
                soldier.orbitAngle = soldier.orbitAngle + ( 0.02 * soldier.speed )
            elseif soldier.direction == "counterClockwise" then
                soldier.orbitAngle = soldier.orbitAngle - ( 0.02 * soldier.speed )
            end
            -- Bepaalt met sinus en cosinus de nieuwe x en y tov de base
            local x = math.cos( soldier.orbitAngle ) * soldier.orbitDistance
            local y = math.sin( soldier.orbitAngle ) * soldier.orbitDistance
            
            -- Bepaal de nieuwe x en y van de soldier adhv de x en y van zijn base, en de x en y die net berekend zijn. 
            soldier.targetX = soldier.currentBase.image.x + x
            soldier.targetY = soldier.currentBase.image.y + y           

-- Bepaal voor soldiers in travel wat hun volgende x en y gaat zijn. 
        elseif soldier.mode == "travel" then
        -- Soldiers reizen met 5 pixels x hun speed. Dit noemen we de travelDistance.
            local travelDistance = soldier.speed * 5
            
            local totalXDistance = soldier.targetBase.image.x - soldier.image.x
            local totalYDistance = soldier.targetBase.image.y - soldier.image.y
            local exactDistance = math.sqrt( ( totalXDistance * totalXDistance ) + ( totalYDistance * totalYDistance ))

            if exactDistance <= travelDistance then
                soldier.targetX = soldier.targetBase.image.x
                soldier.targetY = soldier.targetBase.image.y
            else 
                soldier.targetX = soldier.image.x + ( totalXDistance * ( travelDistance / exactDistance ) )
                soldier.targetY = soldier.image.y + ( totalYDistance * ( travelDistance / exactDistance ) )
            end

-- Soldiers die een travel-movement moeten doen vanuit de rand van een base expanden naar hun correcte orbitDistance. Die movement noemen we 'expand'
        elseif soldier.mode == "expand" then 
            
            local travelDistance = soldier.speed
        -- Bepaal het lokatiepunt waar je heen wil bewegen. 
            local Xtarget = soldier.currentBase.image.x + math.cos( soldier.orbitAngle ) * soldier.orbitDistance
            local Ytarget = soldier.currentBase.image.y + math.sin( soldier.orbitAngle ) * soldier.orbitDistance
        -- Bepaal de afstand tussen waar je nu zit en dat punt
            local totalXDistance = Xtarget - soldier.image.x 
            local totalYDistance = Ytarget - soldier.image.y
            local exactDistance = math.sqrt( ( totalXDistance * totalXDistance ) + ( totalYDistance * totalYDistance ))

        -- Je kan er alleen heen reizen met een bepaalde snelheid. Als je er al bent dan wordt je target x en y dat punt. 

            if exactDistance <= travelDistance then
                soldier.targetX = Xtarget
                soldier.targetY = Ytarget
            else 
                soldier.targetX = soldier.image.x + ( totalXDistance * ( travelDistance / exactDistance ) )
                soldier.targetY = soldier.image.y + ( totalYDistance * ( travelDistance / exactDistance ) )
            end

            if soldier.targetX == Xtarget and soldier.targetY == Ytarget then
                soldier.mode = "orbit"
            end
        end
    end
end



-- Deze functie geeft alle soldiers behorende bij een base het command om te bewegen naar het center van een targetbase. 
function travelSoldiers( targetBase )
    
    -- Haal de base op die als eerste is aangeraakt (de base waar de movement vandaan gaat komen)
    local originBase
    for i, base in ipairs( baseArray ) do 
        if base.isSelected then
            originBase = base
        end
    end

    -- Activeer de travel voor alle soldiers in de originBase, naar de coordinaten van de targetBase.
    -- Doe dit niet als originBase en targetBase dezelfde zijn. 
    
    if not ( originBase == targetBase ) then

    -- Doorloop alle soldaten op zoek naar soldaten behorende bij deze base.
        for i, soldier in ipairs( soldierArray ) do
            
            if soldier.currentBase == originBase and soldier.team == "blue" then
                soldier.targetBase = targetBase
                soldier.mode = "travel"
            end
        end
    end
end



-- Deze functie checkt elke frame of er van beide teams een soldaat aanwezig is in dezelfde base. Zoja dan worden ze tegen elkaar weggestreept.
local function soldierCombat()

-- Check de combat situatie per base apart. 
    for i, base in ipairs( baseArray ) do

        local conflictSize = 0
        local teamBlue = 0
        local teamYellow = 0

    -- Houd het aantal soldaten van beide teams op deze base bij als twee integers.
        for j, soldier in ipairs( soldierArray ) do 

            if soldier.currentBase == baseArray[i] and soldier.team == "blue" then
                teamBlue = teamBlue + 1
            elseif soldier.currentBase == baseArray[i] and soldier.team == "yellow" then
                teamYellow = teamYellow + 1
            end
        end

    -- Het aantal soldaten dat beide teams hier aanwezig hebben, is het aantal keer dat de delete functie moet draaien.
        if teamBlue <= teamYellow then
            conflictSize = teamBlue 
        else
            conflictSize = teamYellow 
        end

        
    -- De wegstreepfunctie die soldiers delete. Roept de aparte killSoldier functie aan die het daadwerkelijke verwijderen doet. 
        if conflictSize > 0 then
            for j = 1, conflictSize, 1 do

                for s, soldier in ipairs( soldierArray ) do
                    if soldier.currentBase == baseArray[i] and soldier.team == "blue" then 
                        killSoldier( soldier, s )
                        break
                    end 
                end

                for s2, soldier in ipairs( soldierArray ) do 
                    if soldier.currentBase == baseArray[i] and soldier.team == "yellow" then
                        killSoldier( soldier, s2 )
                        break
                    end
                end
            end
        end 
    end
end 



-- Deze delete functie verwijdert 1 soldier uit het hele systeem. 
function killSoldier( soldier, arrayIndex ) 
    display.remove( soldier.image )
    table.remove( soldierArray, arrayIndex ) 
end 



-- Deze function wordt elke frame aangeroepen en controleert of de base overgenomen dient te worden door een nieuwe partij. 
local function baseConversion()

    for i, base in ipairs( baseArray ) do 

    -- Tel hoeveel aanvallende soldiers er aanwezig zijn. 
        local numberOfAttackers = 0
        for j, soldier in ipairs( soldierArray ) do 

            if soldier.currentBase == baseArray[i] and ( soldier.team ~= base.team ) then 
                numberOfAttackers = numberOfAttackers + 1
            end
        end 

    -- Als er minimaal 5 aanvallende soldiers zijn, verwijder ze en neem de basis over. 
        if numberOfAttackers >= 5 then

            local conversionCost = 5
            local attackingTeam = "none" 

            for j, soldier in ipairs( soldierArray ) do 

                if conversionCost > 0 and (soldier.currentBase == baseArray[i] ) and (soldier.team ~= base.team) then
                    killSoldier( soldier, j )
                    conversionCost = conversionCost - 1
                    attackingTeam = soldier.team
                end
            end 

            convertBase( base, attackingTeam )
        end 

    end
end 


-- Deze functie gaat de base toekennen aan een ander team.
function convertBase( base, newTeam )

    local oldX = base.image.x 
    local oldY = base.image.y 
    
    if newTeam == "blue" then
        sprite = "spell_fire_minor.png"
    else 
        sprite = "spell_fire_superior.png"
    end

    base.image = display.newImageRect( baseGroup, sprite, 150, 150 )
    base.image.x = oldX
    base.image.y = oldY
    base.image.parentObject = base
    base.team = newTeam
end 


local function commandSoldiers( event )
    
    local base = event.target.parentObject
    local phase = event.phase

-- Als de touch begint op een base die van de speler is, wordt die base Selected.
    if phase == "began" then
            base.isSelected = true

-- Als de touch eindigt op een base, roep dan de travelSoldiers functie aan. 
    elseif phase == "ended" then

        display.currentStage:setFocus( base.image )
        travelSoldiers( base )
    end


-- Wanneer een movement afgekapt wordt of klaar is, moet isSelected en isFocused weer opgeruimd worden. 
    if phase == "ended" or phase == "cancelled" then

        for i, base in ipairs( baseArray ) do
            base.isSelected = false
        end

        display.currentStage:setFocus( nil )
    end

    return true 
end



local function onCollision( event )

-- Wat informatie overnemen uit de event-informatie van de handler zelf.
    local phase = event.phase

-- Als het gaat om een collision tussen een base en een soldier, kom je het volgende stuk code in:

    if ( event.object1.parentObject.objectType == "soldier" and event.object2.parentObject.objectType == "base" ) or ( event.object1.parentObject.objectType == "base" and event.object2.parentObject.objectType == "soldier" ) then

        local soldier
        local base

    -- Voor gemak willen we een soldier en base entiteit definieren. 
        if event.object1.parentObject.objectType == "soldier" and event.object2.parentObject.objectType == "base" then
            soldier = event.object1.parentObject
            base = event.object2.parentObject
        elseif event.object1.parentObject.objectType == "base" and event.object2.parentObject.objectType == "soldier" then
            soldier = event.object2.parentObject
            base = event.object1.parentObject
        end
    
    -- Wanneer soldiers hun targetBase bereiken raken ze hieromheen in orbit.
        if soldier.targetBase == base then
            soldier.currentBase = soldier.targetBase
            soldier.targetBase = nil
            soldier.orbitAngle = determineAngle( base.image, soldier.image )
            soldier.mode = "expand"
        end
    end
end



-- Deze functie bepaalt de hoek tussen twee punten. Wordt bv. gebruikt bij het bepalen van de invalshoek tussen een arriverende soldier en zijn target base. 
function determineAngle( point1, point2)
    local xDifference = point2.x - point1.x
    local yDifference = point2.y - point1.y
    return math.atan2(yDifference, xDifference)
end



-- Zes standaard bases worden aangeroepen voor de start van het spel.
-- De speler zelf speelt als blue.
createBase( "blue" )
createBase( "yellow" )
createBase( "white" )
createBase( "white" )
createBase( "white" )
createBase( "white" )


-- Een functie die elke twee seconden aangeroepen wordt om voor elke base die van een team is, een nieuwe soldier aan te maken. 
local function soldierCreationHandler()
    generateSoldiers()
end

slowGameTimer = timer.performWithDelay( 2000, soldierCreationHandler, 0 )

-- Een functie die elke seconde aangeroepen wordt om bij hard-mode iets te doen voor team oranje.
local function hardmodeCreationHandler()
    generateSoldiersHardmode()
end 

hardmodeTimer = timer.performWithDelay( 1300, hardmodeCreationHandler, 0 )

-- Deze handler en timer bepalen wanneer de vijand probeert te bewegen.
local function invasionHandler()
    considerInvading()
end 

invasionTimer = timer.performWithDelay( 4000, invasionHandler, 0 )




-- De grote gameLoop. Checkt elke frame (30 per seconden) de movement en combat functions.
local function gameLoop()
    soldierMovement()
    soldierCombat()
    baseConversion()
end


-- Start de gameloop die per frame aangeroepen wordt. 
Runtime:addEventListener( "enterFrame", gameLoop )
Runtime:addEventListener( "collision", onCollision )

-- Maak voor elke base een eventlistener aan die wacht op een touch. 
for i, base in ipairs( baseArray ) do
    base.image:addEventListener( "touch", commandSoldiers )
end

-- physics.setDrawMode( "hybrid" )



--[[--------------TODO's------------------------

    - Hoofdmenu waarop je iets kan selecteren (een scene)   (Enkele data daarheen verplaatsen en van daar doorgeven naar hoofdscene)
    - Topscoremenu met iets als 'It took you X seconds to win, and you wasted Y gems before you finally got it' 
    - Scene maken van deze gigantische brij. 
]]