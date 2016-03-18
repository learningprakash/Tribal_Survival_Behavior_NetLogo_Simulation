breed [hunters hunter] ;; create necessary breeds
breed [gatherers gatherer]
breed [rabbits rabbit]
breed [hunters-2 hunter-2]
breed [gatherers-2 gatherer-2]

globals [regrow] ;; likelihood of plants regrowing

hunters-own [ energy
             patience
             has-rabbit? ] 

gatherers-own [ has-food?
                energy ]

hunters-2-own [ energy
              patience
              has-rabbit? ]

gatherers-2-own [ has-food?
                energy ]

rabbits-own [ energy ]


to setup
  clear-all
  set-default-shape hunters "person" ;; create hunters
  set-default-shape gatherers "person" ;; create gatherers
  set-default-shape rabbits "rabbit" ;; create rabbits
  set regrow 100 ;; set plant regrowth likelihood
  ask patches
  [ ifelse random-float 100 < density 
    [ set pcolor yellow ] ;; scatter food based on selected density via slider
    [ set pcolor green ] ]
  create-hunters hunter-pop [ ;; create hunters based on selected pop. via slider
    set color red
    set size 5
    set energy 50 ;; they start hungry
    setxy random-xcor random-ycor
    set patience 100
    set has-rabbit? false
  ]
  create-gatherers gather-pop [
    set color white
    set size 5
    set energy 50 ;; start hungry
    setxy random-xcor random-ycor
    set has-food? false
  ]
  create-rabbits rabbit-pop [
    set color white
    set size 3
    set energy 50
    setxy random-xcor random-ycor
  ]
  if two-tribes? [ ;; if two-tribe switch is ON, go ahead and create second tribe
    set-default-shape hunters-2 "person" ;; create hunters
    set-default-shape gatherers-2 "person" ;; create gatherers
    create-hunters-2 hunter-pop-two [
    set color blue
    set size 5
    set energy 50
    setxy random-xcor random-ycor
    set patience 100
    set has-rabbit? false
    ]
  create-gatherers-2 gather-pop-two [
    set color orange
    set size 5
    set energy 50
    setxy random-xcor random-ycor
    set has-food? false
    ]
  ]
  reset-ticks
end

to go
  ask turtles [
    if not any? turtles [ stop ] ;; check to see if there are any live turtles
    move    ;; make all turtles move
    ask gatherers with [ not has-food? ] [ find-food ] ;; tell gatherers to find food
    ask gatherers with [ has-food? ] [ find-pile ] ;; once food is found, go put it in a pile
    ask gatherers with [ not has-food? ] [
      if energy < 70 [ eat-food ] ] ;; if they are hungry and don't have food in their hands, go eat
    ask hunters with [ not has-rabbit? ] [ hunt-rabbits ] ;; tell hunters to go hunt
    ask hunters with [ has-rabbit? and energy < 70 ] [ eat-rabbit ] ;; tell hungry hunters with rabbit in hand to eat
    if count rabbits = 0 [ ;; if there are no rabbits
      ask hunters with [ energy < 70 ] [ eat-food ;; eat from the food stores and lose patience
                                       set patience patience - 5  ]
      ask hunters with [ patience = 0 and energy < 30 ] [ kill-hunter2 ;; if patience has run out, attack other tribe and add to patience
                                                        set patience 50 ] ]
    if two-tribes? [ ;; if there are two tribes, let second tribe members perform same functions as above
      ask gatherers-2 with [ not has-food? ] [ find-food ]
      ask gatherers-2 with [ has-food? ] [ find-pile ]
      ask gatherers-2 with [ not has-food? ] [
        if energy < 70 [ eat-food ] ]
      ask hunters-2 with [ not has-rabbit? ] [ hunt-rabbits ]
      ask hunters-2 with [ has-rabbit? and energy < 70 ] [ eat-rabbit ]
      if count rabbits = 0 [
      ask hunters-2 with [ energy < 70 ] [ eat-food
                                       set patience patience - 5 ] ]
      ask hunters-2 with [ patience = 0 and energy < 30 ] [ kill-hunter
                                         set patience 50 ]
    ]
    if ticks mod 100 = 0 [ set energy (energy - 10) ] ;; lose some energy every 100 ticks
    if count rabbits != 0 [
      ask one-of rabbits [ reproduce-rabbits ] ] ;; if rabbits are still alive, reproduce
    ask rabbits with [ energy < 40 ] [ rabbit-eat ] ;; if rabbits are hungry, go eat food
    ask turtles with [ energy <= 0 ] [ die ]  ;; turtles with 0 energy die
    ]
  harvest-time ;; food regrows
  if count gatherers != 0 [ ;; if gatherers are healthy enough, there is a 10% chance one of them will reproduce
  if mean [energy] of gatherers > 60 and random 100 < 10 [ ask one-of gatherers [reproduce-human] ] ]
  if count gatherers-2 != 0 [
  if mean [energy] of gatherers-2 > 60 and random 100 < 10 [ ask one-of gatherers-2 [reproduce-human-2] ] ]
  if not any? turtles [ stop ] ;; stop conditions for model
  if not any? hunters and not any? hunters-2 and not any? gatherers and not any? gatherers-2 [ stop ] ;; we want model to stop when people are dead
  tick
