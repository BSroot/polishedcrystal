_BillsPC:
	call .CheckCanUsePC
	ret c
	ld hl, wOptions1
	ld a, [hl]
	push af
	set NO_TEXT_SCROLL, [hl]
	ld a, 71
	ldh [rLYC], a
	call LoadStandardMenuDataHeader
	call UseBillsPC
	call ReturnToMapFromSubmenu

	ld hl, rIE
	res LCD_STAT, [hl]
	xor a
	ldh [hMPState], a

	pop af
	ld [wOptions1], a
	jp CloseSubmenu

.CheckCanUsePC:
	ld a, [wPartyCount]
	and a
	ret nz
	ld hl, .Text_GottaHavePokemon
	call MenuTextBoxBackup
	scf
	ret

.Text_GottaHavePokemon:
	; You gotta have #MON to call!
	text_jump UnknownText_0x1c1006
	text_end

BillsPC_LoadUI:
	; Cursor tile
	ld de, BillsPC_CursorTiles
	ld hl, vTiles0
	lb bc, BANK(BillsPC_CursorTiles), 4
	call Get2bpp

	; Cursor sprite OAM
	lb de, 48, 24
	ld a, SPRITE_ANIM_INDEX_PC_CURSOR
	call _InitSpriteAnimStruct

	; Colored gender symbols are housed in misc battle gfx stuff
	ld hl, BattleExtrasGFX
	ld de, vTiles2 tile $40
	lb bc, BANK(BattleExtrasGFX), 4
	call DecompressRequest2bpp

	; Box frame tiles
	ld de, BillsPC_Tiles
	ld hl, vTiles2 tile $31
	lb bc, BANK(BillsPC_Tiles), 15
	call Get2bpp

	; Held item icon
	ld hl, vTiles0 tile 4
	ld de, HeldItemIcons
	lb bc, BANK(HeldItemIcons), 2
	call Get2bpp

	; Set up background + outline palettes
	ld a, CGB_BILLS_PC
	jp GetCGBLayout

UseBillsPC:
	call ClearTileMap
	call ClearPalettes
	farcall WipeAttrMap
	call ClearSprites
	ld a, [wVramState]
	res 0, a
	ld [wVramState], a
	call BillsPC_LoadUI

	; Default cursor data (top left of storage, not holding anything)
	ld a, $12
	ld [wBillsPC_CursorPos], a
	xor a
	ld [wBillsPC_CursorHeldSlot], a

	; Reserve 4 blank tiles for empty slots
	ld a, 1
	ldh [rVBK], a
	ld hl, vTiles3
	ld de, vTiles5 tile $7f
	push hl
	push hl
	ld c, 1
	call Get2bpp
	pop de
	pop hl
	ld bc, 1 tiles
	add hl, bc
	push hl
	push de
	ld c, 1
	call Get2bpp
	pop de
	pop hl
	ld bc, 1 tiles
	add hl, bc
	ld c, 2
	call Get2bpp
	xor a
	ld [rVBK], a

	; Pokepic attributes
	hlcoord 0, 0, wAttrMap
	lb bc, 7, 7
	ld a, 2
	call FillBoxWithByte

	; Item name is in vbk1
	hlcoord 10, 3, wAttrMap
	ld bc, 10
	ld a, TILE_BANK
	rst ByteFill

	; Storage box
	hlcoord 7, 4
	lb bc, 12, 11
	ld de, .BoxTiles
	call .Box

	; Seperator between box name and content
	hlcoord 7, 6
	lb bc, $3e, 11
	call .SpecialRow

	; set up box title to use vbk0 (previously set to vbk1 by .Box)
	hlcoord 8, 5, wAttrMap
	ld bc, 11
	ld a, 7
	rst ByteFill

	; initialize icon graphics + palettes (tilemaps are set up later)
	ld a, 1
	ldh [rVBK], a
	call SetPartyIcons
	call SetBoxIconsAndName
	xor a
	ldh [rVBK], a

	; Party box
	hlcoord 0, 9
	lb bc, 7, 5
	ld de, .PartyTiles
	call .Box

	; Party label borders
	hlcoord 0, 10
	lb bc, $36, 5
	call .SpecialRow

	; Party label text
	hlcoord 2, 9
	ld a, $38
	ld [hli], a
	inc a
	ld [hli], a
	inc a
	ld [hli], a
	inc a
	hlcoord 2, 10
	ld [hli], a
	inc a
	ld [hli], a
	inc a
	ld [hli], a

	; Write icon tilemaps
	; Party
	hlcoord 1, 11
	lb bc, 3, 2
	lb de, $80, 2 | TILE_BANK
	call .WriteIconTilemap

	; Storage
	hlcoord 8, 7
	lb bc, 5, 4
	lb de, $98, 4 | TILE_BANK
	call .WriteIconTilemap

	; Update attribute map data
	ld b, 2
	call SafeCopyTilemapAtOnce

	; Set up for HBlank palette switching
	ld hl, rIE
	set LCD_STAT, [hl]
	ld a, -1
	ldh [hMPState], a

	; Display data about current Pokémon pointed to by cursor
	call GetCursorMon

	; Begin storage system interaction
	call ManageBoxes

	; Finished with storage system. Cleanup
	call ClearTileMap
	jp ClearPalettes

.Box:
; Draws a box with tiles and attributes
	push bc
	push hl
	call CreateBoxBorders
	pop hl
	ld bc, wAttrMap - wTileMap
	add hl, bc
	pop bc
	ld de, .BoxAttr
	jp CreateBoxBorders

.BoxTiles:
	db $33, $32, $33 ; top
	db $31, $7f, $31 ; middle
	db $33, $32, $33 ; bottom
