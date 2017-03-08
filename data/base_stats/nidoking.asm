	db NIDOKING ; 034

	db  81, 102,  77,  85,  85,  75
	;   hp  atk  def  spd  sat  sdf

	db POISON, GROUND
	db 45 ; catch rate
	db 195 ; base exp
	db NO_ITEM ; item 1
	db NO_ITEM ; item 2
	db 0 ; gender
	db 20 ; step cycles to hatch
	dn 7, 7 ; frontpic dimensions
	db POISON_POINT ; ability 1
	db RIVALRY ; ability 2
	db SHEER_FORCE ; hidden ability
	db MEDIUM_SLOW ; growth rate
	dn MONSTER, FIELD ; egg groups

	; ev_yield
	ev_yield   0,   3,   0,   0,   0,   0
	;         hp, atk, def, spd, sat, sdf

	; tmhm
	tmhm DYNAMICPUNCH, CURSE, ROAR, TOXIC, HIDDEN_POWER, SUNNY_DAY, HONE_CLAWS, ICE_BEAM, BLIZZARD, HYPER_BEAM, PROTECT, RAIN_DANCE, IRON_TAIL, THUNDERBOLT, THUNDER, EARTHQUAKE, RETURN, DIG, SHADOW_BALL, MUD_SLAP, DOUBLE_TEAM, FLAMETHROWER, SLUDGE_BOMB, SANDSTORM, FIRE_BLAST, STONE_EDGE, AVALANCHE, REST, ATTRACT, THIEF, ROCK_SLIDE, FURY_CUTTER, ROCK_SMASH, FOCUS_BLAST, ENDURE, DRAGON_PULSE, SHADOW_CLAW, POISON_JAB, GIGA_IMPACT, CUT, SURF, STRENGTH, WHIRLPOOL, AQUA_TAIL, BODY_SLAM, COUNTER, DEFENSE_CURL, DOUBLE_EDGE, EARTH_POWER, FIRE_PUNCH, HEADBUTT, ICE_PUNCH, ICY_WIND, SEISMIC_TOSS, SLEEP_TALK, SUBSTITUTE, SUCKER_PUNCH, SWAGGER, THUNDERPUNCH, WATER_PULSE
	; end