end


;; turtle procedure
to move 
  fd 1
  rt 20 - random 40
end


;; turtle procedure to find food
to find-food   
    ;; we pick up food only if there is not already a lot of food around it
    ;; (i.e. on at least three patches)
    if pcolor = yellow and count neighbors with [ pcolor = yellow ] < 3 [
      ;; pick up food
      set has-food? true
      ;; remove food from patch
      set pcolor green      
    ]
    
end


;; hunter/gatherer procedure to eat food
to eat-food
  if pcolor = yellow [
    ;; remove food from patch
    set pcolor green
    ;; replenish energy
    set energy ( energy + 5 ) ]
end
  
;; gatherer procedure to find pile of food
to find-pile
  ;; if patch is part of a pile
  if pcolor = yellow and [ pcolor ] of patch-ahead 1 != yellow [
    ;; set food on patch ahead of me
    ask patch-ahead 1 [ set pcolor yellow ]
    ;; I no longer have food in my hands
    set has-food? false
  ]
end

;; patch procedure to regrow food
to harvest-time
  ;; if random toss is in favor of regrowth
  if random 100 < regrow [
    ;; set a random, isolated green patch yellow (we don't want food sprouting near harvested piles)
  ask one-of patches with [ pcolor != yellow and 
    count neighbors with [ pcolor = yellow ] < 3 ] [ set pcolor yellow ] 
    ;; regrowth will be a bit slower now
    set regrow regrow - 1 ]
end

;; hunter procedure to get rabbits
to hunt-rabbits
    let prey one-of rabbits-here                    ;; grab a random rabbit
  if prey != nobody                             ;; did we get one?  if so,
    [ ask prey [ die ] 
      set has-rabbit? true] ;; get energy from eating
end

;; hunter procedure to eat rabbit
to eat-rabbit
  ;; I don't have a rabbit anymore
  set has-rabbit? false
  ;; replenish energy
  set energy energy + 10
end

;; rabbit procedure to reproduce
to reproduce-rabbits
  if random 10000 < 3 [  ;; throw "dice" to see if you will reproduce
    hatch 1 [ rt random 360 fd 1 ]   ;; hatch an offspring and move it forward 1 step
  ]
end

;; rabbit procedure to eat food
to rabbit-eat
  ;; rabbit doesn't care whether food is in pile or not, it just eats it!
  if pcolor = yellow [ set pcolor green ]
  ;; replenish energy
  set energy energy + 7
end

;; hunter procedure to attack member of other tribe
to kill-hunter
  ;; 50-50 chance of killing either a hunter or a gatherer
  ifelse random 100 > 50
  [ let prey one-of hunters-2-here
    if prey != nobody
    [ ask prey [ die ] ] ]
  [ let prey one-of gatherers-2-here
    if prey != nobody
    [ ask prey [ die ] ] ]
end

;; hunter procedure to attack member of other tribe, see above
to kill-hunter2
  ifelse random 100 > 50
  [ let prey one-of hunters-here
    if prey != nobody
    [ ask prey [ die ] ] ]
  [ let prey one-of gatherers-here
    if prey != nobody
    [ ask prey [ die ] ] ]
end

;; gatherer procedure to reproduce
to reproduce-human
  ;; 50-50 chance of making either another gatherer or a new hunter
  ifelse random 100 > 50
  [ hatch-gatherers 1 [
      ;; give each child original stats from setup above
      rt random 360 fd 1
      set color white
      set size 5
      set energy 50
      set has-food? false ] ]
   [hatch-hunters 1 [
      rt random 360 fd 1
      set color red
      set size 5
      set energy 50
      set patience 100
      set has-rabbit? false
  ] ]
end

;; gatherer procedure to reproduce, identical to above
to reproduce-human-2
  ifelse random 100 > 50
  [ hatch-gatherers-2 1 [
      rt random 360 fd 1
      set color orange
      set size 5
      set energy 50
      set has-food? false ] ]
  [ hatch-hunters-2 1 [
      rt random 360 fd 1
      set color blue
      set size 5
      set energy 50
      set patience 100
      set has-rabbit? false
  ] ]
end
@#$#@#$#@
GRAPHICS-WINDOW
675
5
1224
575
43
43
6.2
1
10
1
1
1
0
1
1
1
-43
43
-43
43
0
0
1
ticks
30.0

SLIDER
5
19
183
52
hunter-pop
hunter-pop
0
30
1
1
1
hunters
HORIZONTAL

SLIDER
5
91
177
124
density
density
0
20
20
1
1
% food
HORIZONTAL

BUTTON
129
133
195
166
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
212
133
275
166
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
6
226
206
376
Food vs Time
Time
Food
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count patches with [pcolor = yellow]"

SLIDER
5
55
193
88
gather-pop
gather-pop
0
30
3
1
1
gatherers
HORIZONTAL

SLIDER
390
19
562
52
rabbit-pop
rabbit-pop
0
40
20
20
1
rabbits
HORIZONTAL

MONITOR
199
173
283
218
NIL
count rabbits
17
1
11

SWITCH
182
91
309
124
two-tribes?
two-tribes?
1
1
-1000

SLIDER
196
55
413
88
gather-pop-two
gather-pop-two
0
30
1
1
1
gatherers
HORIZONTAL

SLIDER
181
19
387
52
hunter-pop-two
hunter-pop-two
0
30
0
1
1
hunters
HORIZONTAL

MONITOR
6
173
90
218
NIL
count hunters
17
1
11

MONITOR
97
173
193
218
NIL
count gatherers
17
1
11

MONITOR
288
173
404
218
NIL
count hunters-2
17
1
11

MONITOR
407
173
534
218
NIL
count gatherers-2
17
1
11

PLOT
15
393
447
543
Population vs Time
Time
Population
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Hunters Tribe 1" 1.0 0 -2674135 true "" "plot count hunters"
"Hunters Tribe 2" 1.0 0 -14439633 true "" "plot count hunters-2"
"Gatherers Tribe 1" 1.0 0 -13345367 true "" "plot count gatherers"
"Gatherers Tribe 2" 1.0 0 -8630108 true "" "plot count gatherers-2"

@#$#@#$#@
## WHAT IS IT

This model attempts to replicate hunter-gatherer tribal dynamics of the Paleolithic era.  One or two tribes compete for resources--rabbits (for hunters) and edible plants (for gatherers)--and when those resources die out, so do the tribe(s).  Rabbits are also in competition with the tribes to consume the edible plants.  The tribes reproduce, but only if their energy is sufficient.  If they are 'starving', they will not reproduce, in an effort to stay as close to reality as possible.

## HOW IT WORKS

Initialize:
Create # of hunters, gatherers, rabbits and scatter.
Create chosen density of grain to gather and scatter those patches.

At each tick, each gatherer:
I look for a yellow grain patch.
When I find a yellow grain patch, I pick it up.
If I have a grain patch, I take it to another grain pile.
If I find a grain pile, I put the grain there.
If I have deposited grain and my energy is less than 70, I can eat a different patch of grain and restore my energy.
If my energy is greater than 60, I can reproduce; there is a 50% chance either way of the new tribe member being a hunter or a gatherer.
If there is no grain left on the ground, I continue to search for grain until my energy runs out.
When my energy drops to 0, I die.

At each tick, each hunter:
I look for a rabbit.
When I find a rabbit, I kill it and put it in my 'pouch' for later.
When I have a rabbit in my 'pouch' and my energy is less than 70, I eat the rabbit and restore my energy.
When there are no more rabbits and my energy is less than 70, I eat from the stores of grain and lose some patience.
When there are no more rabbits and my patience is 0, I attack a member of the other tribe.
When my energy drops to 0, I die.

At each tick, each rabbit:
I look for a yellow grain patch.
When I find a yellow grain patch and my energy is below 40, I eat it and restore my energy.
If a hunter finds me, I die.
If my energy drops to 0, I die.
Each tick there is a chance I reproduce.

## HOW TO USE IT

There are six sliders: two to control hunter populations for each tribe, two to control gatherer populations for each tribe, one to control rabbit population for each tribe and one to control the density of food growth.  The switch toggles the tribe count, in case modeling a single tribe is preferred.  

Set the sliders and switch to your desired settings.  Watch the plots and monitors to see how the population fluctuates.

## THINGS TO TRY

Play with the sliders as much or as little as you'd like.  See how long a small tribe can last on its own, or how two large tribes manage competing for food.

If you have the time (over 48 consecutive hours at least) to run a Behavior Space experiment for larger parameters, by all means do so--it may reveal more than this limited experiment.

## EXTENDING THE MODEL

Adding a predator that preys upon the humanoids would be an excellent and realistic extension to this model.  Weather phenomena may also be an interesting extension.  Dangerous prey--that is, the chance for a hunter to die in pursuit of food--would be fascinating to see in action.  Adding additional tribes would make for intense but perhaps rewarding study.

## NETLOGO FEATURES

This model makes use of the sliders and switch widgets, as well as monitors and plots to keep tabs on activity trends.

## RELATED MODELS

Wolf Sheep Predation (predator/prey dynamic)
Rabbits Grass Weeds (animal/plant dynamic)
Termites (gathering/organizing)

## CREDITS AND REFERENCES

NetLogo Models Library, esp. Wolf Sheep Predation and Termites
Arthur Hjorth for his help in building the basic gatherer version of this model
Prof. Uri Wilensky for his lectures and guidance
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

rabbit
false
0
Polygon -7500403 true true 61 150 76 180 91 195 103 214 91 240 76 255 61 270 76 270 106 255 132 209 151 210 181 210 211 240 196 255 181 255 166 247 151 255 166 270 211 270 241 255 240 210 270 225 285 165 256 135 226 105 166 90 91 105
Polygon -7500403 true true 75 164 94 104 70 82 45 89 19 104 4 149 19 164 37 162 59 153
Polygon -7500403 true true 64 98 96 87 138 26 130 15 97 36 54 86
Polygon -7500403 true true 49 89 57 47 78 4 89 20 70 88
Circle -16777216 true false 37 103 16
Line -16777216 false 44 150 104 150
Line -16777216 false 39 158 84 175
Line -16777216 false 29 159 57 195
Polygon -5825686 true false 0 150 15 165 15 150
Polygon -5825686 true false 76 90 97 47 130 32
Line -16777216 false 180 210 165 180
Line -16777216 false 165 180 180 165
Line -16777216 false 180 165 225 165
Line -16777216 false 180 210 210 240

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>not any? patches with [pcolor = yellow]</exitCondition>
    <metric>count patches with [pcolor = yellow]</metric>
    <steppedValueSet variable="density" first="1" step="1" last="100"/>
  </experiment>
  <experiment name="experiment2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count hunters</metric>
    <metric>count gatherers</metric>
    <metric>count rabbits</metric>
    <enumeratedValueSet variable="hunter-pop">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rabbit-pop">
      <value value="20"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gather-pop">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="density">
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