.PartyTiles:
	db $35, $34, $35 ; top
	db $31, $7f, $31 ; middle
	db $33, $32, $33 ; bottom
.BoxAttr:
	db 1, 1, 1 | X_FLIP ; top
	db 1, 2 | TILE_BANK, 1 | X_FLIP ; middle
	db 1 | Y_FLIP, 1 | Y_FLIP, 1 | X_FLIP | Y_FLIP ; bottom

.SpecialRow:
; Draws a nonstandard box outline
	ld a, b
	ld [hli], a
	inc a
	ld b, 0
	push bc
	push hl
	rst ByteFill
	dec a
	ld [hl], a
	pop hl
	ld bc, wAttrMap - wTileMap
	add hl, bc
	pop bc
	ld a, 1
	rst ByteFill
	ret

.WriteIconTilemap:
; Writes icon tile+attr data for b rows, c cols starting from hlcoord, tile a
	ld a, d
.tile_row
	push bc
	push de
	push hl
.tile_col
	call .icon
	dec c
	jr nz, .tile_col
	pop hl
	ld bc, SCREEN_WIDTH * 2
	add hl, bc
	pop de
	pop bc
	dec b
	jr nz, .tile_row
	ret

.icon
	push bc
	ld [hli], a
	inc a
	ld [hld], a
	inc a
	ld bc, SCREEN_WIDTH
	add hl, bc
	ld [hli], a
	inc a
	ld [hld], a
	inc a
	ld bc, -SCREEN_WIDTH + (wAttrMap - wTileMap)
	add hl, bc
	ld [hl], e
	inc hl
	ld [hl], e
	ld bc, SCREEN_WIDTH - 1
	add hl, bc
	ld [hl], e
	inc hl
	ld [hl], e
	inc e
	ld bc, -SCREEN_WIDTH + 2 + (wTileMap - wAttrMap)
	add hl, bc
	pop bc
	ret

