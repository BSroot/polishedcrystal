NatureNames:
	table_width 2, NatureNames
	dw .Lonely
	dw .Brave
	dw .Adamant
	dw .Naughty
	dw .Bold
	dw .Relaxed
	dw .Impish
	dw .Lax
	dw .Timid
	dw .Hasty
	dw .Jolly
	dw .Naive
	dw .Modest
	dw .Mild
	dw .Quiet
	dw .Rash
	dw .Calm
	dw .Gentle
	dw .Sassy
	dw .Careful
	dw .NoNature
	assert_table_length NUM_NATURES + 1

.Lonely:   db "Lonely@"
.Brave:    db "Brave@"
.Adamant:  db "Adamant@"
.Naughty:  db "Naughty@"
.Bold:     db "Bold@"
.Relaxed:  db "Relaxed@"
.Impish:   db "Impish@"
.Lax:      db "Lax@"
.Timid:    db "Timid@"
.Hasty:    db "Hasty@"
.Jolly:    db "Jolly@"
.Naive:    db "Naive@"
.Modest:   db "Modest@"
.Mild:     db "Mild@"
.Quiet:    db "Quiet@"
.Rash:     db "Rash@"
.Calm:     db "Calm@"
.Gentle:   db "Gentle@"
.Sassy:    db "Sassy@"
.Careful:  db "Careful@"
.NoNature: db "---@"

NatureIndicators:
	dw .LonelyInd
	dw .BraveInd
	dw .AdamantInd
	dw .NaughtyInd
	dw .BoldInd
	dw .RelaxedInd
	dw .ImpishInd
	dw .LaxInd
	dw .TimidInd
	dw .HastyInd
	dw .JollyInd
	dw .NaiveInd
	dw .ModestInd
	dw .MildInd
	dw .QuietInd
	dw .RashInd
	dw .CalmInd
	dw .GentleInd
	dw .SassyInd
	dw .CarefulInd
	dw .NoNatureInd

.SassyInd:   db "<NEXT>" ; fallthrough
.RashInd:    db "<NEXT>" ; fallthrough
.ImpishInd:  db "<NEXT>" ; fallthrough
.LonelyInd:  db "↑<NEXT>↓@"
.NaiveInd:   db "<NEXT>" ; fallthrough
.CarefulInd: db "<NEXT>" ; fallthrough
.MildInd:    db "<NEXT>" ; fallthrough
.BoldInd:    db "↓<NEXT>↑@"
.QuietInd:   db "<NEXT>" ; fallthrough
.LaxInd:     db "<NEXT>" ; fallthrough
.AdamantInd: db "↑<NEXT><NEXT>↓@"
.JollyInd:   db "<NEXT>" ; fallthrough
.GentleInd:  db "<NEXT>" ; fallthrough
.ModestInd:  db "↓<NEXT><NEXT>↑@"
.RelaxedInd: db "<NEXT>" ; fallthrough
.NaughtyInd: db "↑<NEXT><NEXT><NEXT>↓@"
.HastyInd:   db "<NEXT>" ; fallthrough
.CalmInd:    db "↓<NEXT><NEXT><NEXT>↑@"
.BraveInd:   db "↑<NEXT><NEXT><NEXT><NEXT>↓@"
.TimidInd:   db "↓<NEXT><NEXT><NEXT><NEXT>↑" ; fallthrough
.HardyInd:
.DocileInd:
.SeriousInd:
.BashfulInd:
.QuirkyInd:
.NoNatureInd: db "@"
