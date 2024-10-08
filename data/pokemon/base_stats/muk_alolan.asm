	db 115, 115,  75,  50,  65, 110 ; 530 BST
	;   hp  atk  def  spd  sat  sdf

	db POISON, DARK ; type
	db 75 ; catch rate
	db 157 ; base exp
	db BLACK_SLUDGE ; item 1
	db NUGGET ; item 2
	dn GENDER_F50, 3 ; gender ratio, step cycles to hatch
	INCBIN "gfx/pokemon/muk_alolan/front.dimensions"
	abilities_for MUK_ALOLAN, POISON_TOUCH, REGENERATOR, CORROSION
	db GROWTH_MEDIUM_FAST ; growth rate
	dn EGG_INDETERMINATE, EGG_INDETERMINATE ; egg groups

	ev_yield   1,   1,   0,   0,   0,   0
	;         hp  atk  def  spd  sat  sdf

	; tm/hm learnset
	tmhm DYNAMICPUNCH, CURSE, TOXIC, HIDDEN_POWER, SUNNY_DAY, HYPER_BEAM, PROTECT, RAIN_DANCE, GIGA_DRAIN, RETURN, DIG, SHADOW_BALL, ROCK_SMASH, DOUBLE_TEAM, FLAMETHROWER, SLUDGE_BOMB, FIRE_BLAST, SUBSTITUTE, FACADE, REST, ATTRACT, THIEF, ROCK_SLIDE, FOCUS_BLAST, DARK_PULSE, EXPLOSION, POISON_JAB, GIGA_IMPACT, STONE_EDGE, STRENGTH, BODY_SLAM, ENDURE, FIRE_PUNCH, ICE_PUNCH, KNOCK_OFF, SLEEP_TALK, SWAGGER, THUNDERPUNCH
	; end