BillsPC_CursorTiles:
	dw `33330000
	dw `22230000
	dw `22230000
	dw `22300000
	dw `22300000
	dw `23000000
	dw `23000000
	dw `30000000

	dw `00003333
	dw `00003111
	dw `00003111
	dw `00000311
	dw `00000311
	dw `00000031
	dw `00000031
	dw `00000003

	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00033333
	dw `00030000

	dw `00030000
	dw `00030000
	dw `00003000
	dw `00003000
	dw `00000300
	dw `00000300
	dw `00000030
	dw `00000003

BillsPC_Tiles
	dw `01223333
	dw `01223333
	dw `01223333
	dw `01223333
	dw `01223333
	dw `01223333
	dw `01223333
	dw `01223333

	dw `00000000
	dw `11111111
	dw `22222222
	dw `22222222
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333

	dw `00000000
	dw `00011111
	dw `00122222
	dw `01222222
	dw `01222333
	dw `01223333
	dw `01223333
	dw `01223333

	dw `00000000
	dw `11111111
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222

	dw `00000000
	dw `00011111
	dw `00122222
	dw `01222222
	dw `01222222
	dw `01222222
	dw `01222222
	dw `01222222

	dw `01222222
	dw `01222222
	dw `01222222
	dw `01222222
	dw `01222333
	dw `01223333
	dw `01223333
	dw `01223333

	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333

	dw `00000000
	dw `11111111
	dw `22222222
	dw `22222222
	dw `23332222
	dw `23223222
	dw `23223223
	dw `23332232

	dw `00000000
	dw `11111111
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `33232323
	dw `23233222

	dw `00000000
	dw `11111111
	dw `22222222
	dw `22222222
	dw `22222222
	dw `32222222
	dw `33232232
	dw `32232232

	dw `23222232
	dw `23222223
	dw `22222222
	dw `22222222
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333

	dw `33232222
	dw `23232222
	dw `22222222
	dw `22222222
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333

	dw `32223332
	dw `33222232
	dw `22233322
	dw `22222222
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333

	dw `01223333
	dw `01222333
	dw `01222222
	dw `01222222
	dw `01111111
	dw `01222222
	dw `01222222
	dw `01222333

	dw `33333333
	dw `33333333
	dw `22222222
	dw `22222222
	dw `11111111
	dw `22222222
	dw `22222222
	dw `33333333

BillsPC_BlankTiles:
; Used as input to blank empty slots
	ld de, vTiles3 tile $00
	ld bc, 4 tiles
.loop
	push hl
	push de
	push bc
	push af
	ld c, 4
	call BillsPC_SafeGet2bpp
	pop af
	pop bc
	pop de
	pop hl
	add hl, bc
	dec a
	jr nz, .loop
	ret

BillsPC_SafeRequest2bppInWRA6::
	ldh a, [hROMBank]
	ld b, a
	call RunFunctionInWRA6

BillsPC_SafeGet2bpp:
; Only copies graphics when doing so wont interfere with hblank palette usage.
; Otherwise, wait until next frame.
	ldh a, [rLY]
	cp $40
	jp c, Get2bpp
	call DelayFrame
	jr BillsPC_SafeGet2bpp

SetBoxName:
; Writes name of current Box to box name area in storage system
	hlcoord 9, 5
	ld a, " "
	ld bc, 9
	rst ByteFill

	; Write new box name
	ld a, [wCurBox]
	ld hl, wBoxNames
	ld bc, BOX_NAME_LENGTH
	rst AddNTimes
	ld d, h
	ld e, l

	; Center the name (b is 0 from earlier)
.loop
	ld a, [hli]
	inc b
	cp "@"
	jr nz, .loop
	inc b
	srl b
	ld a, 5
	sub b
	ld c, a
	ld b, 0
	hlcoord 9, 5
	add hl, bc
	jp PlaceString

SetPartyIcons:
; Writes party list
	; Blank current list
	xor a
	ld hl, wBillsPC_PartyList
	ld bc, PARTY_LENGTH * 2
	rst ByteFill

	ld hl, vTiles4 tile $00
	ld a, PARTY_LENGTH
	call BillsPC_BlankTiles

	; Write party members
	lb bc, 0, 1
	ld hl, wBillsPC_PartyList
	lb de, PARTY_LENGTH, $80
	jr PCIconLoop

SetBoxIconsAndName:
	; Blank previous box name
	call SetBoxName
	; fallthrough
SetBoxIcons:
	; Blank current list
	xor a
	ld hl, wBillsPC_BoxList
	ld bc, MONS_PER_BOX * 2
	rst ByteFill

	ld hl, vTiles4 tile $18
	ld a, MONS_PER_BOX
	call BillsPC_BlankTiles

	; Write box members
	ld a, [wCurBox]
	inc a
	ld b, a
	ld c, 1
	ld hl, wBillsPC_BoxList
	lb de, MONS_PER_BOX, $98
	; fallthrough
PCIconLoop:
	call GetStorageBoxMon
	jr z, .next
	ld a, [wBufferMon]
	ld [wCurIcon], a
	ld [hli], a
	ld a, [wBufferMonForm]
	ld [wCurIconForm], a
	ld a, e
	push hl
	push de
	push bc
	farcall GetStorageIcon_a
	pop bc
	pop de
	pop hl
	call WriteIconPaletteData
.next
	ld a, e
	add 4
	ld e, a
	inc c
	dec d
	jr nz, PCIconLoop
	ret

WriteIconPaletteData:
; Write box slot c's palette data. If b is zero, write party palette instead.
; (This is the same input as various "box mon data" functions).
	push hl
	push de
	push bc
	ld a, [wBufferMonSpecies]
	ld hl, wBufferMonPersonality
	farcall _GetMonIconPalette
	pop bc
	push bc
	push af
	ld a, c
	dec a
	inc b
	dec b
	ld bc, wBillsPC_MonPals2 - wBillsPC_MonPals1
	ld d, 2
	ld hl, wBillsPC_PartyPals3
	jr z, .loop
	ld d, 4
	ld hl, wBillsPC_MonPals1
.loop
	sub d
	jr c, .found_row
	add hl, bc
	jr .loop
.found_row
	add d
	add a
	add a
	ld c, a
	add hl, bc

	; TODO: per-mon palettes
	ld [hl], $7f
	inc hl
	ld [hl], $2a
	inc hl
	pop af
	and a ; PAL_OW_RED
	ld de, $04ff
	jr z, .got_pal
	dec a ; PAL_OW_BLUE
	ld de, $7d2a
	jr z, .got_pal
	dec a ; PAL_OW_GREEN
	ld de, $0ee7
	jr z, .got_pal
	dec a ; PAL_OW_BROWN
	ld de, $0d4f
	jr z, .got_pal
	dec a ; PAL_OW_PURPLE
	ld de, $4892
	jr z, .got_pal
	dec a ; PAL_OW_GRAY
	ld de, $35ad
	jr z, .got_pal
	dec a ; PAL_OW_PINK
	ld de, $2d5f
	jr z, .got_pal
	ld de, $56e3 ; PAL_OW_TEAL
.got_pal
	ld [hl], e
	inc hl
	ld [hl], d
	jp PopBCDEHL

BillsPC_HideCursor:
	ld hl, wVirtualOAM
	ld bc, 24
	xor a
	rst ByteFill
	ret

BillsPC_UpdateCursorLocation:
	push hl
	push de
	push bc
	ld hl, wVirtualOAM + 24
	ld de, wStringBuffer1
	ld bc, 4
	rst CopyBytes
	farcall PlaySpriteAnimations
	ld hl, wStringBuffer1
	ld de, wVirtualOAM + 24
	ld bc, 4
	rst CopyBytes
	jp PopBCDEHL

GetCursorMon:
; Prints data about Pokémon at cursor if nothing is held (underline to force)
	; Don't do anything if we're already holding a mon
	ld a, [wBillsPC_CursorHeldSlot]
	and a
	jr nz, BillsPC_UpdateCursorLocation
	; fallthrough
_GetCursorMon:
	call BillsPC_UpdateCursorLocation

	; Check if cursor is currently hovering over a mon.
	ld a, [wBillsPC_CursorPos]
	sub $10
	jr c, .clear

	ld b, a
	and $f
	; column 0-1 is party
	cp 2
	jr c, .party

	; Otherwise we're checking storage
	; With existing $yx row 0-4 col 2-5, we want to get y*4+x-1.
	ld c, a
	ld a, b
	swap a
	and $f
	add a
	add a
	add c
	dec a
	ld c, a
	ld a, [wCurBox]
	inc a
	ld b, a
	jr .got_storage_location
.party
	; With existing $yx row 2-4 col 0-1, we want to get y*2+x-3.
	ld c, a
	ld a, b
	swap a
	and $f
	add a
	add c
	sub 3
	ld c, a
	ld b, 0
.got_storage_location
	call GetStorageBoxMon
	jr nz, .not_clear
	ld a, -1
	ld [wVirtualOAM + 24], a

.clear
	; Clear existing data
	hlcoord 7, 0
	lb bc, 4, 13
	call ClearBox
	hlcoord 0, 0
	lb bc, 9, 7
	call ClearBox
	ld a, [wBillsPC_CursorPos]
	cp $10
	jr c, .box_cursors

	ld a, " "
	hlcoord 8, 5
	ld [hl], a
	hlcoord 18, 5
	ld [hl], a
	ret

.box_cursors
	hlcoord 8, 5
	ld [hl], "◀"
	hlcoord 18, 5
	ld [hl], "▶"
	ld a, -1
	ld [wVirtualOAM + 24], a
	ret

.not_clear
	; Prepare frontpic. Split into decompression + loading to make sure we
	; refresh the pokepic and the palette in a single frame (decompression
	; is unpredictable, but bpp copy can be relied upon).
	ld a, [wBufferMonSpecies]
	ld hl, wBufferMonForm
	ld de, vTiles2
	push de
	push af
	predef GetVariant
	ld a, [wBufferMonIsEgg]
	ld d, a
	pop af
	bit MON_IS_EGG_F, d
	jr z, .not_egg
	ld a, EGG
.not_egg
	ld [wCurPartySpecies], a
	ld [wCurSpecies], a
	call GetBaseData
	pop de
	farcall PrepareFrontpic

	push hl
	ld a, "@"
	ld [wStringBuffer2], a
	ld a, [wBufferMonItem]
	and a
	jr z, .no_item
	ld [wNamedObjectIndexBuffer], a
	call GetItemName
	ld hl, wStringBuffer1
	ld de, wStringBuffer2
	ld bc, ITEM_NAME_LENGTH
	rst CopyBytes

.no_item
	; Delay first before finishing frontpic
	call DelayFrame
	ld a, [wAttrMap]
	and TILE_BANK
	pop hl
	push af
	ld a, 0
	jr nz, .dont_switch_vbk
	ld a, 1
	ld [rVBK], a
.dont_switch_vbk
	farcall GetPreparedFrontpic
	xor a
	ld [rVBK], a
	ld hl, wBillsPC_ItemVWF
	ld bc, 10 tiles
	xor a
	push hl
	rst ByteFill
	pop hl
	ld de, wStringBuffer1
	ld a, [wBufferMonItem]
	and a
	call nz, PlaceVWFString
	call DelayFrame

	ld a, 1
	ld [rVBK], a
	ld hl, vTiles2 tile $31
	ld de, wBillsPC_ItemVWF
	ld c, 10
	call Get2bpp
	xor a
	ld [rVBK], a

	pop af
	ld a, 2
	jr nz, .got_new_tile_bank
	ld a, 2 | TILE_BANK
.got_new_tile_bank
	hlcoord 0, 0, wAttrMap
	lb bc, 7, 7
	call FillBoxWithByte

	; Colors
	ld bc, wBufferMonPersonality
	ld a, [wBufferMonSpecies]
	farcall GetMonNormalOrShinyPalettePointer
	ld de, wBillsPC_PokepicPal
	ld b, 4
.loop
	ld a, BANK(PokemonPalettes)
	call GetFarByte
	inc hl
	ld [de], a
	inc de
	dec b
	jr nz, .loop

	; Show or hide item icon
	ld hl, wVirtualOAM + 24
	ld a, [wBufferMonItem]
	and a
	ld [hl], -1
	jr z, .item_icon_done

	ld [hl], 40
	inc hl
	ld [hl], 72
	inc hl
	inc hl
	ld [hl], 0
	dec hl
	ld [hl], 4
	call ItemIsMail
	jr c, .item_icon_done
	inc [hl]
.item_icon_done

	ld b, 0
	call SafeCopyTilemapAtOnce

	; Clear text
	call .clear

	; Poképic tilemap
	hlcoord 0, 0
	farcall PlaceFrontpicAtHL

	; Nickname
	hlcoord 8, 0
	ld de, wBufferMonNick
	call PlaceString

	; If we're dealing with an egg, we're done now.
	ld a, [wBufferMonIsEgg]
	bit MON_IS_EGG_F, a
	ret nz

	; Species name
	ld a, [wBufferMonSpecies]
	ld [wNamedObjectIndexBuffer], a
	hlcoord 8, 1
	ld a, "/"
	ld [hli], a
	call GetPokemonName
	ld de, wStringBuffer1
	call PlaceString

	; Several functions rely on having the mon in wTempMon
	ld hl, wBufferMon
	ld de, wTempMon
	ld bc, PARTYMON_STRUCT_LENGTH
	rst CopyBytes

	; Level
	hlcoord 0, 8
	call PrintLevel

	; Gender
	ld a, TEMPMON
	ld [wMonType], a
	farcall GetGender
	jr c, .genderless
	hlcoord 4, 8
	ld a, $41
	jr nz, .male
	; female
	inc a
.male
	ld [hl], a
.genderless

	; Item
	hlcoord 10, 3
	ld a, $31
	ld b, 10
.item_loop
	ld [hli], a
	inc a
	dec b
	jr nz, .item_loop
	ret

ManageBoxes:
; Main box management function
.loop
	call BillsPC_UpdateCursorLocation
	call DelayFrame
	call JoyTextDelay
.redo_input
	ldh a, [hJoyPressed]
	ld hl, wInputFlags
	rrca
	jp c, .pressed_a
	rrca
	jp c, .pressed_b
	rrca
	jp c, .pressed_select
	rrca
	jp c, .pressed_start
	rrca
	jp c, .pressed_right
	rrca
	jp c, .pressed_left
	rrca
	jp c, .pressed_up
	rrca
	jp c, .pressed_down
	jr .loop
.pressed_a
	; check if we're on top row (hovering over box name)
	ld a, [wBillsPC_CursorPos]
	cp $10
	ld hl, .BoxMenu
	jr c, .got_menu

	; check if we're in party or storage
	and $f
	cp $2
	ld hl, .PartyMonMenu
	jr c, .got_menu

	; hide the cursor
	call BillsPC_HideCursor
	ld hl, .StorageMonMenu
.got_menu
	call LoadMenuDataHeader
	xor a
	ld [wWhichIndexSet], a
	call DoNthMenu
	push af
	call BillsPC_UpdateCursorLocation
	call CloseWindow
	pop af
	jr c, .loop
	ld a, [wMenuSelection]
	ld hl, .Jumptable
	call JumpTable
	jr .loop

.pressed_b
	; Prompt if we want to exit Box operations or not.
	call BillsPC_HideCursor
	ld hl, .ContinueBoxUse
	call MenuTextBox
	call YesNoBox
	push af
	call BillsPC_UpdateCursorLocation
	call CloseWindow
	pop af
	ret c
	jr .loop

.pressed_select
	; TODO: Cursor Mode Switch
.pressed_start
	; Immediately leave the storage system (TODO: Maybe allow searching?)
	ret

.pressed_right
	ld a, [wBillsPC_CursorPos]
	cp $10
	jr nc, .regular_right
	ld a, [wCurBox]
	inc a
	jr .new_box

.regular_right
	; Move right
	ld b, a
	and $f
	cp 5
	jr nz, .inc_x
	ld a, b
	sub 6
	ld b, a
.inc_x
	inc b
	ld a, b
	jr .new_cursor_pos

.pressed_left
	ld a, [wBillsPC_CursorPos]
	cp $10
	jr nc, .regular_left
	ld a, [wCurBox]
	add 13
	; fallthrough
.new_box
	cp NUM_BOXES
	jr c, .valid_box
	sub NUM_BOXES
.valid_box
	ld [wCurBox], a
	call SetBoxName
	call Delay2
	ldh a, [hBGMapMode]
	push af
	xor a
	ldh [hBGMapMode], a
	ld a, 1
	ldh [rVBK], a
	call SetBoxIcons
	xor a
	ldh [rVBK], a
	pop af
	ldh [hBGMapMode], a
	jp .loop

.regular_left
	; Move left
	ld b, a
	and $f
	jr nz, .dec_x
	ld a, b
	add 6
	ld b, a
.dec_x
	dec b
	ld a, b
	jr .new_cursor_pos

.pressed_up
	ld a, [wBillsPC_CursorPos]
	sub $10
	jr .new_cursor_pos
.pressed_down
	ld a, [wBillsPC_CursorPos]
	add $10
	; fallthrough
.new_cursor_pos
	ld [wBillsPC_CursorPos], a
	call BillsPC_CursorPosValid
	jp nz, .redo_input
	call GetCursorMon
	jp .loop

.ContinueBoxUse:
	text "Continue Box"
	line "operations?"
	done

.StorageMonMenu:
	db $40 ; flags
	db 02, 09 ; start coords
	db 17, 19 ; end coords
	dw .StorageMenuData2
	db 1 ; default option

.StorageMenuData2:
	db $20 ; flags
	db 0 ; items
	dw .storageitems
	dw PlaceMenuStrings
	dw .strings

.PartyMonMenu:
	db $40 ; flags
	db 02, 10 ; start coords
	db 17, 19 ; end coords
	dw .PartyMenuData2
	db 1 ; default option

.PartyMenuData2:
	db $20 ; flags
	db 0 ; items
	dw .partyitems
	dw PlaceMenuStrings
	dw .strings

.BoxMenu:
	db $40 ; flags
	db 10, 07 ; start coords
	db 17, 19 ; end coords
	dw .BoxMenuData2
	db 1 ; default option

.BoxMenuData2:
	db $20 ; flags
	db 0 ; items
	dw .boxitems
	dw PlaceMenuStrings
	dw .strings

.strings
	; pokémon management options
	db "Withdraw@"
	db "Deposit@"
	db "Stats@"
	db "Switch@"
	db "Moves@"
	db "Item@"
	db "Release@"
	; box options
	db "Switch box@"
	db "Rename@"
	db "Cancel@"

.Jumptable
	dw BillsPC_Withdraw
	dw BillsPC_Deposit
	dw BillsPC_Stats
	dw BillsPC_Switch
	dw BillsPC_Moves
	dw BillsPC_Item
	dw BillsPC_Release
	dw BillsPC_SwitchBox
	dw BillsPC_Rename
	dw DoNothing

.storageitems
	db 7
	db 0 ; withdraw
	db 2 ; stats
	db 3 ; switch
	db 4 ; moves
	db 5 ; item
	db 6 ; release
	db 9 ; cancel
	db -1

.partyitems
	db 7
	db 1 ; deposit
	db 2 ; stats
	db 3 ; switch
	db 4 ; moves
	db 5 ; item
	db 6 ; release
	db 9 ; cancel
	db -1

.boxitems
	db 3
	db 7 ; switch box
	db 8 ; rename
	db 9 ; cancel
	db -1

BillsPC_Withdraw:
BillsPC_Deposit:
	ret

BillsPC_Stats:
	ld hl, rIE
	res LCD_STAT, [hl]
	farcall OpenPartyStats
	call BillsPC_RestoreUI
	ret

BillsPC_Switch:
BillsPC_Moves:
	ret

BillsPC_Item:
	call BillsPC_HideCursor
	ld a, [wBufferMonItem]
	and a
	ld hl, .ItemIsSelected
	ld de, .ItemMenu
	jr nz, .got_menu
	ld hl, .ItCanHoldAnItem
	ld de, .NoItemMenu
.got_menu
	push de
	call MenuTextBox
	pop hl
	call LoadMenuDataHeader
	xor a
	ld [wWhichIndexSet], a
	call DoNthMenu
	call CloseWindow
	call CloseWindow
	jp BillsPC_UpdateCursorLocation

.ItemIsSelected:
	text_from_ram wStringBuffer2
	text " is"
	line "selected."
	done

.ItCanHoldAnItem:
	text_from_ram wStringBuffer1
	text " can"
	line "hold an item."
	done

.ItemMenu:
	db $40 ; flags
	db 05, 11 ; start coords
	db 12, 19 ; end coords
	dw .ItemMenuData
	db 1 ; default option

.ItemMenuData:
	db $20 ; flags
	db 3 ; items
	dw .items
	dw PlaceMenuStrings
	dw .strings

.NoItemMenu:
	db $40 ; flags
	db 07, 11 ; start coords
	db 12, 19 ; end coords
	dw .NoItemMenuData
	db 1 ; default option

.NoItemMenuData:
	db $20 ; flags
	db 2 ; items
	dw .noitems
	dw PlaceMenuStrings
	dw .strings

.strings
	; holds and item
	db "Move@"
	db "Bag@"
	; doesn't hold an item
	db "Give@"
	db "Cancel@"

.items
	db 3
	db 0 ; move
	db 1 ; bag
	db 3 ; cancel
	db -1

.noitems
	db 2
	db 2 ; give
	db 3 ; cancel
	db -1

BillsPC_Release:
BillsPC_SwitchBox:
BillsPC_Rename:
	ret

BillsPC_RestoreUI:
	ld hl, rIE
	set LCD_STAT, [hl]
	call ClearPalettes

	call BillsPC_LoadUI

	ld a, CGB_BILLS_PC
	call GetCGBLayout
	call SetPalettes
	jp GetCursorMon

BillsPC_CursorPosValid:
; Returns z if the cursor position is valid
	; Check for columns beyond 5
	ld b, a
	and $f
	cp 6
	jr nc, .invalid

	; Check for party rows less than 3
	cp 2
	jr nc, .not_party
	ld a, b
	cp $30
	jr c, .invalid

.not_party
	; Check for rows beyond 5
	ld a, b
	cp $60
	jr c, .valid
.invalid
	or 1
	ld a, b
	ret
.valid
	xor a
	ld a, b
	ret

CopyBoxmonToTempMon:
	ld a, [wCurPartyMon]
	ld hl, sBoxMon1Species
	ld bc, BOXMON_STRUCT_LENGTH
	rst AddNTimes
	ld de, wTempMonSpecies
	ld bc, BOXMON_STRUCT_LENGTH
	ld a, BANK(sBoxMon1Species)
	call GetSRAMBank
	rst CopyBytes
	jp CloseSRAM

InitializeBoxes:
; Initializes the Storage System boxes as empty with default names.
	ld a, BANK(sNewBox1)
	call GetSRAMBank
	ld b, NUM_NEWBOXES
	ld hl, sNewBox1
.loop
	push bc
	ld bc, sNewBox1Name - sNewBox1
	xor a
	rst ByteFill
	push hl
	ld de, .Box
	call CopyName2
	dec hl
	ld a, b
	sub 10
	add "0" + 10
	ld [hl], a
	jr c, .next
	sub 10
	ld [hld], a
	ld [hl], "1"
.next
	pop hl
	ld c, sNewBox2 - sNewBox1Name
	add hl, bc
	pop bc
	dec b
	jr nz, .loop
	jp CloseSRAM

.Box:
	rawchar "Box   @"

SetBoxPointer:
; Set box b slot c to point to pokémon storage bank d, entry e.
	push hl
	push de
	push bc
	ld a, BANK(sNewBox1)
	call GetSRAMBank

	; Locate the correct Box
	ld hl, sNewBox1
	ld a, b
	dec a
	push bc
	ld bc, sNewBox2 - sNewBox1
	rst AddNTimes
	pop bc

	; Write entry
	push hl
	ld b, 0
	dec c
	add hl, bc
	ld [hl], e
	pop hl

	; Write 1 to bank flag array if entry is in storage bank 2, 0 otherwise
	ld a, c
	ld bc, sNewBox1Banks - sNewBox1
	add hl, bc
	ld c, a
	ld b, RESET_FLAG
	dec d
	jr z, .got_flag_setup
	ld b, SET_FLAG
.got_flag_setup
	predef FlagPredef
	jp PopBCDEHL

GetStorageBoxMon:
; Reads storage bank+entry from box b slot c and put it in wBufferMon.
; If there is a checksum error, put Bad Egg data in wBufferMon instead.
; Returns c in case of a Bad Egg, z if the requested mon doesn't exist,
; nz|nc otherwise. If b==0, read from party list.
	; TODO: DON'T READ LEGACY SAVE DATA
	ld a, b
	and a
	jr z, .read_party
	push hl
	push de
	push bc
	dec b
	dec c
	ld a, b
	sub 7
	ld d, BANK(sBox1)
	jr c, .got_save_bank
	ld b, a
	ld d, BANK(sBox8)
.got_save_bank
	ld a, d
	call GetSRAMBank
	ld d, b
	ld e, c
	ld bc, sBox2 - sBox1
	ld a, d
	ld hl, sBox1
	rst AddNTimes
	ld a, e
	cp [hl]
	jr c, .not_empty
	xor a
	jr .done
.not_empty
	ld bc, sBox1Mons - sBox1
	add hl, bc
	push hl
	push de
	ld bc, BOXMON_STRUCT_LENGTH
	ld a, e
	rst AddNTimes
	ld de, wBufferMon
	ld bc, BOXMON_STRUCT_LENGTH
	rst CopyBytes
	pop de
	pop hl
	push hl
	push de
	ld bc, sBox1MonNicknames - sBox1Mons
	add hl, bc
	ld a, e
	call SkipNames
	ld de, wBufferMonNick
	ld bc, MON_NAME_LENGTH
	rst CopyBytes
	pop de
	pop hl
	ld bc, sBox1MonOT - sBox1Mons
	add hl, bc
	ld a, e
	call SkipNames
	ld de, wBufferMonOT
	ld bc, NAME_LENGTH
	rst CopyBytes
	or 1
.done
	pop bc
	pop de
	pop hl
	jp CloseSRAM
.read_party
	ld a, [wPartyCount]
	cp c
	jr nc, .party_not_empty
	xor a
	ret
.party_not_empty
	push hl
	push de
	push bc
	dec c
	ld d, b
	ld e, c
	ld hl, wPartyMons
	ld a, c
	ld bc, PARTYMON_STRUCT_LENGTH
	rst AddNTimes
	push de
	ld de, wBufferMon
	ld c, PARTYMON_STRUCT_LENGTH
	rst CopyBytes
	pop de
	push de
	ld hl, wPartyMonNicknames
	ld a, e
	call SkipNames
	ld de, wBufferMonNick
	ld bc, MON_NAME_LENGTH
	rst CopyBytes
	pop de
	ld hl, wPartyMonOT
	ld a, e
	call SkipNames
	ld de, wBufferMonOT
	ld bc, NAME_LENGTH
	rst CopyBytes
	or 1
	jp PopBCDEHL

GetStorageMon:
; Reads storage bank d, entry e and put it in wBufferMon.
; If there is a checksum error, put Bad Egg data in wBufferMon instead.
; Returns c in case of a Bad Egg, z if the requested mon doesn't exist,
; nz|nc otherwise.
	ld a, d
	dec a
	ld a, BANK(sBoxMons1)
	jr z, .got_bank
	ld a, BANK(sBoxMons2)
.got_bank
	call GetSRAMBank

	; Check if entry is allocated.
	push hl
	push de
	push bc
	ld b, CHECK_FLAG
	ld c, e
	dec c
	ld hl, sBoxMons1UsedEntries
	ld d, 0
	predef FlagPredef
	jr z, .done ; entry not found

	; Get the correct pointer
	ld hl, sBoxMons1Mons
	ld bc, SAVEMON_STRUCT_LENGTH
	ld a, e
	dec a
	rst AddNTimes

	; Write to wBufferMon
	ld de, wBufferMon
	ld bc, BOXMON_STRUCT_LENGTH
	rst CopyBytes
	ld de, wBufferMonNick
	ld bc, NAME_LENGTH - 1
	rst CopyBytes
	ld de, wBufferMonOT
	ld bc, NAME_LENGTH - 1
	rst CopyBytes

	; Decode the resulting wBufferMon. This also returns a
	; Bad Egg failsafe on a checksum error.
	call DecodeBufferMon
.done
	jp PopBCDEHL

NewStorageMon:
; Writes Pokémon from wBufferMon to free space in storage, if there
; is space. Returns z on success with storage bank d, entry e.
; Returns z if the storage is full, otherwise nz with de pointing to
; bank and entry.
	push bc
	push hl
	ld a, BANK(sBoxMons1)
	ld de, 0
	call .check_entries
	ld a, BANK(sBoxMons2)
	call z, .check_entries
	ld d, e
	ld e, c
	pop hl
	pop bc
	jp z, CloseSRAM
	inc e
	jr _NewStorageMon

.check_entries
	inc e
	call GetSRAMBank
	lb bc, CHECK_FLAG, 0
	ld hl, sBoxMons1UsedEntries
.loop
	push bc
	predef FlagPredef
	pop bc
	ret nz

	; This isn't an off-by-1 error. We have 157 entries, but flags are 0-156.
	inc c
	ld a, c
	cp MONDB_ENTRIES
	ret z
	jr .loop

_NewStorageMon:
; Writes Pokémon from wBufferMon to storage bank d, entry e. Does not
; verify that the space is empty -- if you want that, you probably want
; NewStorageMon (without underline) which finds an unused de to run this.
; Returns nz (denoting successful write into the storage list).
	push hl
	push bc
	push de
	call EncodeBufferMon
	pop de

	; Check which SRAM bank to use
	ld a, d
	dec a
	ld a, BANK(sBoxMons1)
	jr z, .got_bank
	ld a, BANK(sBoxMons2)
.got_bank
	call GetSRAMBank

	; Get Pokémon location
	ld hl, sBoxMons1
	ld b, 0
	ld c, e
	dec c
	ld a, SAVEMON_STRUCT_LENGTH
	rst AddNTimes

	; Write to location
	push de
	ld d, h
	ld e, l
	ld hl, wBufferMon
	ld bc, BOXMON_STRUCT_LENGTH
	rst CopyBytes
	ld hl, wBufferMonNick
	ld bc, NAME_LENGTH - 1
	rst CopyBytes
	ld hl, wBufferMonOT
	ld bc, NAME_LENGTH - 1
	rst CopyBytes
	pop de
	push de

	; Mark location as used
	ld hl, sBoxMons1UsedEntries
	ld c, e
	dec c
	ld b, SET_FLAG
	predef FlagPredef
	pop de
	pop bc
	pop hl
	or 1
	jp CloseSRAM

DecodeBufferMon:
; Decodes BufferMon. Returns nz. Sets carry in case of invalid checksum.
	; First, run a checksum check. Don't use the result until we've done
	; character replacements back to their original state
	call ChecksumBufferMon
	push af

	; Convert 7bit nicknames back to their origianl state.
	ld hl, wBufferMonNick
	ld b, MON_NAME_LENGTH - 1
	call .Prepare
	ld hl, wBufferMonOT
	ld b, PLAYER_NAME_LENGTH - 1
	call .Prepare

	; Shift unused OT bytes
	ld hl, wBufferMonOT + NAME_LENGTH
	ld d, h
	ld e, l
	dec de
	ld a, [de]
	ld [hld], a
	dec de
	ld a, [de]
	ld [hld], a
	dec de
	ld a, [de]
	ld [hld], a

	; Add nickname terminators
	ld [hl], "@" ; OTname terminator
	ld hl, wBufferMonNick + MON_NAME_LENGTH - 1
	ld [hl], "@"

	; Now we have a complete decoded boxmon struct with names.
	; If checksum was incorrect, replace data with one for Bad Egg.
	pop af
	jr z, .set_partymon_data

	call SetBadEgg
	call .set_partymon_data
	scf
	ret

.set_partymon_data
	; Calculate stats
	ld hl, wBufferMonOT + PLAYER_NAME_LENGTH
	ld a, [hl]
	and HYPER_TRAINING_MASK
	inc a
	ld b, a
	ld hl, wBufferMonEVs - 1
	ld de, wBufferMonMaxHP
	predef CalcPkmnStats

	; Set HP to full
	ld hl, wBufferMonMaxHP
	ld de, wBufferMonHP
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a

	; Eggs have 0 current HP
	ld hl, wBufferMonIsEgg
	bit MON_IS_EGG_F, [hl]
	jr z, .not_egg
	xor a
	ld [de], a
	dec de
	ld [de], a

.not_egg
	ld hl, wBufferMonMoves
	ld de, wBufferMonPP
	predef FillPP
	or 1
	ret

.Prepare:
	ld a, [hl]
	or $80
	ld c, $7f
	cp $fa
	jr z, .replace
	ld c, "@"
	cp $fb
	jr z, .replace
	ld c, 0
	cp $fc
	jr nz, .setchar
.replace
	ld a, c
.setchar
	ld [hli], a
	dec b
	jr nz, .Prepare
	ret

SetBadEgg:
	; Load failsafe data into the BufferMon pokémon struct
	ld hl, wBufferMon
	ld bc, BOXMON_STRUCT_LENGTH
	ld a, 1
	rst ByteFill

	; Set data that can't be 1 to other things
	xor a
	ld hl, wBufferMonItem
	ld [hl], a
	ld hl, wBufferMonMoves + 1
	ld bc, NUM_MOVES - 1
	rst ByteFill
	ld hl, wBufferMonPersonality
	ld [hl], ABILITY_1 | QUIRKY
	inc hl
	ld [hl], MALE | IS_EGG_MASK | 1
	ld hl, wBufferMonHappiness ; egg cycles
	ld [hl], 255
	ld hl, wBufferMonExp
	ld c, 3
	rst ByteFill

	; Set nickname fields
	ld hl, wBufferMonNick
	ld de, .BadEgg
	call CopyName2
	ld hl, wBufferMonOT
	ld [hl], "?"
	inc hl
	ld [hl], "@"
	ret

.BadEgg:
	rawchar "Bad Egg@"

EncodeBufferMon:
; Encodes BufferMon to prepare for storage
	; Shift unused OT bytes
	ld hl, wBufferMonOT + PLAYER_NAME_LENGTH
	ld d, h
	ld e, l
	dec de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a

	; Convert nicknames to 7bit
	ld hl, wBufferMonNick
	ld b, MON_NAME_LENGTH - 1
	call .Prepare
	ld hl, wBufferMonOT
	ld b, PLAYER_NAME_LENGTH - 1
	call .Prepare

	jr ChecksumBufferMon

.Prepare:
	ld a, [hl]
	ld c, $fa
	cp $7f
	jr z, .replace
	inc c
	cp "@"
	jr z, .replace
	inc c
	and a
	jr nz, .removebit
.replace
	ld a, c
.removebit
	and $7f
	ld [hli], a
	dec b
	jr nz, .Prepare
	ret

ChecksumBufferMon:
; Calculate and write a checksum and to BufferMon. Use a nonzero baseline to
; avoid a complete null content from having 0 as a checksum.
; Returns z if an existing checksum is identical to the written checksum.
	; boxmon struct
	ld bc, wBufferMon
	ld hl, 127
	lb de, BOXMON_STRUCT_LENGTH, 0
	call .DoChecksum

	; extra bytes in otname
	ld bc, wBufferMonOT + PLAYER_NAME_LENGTH - 1
	ld d, 3
	call .DoChecksum

	; nickname (7bit only)
	ld bc, wBufferMonNick
	ld d, $80 | MON_NAME_LENGTH - 1
	call .DoChecksum

	; otname (7bit only)
	ld bc, wBufferMonOT
	ld d, $80 | MON_NAME_LENGTH - 1
	call .DoChecksum

	; Compare and write the result
	ld d, h
	ld e, l

	; Checksum is 16bit, further ones are padded with zeroes.
	; The padding being nonzero is also counted as invalid.
	ld b, 0 ; used for checksum error detection
	ld hl, wBufferMonNick
	ld c, MON_NAME_LENGTH - 1
	call .WriteChecksum
	ld hl, wBufferMonOT
	ld c, PLAYER_NAME_LENGTH - 1
.WriteChecksum:
	ld a, [hl]
	and $7f
	sla e
	rl d
	jr nc, .not_set
	or $80
.not_set
	cp [hl]
	ld [hli], a
	jr z, .checksum_valid
	inc b
.checksum_valid
	dec c
	jr nz, .WriteChecksum
	ld a, b
	and a
	ret

.DoChecksum:
	inc e
	dec d
	bit 6, d
	ret nz
	ld a, [bc]
	inc bc
	bit 7, d
	jr z, .not_7bit
	and $7f
.not_7bit
	push bc
	ld b, 0
	ld c, a
	ld a, e
	rst AddNTimes
	pop bc
	jr .DoChecksum
