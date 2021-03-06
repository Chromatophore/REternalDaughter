;;;;;;;;;;;;;;;;;;;;;;;;;;
;       saveutil:        ;
;        part of         ;
;    REternal Daughter   ;
;                        ;
;     copyright 2016     ;
;   by Maciej Miszczyk   ;
;                        ;
;  this program is free  ;
;           and          ;
;  open source software  ;
; released under GNU GPL ;
;    (see COPYING for    ;
;    further details)    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;

(import argparse struct)

(defreader | [str] `(getattr arguments ~str)) ; reader macro for easier cmdline handling

(defn get-var-from-file [file offset]
  (.seek file offset)
  (int.from_bytes(.read file 4) "little"))

(defn set-var-to-file [file offset value]
  (.seek file offset)
  (.write file (struct.pack "i" value)))

(defn weapon-to-number [value reverse]
  (setv weapons[`(~(int 1) knife)
                `(~(int 2) hammer)
                `(~(int 3) mojak)
                `(~(int 4) ozar)
                `(~(int 5) sigil)])
  (setv ret None)
  (for [weapon weapons] (if reverse (if (= (car weapon) value) (setv ret (last weapon)))   ; get weapon from number
                                    (if (= (last weapon) value) (setv ret (car weapon))))) ; get number from weapon
  ret)

; TODO: find variables for gifts from gods and other special abilities in savefile

; see this description of CNC Array format: http://community.clickteam.com/threads/41217-specs-for-CNC-ARRAY-format
; offset 0x1e: health
; offset 0x22: setting to 1 enables double jump, I don't think it does anything else
; offset 0x26: ? unknown offsets might be storyline triggers
; offset 0x2a: ? '?' means tested but unkown
; offset 0x2e: ? if something's not there, it wasn't rested
; offset 0x32: ?
; offset 0x36: ?
; offset 0x3a: number of gems (ammo for secondary weapon)
; offset 0x3e: ?
; offset 0x42: setting to 1 unlocks hammer
; offset 0x46: ?
; offset 0x4a: ?
; offset 0x4e: ?
; offset 0x52: ?
; offset 0x56: max gems
; offset 0x5a: ?
; offset 0x5e: setting to 1 enables mojak
; offset 0x62: ?
; offset 0x66: ?
; offset 0x6a: ?
; offset 0x6e: ?
; offset 0x72: current weapon 1 - knife 2 - hammer 3 - mojak 4 - ozar 5 - sigil
; offset 0x74: ?
; offset 0x76: setting to 1 enables ozar
; offset 0x7a: setting to 1 makes erlanduru appear as savegame icon
; offset 0x7e: ?
; offset 0x82: ?
; offset 0x86: ?
; offset 0x8a: ?
; offset 0x8e: elanduru: 0 - no, 1-3 - young, 4 - adult, 5 - adult with mask
; offset 0x92: ?
; offset 0x96: setting to 1 enables sigil
; offset 0xaa: attack power
; offset 0xc6: current position

;handle command line arguments
(setv parser (argparse.ArgumentParser
  :description "Eternal Daughter save reader/editor. Part of the REternal Daughter project.
  To use, place in the game's folder or any other folder containing ED savefiles with slot{1-3}.sav."))
(.add_argument parser "slotnumber" :help "Save slot number" :type int :choices (range 1 4))
(.add_argument parser "-p" "--print" :action "store_true" :help "Print information about current savefile")
(.add_argument parser "-l" "--life" :help "Set life to provided value" :type int)
(.add_argument parser "-g" "--gems" :help "Set current number of gems (ammo)" :type int)
(.add_argument parser "-G" "--gems-max" :help "Set maximum number of gems" :type int)
(.add_argument parser "-L" "--location" :help "Teleport to chosen savespot" :type int)
(.add_argument parser "-a" "--attack-power" :help "Set attack power" :type int)
(.add_argument parser "-d" "--doublejump" :help "Enable/disable double jump" :type int :choices [0 1])
(.add_argument parser "-e" "--elanduru" :help "Pick Elanduru's form (0 - no Elanduru, 5 - adult Elanduru with mask)"
                                        :type int :choices (range 0 6))
(.add_argument parser "-H" "--hammer" :help "Enable/disable hammer" :type int :choices [0 1])
(.add_argument parser "-M" "--mojak" :help "Enable/disable Mojak" :type int :choices [0 1])
(.add_argument parser "-O" "--ozar" :help "Enable/disable Ozar's Flame" :type int :choices [0 1])
(.add_argument parser "-S" "--sigil" :help "Enable/disable Sigil" :type int :choices [0 1])
(.add_argument parser "-W" "--weapon" :help "Current weapon" :type str
                                      :choices ["knife" "hammer" "mojak" "ozar" "sigil"])
(setv arguments (.parse_args parser))
(setv savefile-vars[ `(life ~(int "0x1e" 16)) ; known variable in savefile
                     `(gems ~(int "0x3a" 16)) ; weapon handled separately to print string instead of int
                     `(gems-max ~(int "0x56" 16))
                     `(location ~(int "0xc6" 16))
                     `(attack-power ~(int "0xaa" 16))
                     `(doublejump ~(int "0x22" 16))
                     `(elanduru ~(int "0x8e" 16))
                     `(hammer ~(int "0x42" 16))
                     `(mojak ~(int "0x5e" 16))
                     `(ozar ~(int "0x76" 16))
                     `(sigil ~(int "0x96" 16))])

(if #|"print" (print (+ "Analyzing file " (+ "slot" (str #|"slotnumber") ".sav \nValues are now:"))))
(with [(setv f (open (+ "slot" (str #|"slotnumber") ".sav") "r+b"))]
  (for [i savefile-vars] ; handle known variables in savefile
    (lif #|(car i) (set-var-to-file f (last i) #|(car i))) ; lif will return true if attribute is set but has value 0
    (if #|"print" (print (+ (car i) ": " (str (get-var-from-file f (last i)))))))
  (if #|"weapon" (set-var-to-file f (int "0x72" 16) (weapon-to-number #|"weapon" False))) ; handle current weapon
  (if #|"print" (print (+ "current weapon: " (weapon-to-number (get-var-from-file f (int "0x72" 16)) True)))))