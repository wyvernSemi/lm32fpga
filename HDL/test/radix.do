radix define SDRAM_FSM {
    "32'd0"  "PRE"          -color "#8080ff",
    "32'd1"  "idle"         -color "#b0b0b0",
    "32'd2"  "SELF"         -color "#80ff80",
    "32'd3"  "REF"          -color "#80ff80",
    "32'd4"  "MRS"          -color "white",
    "32'd5"  "PWR_DOWN"     -color "#b0b0b0",
    "32'd6"  "ROW_ACT"      -color "white",
    "32'd7"  "ACT_PWR_DOWN" -color "#b0b0b0",
    "32'd8"  "WR"           -color "#ffff80",
    "32'd9"  "WR_SUSP"      -color "#b0b0b0",
    "32'd10" "WRA"          -color "#ffff80",
    "32'd11" "WRA_SUSP"     -color "#b0b0b0",
    "32'd12" "RD"           -color "cyan",
    "32'd13" "RD_SUSP"      -color "#b0b0b0",
    "32'd14" "RDA"          -color "cyan",
    "32'd15" "RD_SUSP"      -color "#b0b0b0",
    -default hex
    -defaultcolor red
}
