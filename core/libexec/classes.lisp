;;;; -*- mode: Common-Lisp; sly-buffer-package: "yadfa"; coding: utf-8-unix; -*-
(in-package :yadfa)
(defmethod ms:class-persistent-slots ((self standard-object))
  (mapcar #'c2mop:slot-definition-name
          (c2mop:class-slots (class-of self))))
(defun print-slot (object slot stream)
  (if (slot-boundp object slot)
      (write (slot-value object slot) :stream stream)
      (write-string "#<unbound>" stream)))
(defclass yadfa-class ()
  ((attributes
    :initarg :attributes
    :initform '()
    :accessor attributes-of
    :type list
    :documentation "Plist of attributes which are used instead of slots for stuff that aren't shared between slots"))
  (:documentation "All the classes that are part of the game's core inherit this class"))
(defclass element-type-class (standard-class) ((name :initform nil)))
(defmethod name-of ((class element-type-class))
  (or (slot-value class 'name) (class-name class)))
(defmethod c2mop:validate-superclass ((class element-type-class) (superclass standard-class)) t)
(defmethod c2mop:validate-superclass ((class standard-class) (superclass element-type-class))
  (error 'simple-error :format-control "Either you didn't use ~s to define ~s or you tried to inherit a class not defined with ~s" :format-arguments `(define-type ,(class-name class) define-type)))
(defclass element-type () () (:metaclass element-type-class))
(defmethod make-load-form ((object element-type) &optional env)
  (make-load-form-saving-slots object :environment env))
(defclass buff () ()
  (:documentation #.(f:fmt nil "mixin for " (ref move :class) " or " (ref item :class) " that sets specified " (ref status-condition :class) " that causes buffs also uses this mixin")))
(defclass debuff () ()
  (:documentation #.(f:fmt nil "mixin for " (ref move :class) " or " (ref item :class) " that sets specified " (ref status-condition :class) " that causes debuffs also uses this mixin")))
(defclass clear-status-mixin ()
  ((statuses-cleared
    :initarg :statuses-cleared
    :accessor statuses-cleared-of
    :initform ()
    :type list
    :documentation "Status conditions that this move or item clears"))
  (:documentation #.(f:fmt nil "mixin for " (ref move :class) " or " (ref item :class) " that clears specified " (ref status-condition :class))))
(defclass element-type-mixin ()
  ((element-types
    :accessor element-types-of
    :initform nil
    :initarg :element-types
    :type list
    :documentation #.(f:fmt nil "a list of " (ref element-type :class) "s or symbols that makes @code{CL:MAKE-INSTANCE} return one when passed to it"))))
(defclass base-character (yadfa-class element-type-mixin)
  ((name
    :initarg :name
    :initform :missingno.
    :accessor name-of
    :type (or keyword string)
    :documentation "Name of the character")
   (description
    :initarg :description
    :initform :?
    :accessor description-of
    :type (or keyword string)
    :documentation "Description of the character")
   (health
    :initarg :health
    :reader health-of
    :type (real 0)
    :documentation "Health of the character.")
   (energy
    :initarg :energy
    :reader energy-of
    :type (real 0)
    :documentation "Energy of the character.")
   (default-attack-power
    :initarg :default-attack-power
    :initform 40
    :type real
    :accessor default-attack-power-of
    :documentation "The default attack base stat when no attack is selected and no weapon is equipped")
   (level
    :initarg :level
    :initform 2
    :accessor level-of
    :type unsigned-byte
    :documentation "character's current level")
   (male
    :initarg :male
    :initform t
    :accessor malep
    :type boolean
    :documentation "True if the character is male, false if female")
   (wear
    :initarg :wear
    :initform ()
    :accessor wear-of
    :type list
    :documentation "List of clothes the character is wearing, outer clothes listed first")
   (species
    :initarg :species
    :initform :missingno.
    :accessor species-of
    :type (or keyword string)
    :documentation "Character's species.")
   (last-process-potty-time
    :initarg :last-process-potty-time
    :initform (if *game* (time-of *game*) 0)
    :accessor last-process-potty-time-of
    :type real
    :documentation "Last time process-potty was processed")
   (moves
    :initarg :moves
    :initform ()
    :type list
    :accessor moves-of
    :documentation "list of moves the character knows")
   (exp
    :initarg :exp
    :accessor exp-of
    :initform 0
    :type (real 0)
    :documentation "How many experience points the character has")
   (base-stats
    :initarg :base-stats
    :initform (list :health 45 :attack 80 :defense 50 :energy 45 :speed 120)
    :accessor base-stats-of
    :type list
    :documentation "the base stats of the character")
   (iv-stats
    :initarg :iv-stats
    :initform (list :health (random 16) :attack (random 16) :defense (random 16) :energy (random 16) :speed (random 16))
    :accessor iv-stats-of
    :type list
    :documentation "iv stats of the character")
   (bitcoins
    :initarg :bitcoins
    :initform 0
    :type (real 0)
    :accessor bitcoins-of
    :documentation "Amount of Bitcoins the character has. Not limited to a single country.")
   (inventory
    :initarg :inventory
    :initform ()
    :type list
    :accessor inventory-of
    :documentation "List of items the character has.")
   (wield
    :initarg :wield
    :initform nil
    :accessor wield-of
    :type (or null item)
    :documentation "Item the character is wielding as a weapon")
   (status-conditions
    :initarg :status-conditions
    :initform ()
    :accessor %status-conditions-of
    :type list
    :documentation "Status conditions of the character"))
  (:documentation "Base class for the characters in the game"))
(defclass item (yadfa-class)
  ((description
    :initarg :description
    :initform :?
    :accessor description-of
    :type (or keyword string)
    :documentation "item description")
   (name
    :initarg :name
    :initform :teru-sama
    :accessor name-of
    :type (or keyword string)
    :documentation "item description")
   (plural-name
    :initarg :plural-name
    :initform nil
    :accessor plural-name-of
    :type (or null string)
    :documentation "The plural name of item")
   (consumable
    :initarg :consumable
    :initform nil
    :accessor consumablep
    :type boolean
    :documentation "Whether this item goes away when you use it")
   (tossable
    :initarg :tossable
    :initform t
    :accessor tossablep
    :type boolean
    :documentation "Whether you can throw this item away or not")
   (sellable
    :initarg :sellable
    :initform t
    :accessor sellablep
    :type boolean
    :documentation "Whether you can sell this item or not")
   (value
    :initarg :value
    :initform 0
    :accessor value-of
    :type (real 0)
    :documentation "Value of item in bitcoins")
   (wear-stats
    :initarg :wear-stats
    :initform ()
    :accessor wear-stats-of
    :type list
    :documentation "stat boost when wearing this item. Is a plist in the form of @code{(list :attack attack :defense defense :health health :energy energy :speed speed)}")
   (wield-stats
    :initarg :wield-stats
    :initform ()
    :accessor wield-stats-of
    :type list
    :documentation "stat boost when wielding this item. Is a plist in the form of @code{(list :attack attack :defense defense :health health :energy energy :speed speed)}")
   (special-actions
    :initarg :special-actions
    :initform ()
    :accessor special-actions-of
    :type list
    :documentation "Plist of actions that the player sees as actions with a lambda with the lambda-list @code{(item user &key &allow-other-keys)} they can perform with the item, @var{ITEM} is the instance that this slot belongs to, @var{USER} is the user using the item"))
  (:documentation "Something you can store in your inventory and use"))
(defclass damage-item (item)
  ((use-power
    :initarg :use-power
    :initform 40
    :type real
    :accessor use-power-of
    :documentation "attack power of item when used instead of wielded"))
  (:documentation "Item that deal damage when used"))
(defclass status-condition (yadfa-class)
  ((name
    :initarg :name
    :initform nil
    :type (or string null)
    :accessor name-of
    :documentation "name of status condition")
   (description
    :initarg :description
    :initform nil
    :type (or string null)
    :accessor description-of
    :documentation "description of status conditions")
   (target
    :initarg :target
    :initform nil
    :accessor target-of
    :documentation "Enemy target that the battle script affects")
   (accumulative
    :initarg :accumulative
    :initform 1
    :accessor accumulative-of
    :type (or unsigned-byte (eql t))
    :documentation "how many of these the user can have at a time, @code{T} if infinite")
   (blocks-turn
    :initarg :blocks-turn
    :initform nil
    :type boolean
    :accessor blocks-turn-of
    :documentation "If @code{T} this condition prevents the player from moving")
   (duration
    :initarg :duration
    :initform t
    :accessor duration-of
    :type (or unsigned-byte (eql t))
    :documentation "How many turns this condition lasts. @code{T} means it lasts indefinitely.")
   (stat-delta
    :initarg :stat-delta
    :initform '()
    :accessor stat-delta-of
    :type list
    :documentation "Plist containing the status modifiers in the form of deltas")
   (stat-multiplier
    :initarg :stat-multiplier
    :initform '()
    :type list
    :accessor stat-multiplier-of
    :documentation "Plist containing the status modifiers in the form of multipliers")
   (priority
    :initarg :priority
    :initform 0
    :type unsigned-byte
    :accessor priority-of
    :documentation "Unsigned integer that specifies How important this condition is to cure. Used for the AI. Lower value means more important")
   (curable
    :initarg :curable
    :initform nil
    :type boolean
    :accessor curablep
    :documentation "Whether items or moves that cure statuses cure this"))
  (:documentation "Base class for all the status conditions"))
(defclass persistent-status-condition (status-condition)
  ()
  (:documentation "Status condition that lasts outside of battle"))
(defclass move (yadfa-class element-type-mixin)
  ((name
    :initarg :name
    :initform :-
    :accessor name-of
    :type (or keyword string)
    :documentation "name of move")
   (description
    :initarg :description
    :initform :-
    :type (or keyword string)
    :accessor description-of
    :documentation "Description of move")
   (energy-cost
    :initarg :energy-cost
    :initform 0
    :type real
    :accessor energy-cost-of
    :documentation "How much energy this move costs"))
  (:documentation "base class of moves used in battle"))
(defclass health-inc-move (move)
  ((health
    :accessor health-of
    :initform 0
    :type real
    :initarg :health)))
(defclass energy-inc-move (move)
  ((energy
    :accessor energy-of
    :initform 0
    :type real
    :initarg :energy)))
(defclass damage-move (move)
  ((power
    :initarg :power
    :initform 40
    :type real
    :accessor power-of
    :documentation "Number used to determine the damage of this attack"))
  (:documentation "Move that causes damage when used"))
(defclass mess-move-mixin (move) ()
  (:documentation "Basically any move that involves messing"))
(defclass wet-move-mixin (move) ()
  (:documentation "Basically any move that involves wetting"))
(defclass bladder-character (base-character)
  ((bladder/contents
    :initarg :bladder/contents
    :initform 0
    :type (real 0)
    :accessor bladder/contents-of
    :documentation "Amount in ml that the character is holding in in ml.")
   (bladder/fill-rate
    :initarg :bladder/fill-rate
    :initform (* (/ 2000 24 60) 0)
    :type real
    :accessor bladder/fill-rate-of
    :documentation "Amount in ml that the character's bladder fills each turn.")
   (bladder/fill-rate/multiplier
    :initarg :bladder/fill-rate/multiplier
    :initform 1
    :type real
    :accessor bladder/fill-rate/multiplier-of
    :documentation "Multiplier for @var{BLADDER/FILL-RATE}. Decreases by @var{BLADDER/FILL-RATE/COOLDOWN} every turn")
   (bladder/fill-rate/cooldown
    :initarg :bladder/fill-rate/cooldown
    :initform 1/20
    :type real
    :accessor bladder/fill-rate/cooldown-of
    :documentation "How much  @var{BLADDER/FILL-RATE/MULTIPLIER} decreases every turn")
   (bladder/need-to-potty-limit
    :initarg :bladder/need-to-potty-limit
    :initform 300
    :type (real 0)
    :accessor bladder/need-to-potty-limit-of
    :documentation "How full the bladder needs to be before the character needs to go")
   (bladder/potty-dance-limit
    :initarg :bladder/potty-dance-limit
    :initform 450
    :type (real 0)
    :accessor bladder/potty-dance-limit-of
    :documentation "How full the character's bladder needs to be before the character starts doing a potty dance")
   (bladder/potty-desperate-limit
    :initarg :bladder/potty-desperate-limit
    :initform 525
    :type (real 0)
    :accessor bladder/potty-desperate-limit-of
    :documentation "How full the character's bladder needs to be before the character starts begging to be taken to the bathroom")
   (bladder/maximum-limit
    :initarg :bladder/maximum-limit
    :initform 600
    :type (real 0)
    :accessor bladder/maximum-limit-of
    :documentation "When the character's bladder gets this full, @{s,he@} wets @{him,her@}self")))
(defclass bowels-character (base-character)
  ((bowels/contents
    :initarg :bowels/contents
    :initform 0
    :type (real 0)
    :accessor bowels/contents-of
    :documentation "Amount in grams that the character is holding in")
   (bowels/fill-rate
    :initarg :bowels/fill-rate
    :initform (* (/ 400 24 60) 0)
    :type (real 0)
    :accessor bowels/fill-rate-of
    :documentation "Amount in grams that the character's bowels fills each turn")
   (bowels/fill-rate/multiplier
    :initarg :bowels/fill-rate/multiplier
    :initform 1
    :type real
    :accessor bowels/fill-rate/multiplier-of
    :documentation "Multiplier for @var{BOWELS/FILL-RATE}. Decreases by @var{BOWELS/FILL-RATE/COOLDOWN} every turn")
   (bowels/fill-rate/cooldown
    :initarg :bowels/fill-rate/cooldown
    :initform 1/20
    :type real
    :accessor bowels/fill-rate/cooldown-of
    :documentation "How much @var{BOWELS/FILL-RATE/MULTIPLIER} decreases every turn")
   (bowels/need-to-potty-limit
    :initarg :bowels/need-to-potty-limit
    :initform 400
    :type (real 0)
    :accessor bowels/need-to-potty-limit-of
    :documentation "How full the bowels need to be before the character needs to go")
   (bowels/potty-dance-limit
    :initarg :bowels/potty-dance-limit
    :initform 600
    :type (real 0)
    :accessor bowels/potty-dance-limit-of
    :documentation "How full the character's bowels need to be before the character starts doing a potty dance")
   (bowels/potty-desperate-limit
    :initarg :bowels/potty-desperate-limit
    :initform 700
    :type (real 0)
    :accessor bowels/potty-desperate-limit-of
    :documentation "How full the character's bowels needs to be before the character starts begging to be taken to the bathroom")
   (bowels/maximum-limit
    :initarg :bowels/maximum-limit
    :initform 800
    :type (real 0)
    :accessor bowels/maximum-limit-of
    :documentation "When the character's bowels gets this full, @{he,she@} messes @{him,her@}self")
   (fart-count
    :initarg :fart-count
    :initform 0
    :type unsigned-byte
    :accessor fart-count-of
    :documentation "How many times the character has farted to reduce the pressure since the last mess. Used to calculate how much pressure this relieves and the chance the character might end up messing himself/herself instead.")))
(defclass potty-character (bladder-character bowels-character)
  ())
(defclass team-member (base-character)
  ((skin
    :initarg :skin
    :initform '()
    :type list
    :accessor skin-of
    :documentation "attributes for the character's skin, such as whether he/she has fur or not. current supported elements are @code{:SCALES}, @code{:FUR}, and @code{:FEATHERS}")
   (tail
    :initarg :tail
    :initform nil
    :accessor tail-of
    :type list
    :documentation "attributes for the character's tail. Is @code{NIL} if the character doesn't have a tail. Takes the same syntax as the cdr of a function form with the lambda list @code{(tail-type &optional tail)}  current supported values for @var{TAIL-TYPE} are @code{:SMALL}, @code{:MEDIUM}, @code{:LARGE}, @code{:LIZARD}, @code{:BIRD-SMALL}, @code{:BIRD-LARGE}, and @code{NIL}. current supported elements for @var{TAIL} are @code{:MULTI}, @code{:SCALES}, @code{:FUR}, and @code{:FEATHERS}")
   (wings
    :initarg :wings
    :initform '()
    :type list
    :accessor wings-of
    :documentation "list of attributes for the character's wings. current supported elements are @code{:SCALES}, @code{:FUR}, and @code{:FEATHERS}"))
  (:documentation "Either the player or an ally inherits this class"))
(defclass potty-trained-team-member (team-member potty-character) ())
(defclass ally (team-member)
  ((learned-moves
    :initarg :learned-moves
    :accessor learned-moves-of
    :type list
    :initform (list (cons 100 'yadfa-moves:superglitch) (cons 11 'yadfa-moves:kamehameha) (cons 7 'yadfa-moves:tickle) (cons 8 'yadfa-moves:mush))
    :documentation "Alist of moves the player learns by leveling up, first element is the level when you learn them ove, second is a symbol from the `yadfa-moves' package"))
  (:documentation "Team member that is not the player")
  (:default-initargs
   :base-stats (list :health 35 :attack 55 :defense 40 :energy 35 :speed 90)
   :name "Anon"
   :level 5
   :species "fox"
   :bladder/fill-rate (* (/ 2000 24 60) 2)
   :bowels/fill-rate (* (/ 400 24 60) 2)
   :wear (list (make-instance 'yadfa-items:diaper))
   :moves (list (make-instance 'yadfa-moves:watersport) (make-instance 'yadfa-moves:mudsport))))
(defclass ally-no-potty-training (ally potty-character) ())
(defclass ally-rebel-potty-training (ally potty-character) ())
(defclass ally-silent-potty-training (ally potty-trained-team-member) ())
(defclass ally-last-minute-potty-training (ally potty-trained-team-member) ())
(defclass ally-feral (ally potty-trained-team-member) ())
(defclass playable-ally (ally) ())
(defmethod initialize-instance :after
    ((c base-character) &key (health nil healthp) (energy nil energyp)
                             (base-health nil base-health-p) (base-attack nil base-attack-p)
                             (base-defense nil base-defense-p) (base-speed nil base-speed-p) (base-energy nil base-energy-p) &allow-other-keys)
  (declare (ignore health energy))
  (when base-health-p
    (setf (getf (base-stats-of c) :health) base-health))
  (when base-attack-p
    (setf (getf (base-stats-of c) :attack) base-attack))
  (when base-defense-p
    (setf (getf (base-stats-of c) :defence) base-defense))
  (when base-speed-p
    (setf (getf (base-stats-of c) :speed) base-speed))
  (when base-energy-p
    (setf (getf (base-stats-of c) :energy) base-energy))
  (unless healthp
    (setf (health-of c) (calculate-stat c :health)))
  (unless energyp
    (setf (energy-of c) (calculate-stat c :energy)))
  (setf (exp-of c) (calculate-level-to-exp (level-of c))))
(defclass player (potty-trained-team-member pantsable-character)
  ((position
    :initarg :position
    :initform '(0 0 0 yadfa-zones:debug-map)
    :accessor position-of
    :type list
    :documentation "Current position in the form of `(list x y z map)'.")
   (warp-on-death-point
    :initarg :warp-on-death-point
    :accessor warp-on-death-point-of
    :type list
    :initform nil
    :documentation "Where the player warps to when @{s,@}he dies, same format as POSITION")
   (learned-moves
    :initarg :learned-moves
    :accessor learned-moves-of
    :type list
    :initform (list (cons 100 'yadfa-moves:superglitch) (cons 11 'yadfa-moves:kamehameha) (cons 7 'yadfa-moves:tickle) (cons 8 'yadfa-moves:mush))
    :documentation "Alist of moves the player learns by leveling up, first element is the level when you learn them ove, second is a symbol from the `yadfa-moves'"))
  (:documentation "The player")
  (:default-initargs
   :base-stats (list :health 45 :attack 80 :defense 50 :energy 45 :speed 120)
   :name "Anon"
   :description "This is you stupid"
   :level 5
   :species "Fox"
   :bladder/fill-rate (* (/ 2000 24 60) 2)
   :bowels/fill-rate (* (/ 400 24 60) 2)
   :wear (list (make-instance 'yadfa-items:diaper))
   :moves (list (make-instance 'yadfa-moves:watersport)
                (make-instance 'yadfa-moves:mudsport))
   :tail '(:medium :fur)
   :skin '(:fur)))
(defmethod initialize-instance :after
    ((c player) &key (warp-on-death-point nil warp) &allow-other-keys)
  (declare (ignore warp-on-death-point))
  (unless warp
    (setf (warp-on-death-point-of c) (position-of c))))
(defclass zone (yadfa-class)
  ((description
    :initarg :description
    :initform "Seems Pouar didn't make the text for this room yet, get to it you lazy fuck"
    :accessor description-of
    :type string
    :documentation "room description")
   (enter-text
    :initarg :enter-text
    :type (or string coerced-function)
    :initform "Seems Pouar didn't make the text for this room yet, get to it you lazy fuck"
    :accessor enter-text-of
    :documentation "Text that pops up when you enter the room. either a string or a function designator or lambda expression with @code{NIL} as the lambda list that returns a string.")
   (position
    :initarg :position
    :initform '()
    :type list
    :accessor position-of
    :documentation "Position of the zone. Used when we can't figure out the position of the zone ahead of time and to avoid iterating through the hash table.")
   (name
    :initarg :name
    :initform "Mystery Zone"
    :accessor name-of
    :type string
    :documentation "Name of the room")
   (props
    :initarg :props
    :initform ()
    :accessor props-of
    :type list
    :documentation #.(format nil "Plist of props in the room, and by `props' I mean instances of the @code{PROP} class

~a."
                             (xref yadfa:prop :class)))
   (events
    :initarg :events
    :initform ()
    :accessor events-of
    :type list
    :documentation "list of events that run when you enter a room")
   (continue-battle
    :initarg :continue-battle
    :initform nil
    :type list
    :accessor continue-battle-of
    :documentation "A previous battle (which is an instance of the battle class) triggered by an event that you lost. Used to keep the game in a consistent state after losing.")
   (underwater
    :initarg :underwater
    :initform nil
    :accessor underwaterp
    :type boolean
    :documentation "Whether this zone is underwater or not, better get some waterproof clothing if you don't want your diaper to swell up")
   (warp-points
    :initarg :warp-points
    :initform ()
    :accessor warp-points-of
    :type list
    :documentation #.(format nil "Plist of warp points to different maps, values are lists in the same form as the position of the player, keys are passed to the @code{MOVE} function

~a."
                             (xref yadfa-world:move :function)))
   (locked
    :initarg :locked
    :initform nil
    :accessor lockedp
    :type boolean
    :documentation "Whether this area is locked")
   (key
    :initarg :key
    :initform nil
    :accessor key-of
    :type type-specifier
    :documentation "Whether this area can be unlocked. if non-nil, contains the type specifier of the key needed to unlock it if locked.")
   (hidden
    :initarg :hidden
    :initform nil
    :accessor hiddenp
    :type boolean
    :documentation "When true, the game pretends this room doesn't exist. This is for when certain events in the game makes certain zones disappear from the map and to avoid making them be in the exact same state as in the beginning of the game when they reappear")
   (stairs
    :initarg :stairs
    :initform '()
    :accessor stairs-of
    :type list
    :documentation "list containing the directions of stairs. Contains @code{:UP} if there are stairs going up and @code{:DOWN} if there are stairs going down.")
   (direction-attributes
    :initarg :direction-attributes
    :initform ()
    :type list
    :accessor direction-attributes-of
    :documentation "List of attributes based on the direction rather than the zone itself")
   (can-potty
    :initarg :can-potty
    :initform '(lambda (prop &key wet mess pants-down user)
                (declare (ignore prop wet mess pants-down user))
                t)
    :type coerced-function
    :accessor can-potty-p
    :documentation "Whether you're allowed to go potty in this zone. @var{PROP} is the prop you're going potty on if any while @var{USER} is the one going potty. @var{PANTS-DOWN} is @code{T} when @var{USER} pulls his/her pants down and @var{WET} and @var{MESS} are the arguments")
   (potty-trigger
    :initarg :potty-trigger
    :initform '(lambda (had-accident user)
                (declare (ignore had-accident user))
                nil)
    :accessor potty-trigger-of
    :type coerced-function
    :documentation "Runs whenever the user goes potty, whether on purpose or by accident, arguments are the cons called @var{HAD-ACCIDENT} that gets passed from the process-potty function, and @var{USER} which is the user who did it")
   (must-wear
    :initarg :must-wear
    :initform '(t . (lambda (user)
                      (declare (ignore user))
                      t))
    :type (or cons symbol)
    :accessor must-wear-of
    :documentation #.(format nil "Used to determine whether you can enter the zone based on what you're wearing. Is either a cons cell or a symbol. When a symbol it is used as key for one of the values in the hash table in the @code{MUST-WEAR} slot in ~a. When a cons cell, the car is a type specifier of what @var{USER} must wear and the cdr is a lambda expression or a function designator with a single @var{USER} argument which is the character that must be wearing the item. It returns a generalized boolean that returns true when you can enter the zone."
                             (ref game :class)))
   (must-wear*
    :initarg :must-wear*
    :initform '(t . (lambda (user)
                      (declare (ignore user))
                      t))
    :accessor must-wear*-of
    :type (or cons symbol)
    :documentation #.(format nil "Similar to the @code{MUST-WEAR} slot but is done when you try to wear or change while still inside the zone. You can also use a symbol as key for one of the values in the hash table in the @code{MUST-WEAR*} slot in ~a."
                             (ref game :class)))
   (must-not-wear
    :initarg :must-not-wear
    :initform '(nil . (lambda (user)
                        (declare (ignore user))
                        t))
    :type (or cons symbol)
    :accessor must-not-wear-of
    :documentation #.(format nil "Used to determine whether you can enter the zone based on what you're wearing. Is either a cons cell or a symbol. When a symbol it is used as key for one of the values in the hash table in the @code{MUST-NOT-WEAR} slot in ~a. When a cons cell, the car is a type specifier of what @var{USER} must not be wearing wear and the cdr is a lambda expression or a function designator with a single @var{USER} argument which is the character that must be wearing the item. It returns a generalized boolean that returns true when you can enter the zone."
                             (ref game :class)))
   (must-not-wear*
    :initarg :must-not-wear*
    :initform '(nil . (lambda (user)
                        (declare (ignore user))
                        t))
    :type (or cons symbol)
    :accessor must-not-wear*-of
    :documentation #.(format nil "Similar to the @code{MUST-NOT-WEAR} slot but is done when you try to wear or change while still inside the zone. You can also use a symbol as key for one of the values in the hash table in the @code{MUST-NOT-WEAR*} slot in ~a."
                             (ref game :class)))
   (no-wetting/messing
    :initarg no-wetting/messing
    :initform '(lambda (user)
                (declare (ignore user))
                nil)
    :type coerced-function
    :accessor no-wetting/messing-of
    :documentation "lambda expression or function that tells you if you're allowed to wet or mess voluntarily")
   (enemy-spawn-list
    :initarg :enemy-spawn-list
    :initform ()
    :type (or symbol list)
    :accessor enemy-spawn-list-of
    :documentation "list containing what enemies might show up when you enter an area. Each entry looks like this @code{(:chance chance :enemies enemies)} If @var{RANDOM} is specified, then the probability of the enemy being spawn is @var{CHANCE} out of 1 where @var{CHANCE} is a number between 0 and 1")
   (team-npc-spawn-list
    :initarg :team-npc-spawn-list
    :initform ()
    :type (or symbol list)
    :accessor team-npc-spawn-list-of
    :documentation "list containing what npcs team member might show up when you enter an area. Each entry looks like this @code{(:chance chance :npc npc)} If @var{RANDOM} is specified, then the probability of the enemy being spawn is @var{CHANCE} out of 1 where @var{CHANCE} is a number between 0 and 1")
   (placable
    :initarg :placable
    :initform nil
    :accessor placeablep
    :documentation "Whether you can place items here or not"))
  (:documentation "A zone on the map"))
(defclass prop (yadfa-class)
  ((description
    :initarg :description
    :initform ""
    :accessor description-of
    :type string
    :documentation "Description of a prop")
   (name
    :initarg :name
    :initform ""
    :accessor name-of
    :type string
    :documentation "Name of prop")
   (placeable
    :initarg :placeable
    :initform nil
    :accessor placeablep
    :type boolean
    :documentation "Whether you can place items here")
   (items
    :initarg :items
    :initform ()
    :type list
    :accessor items-of
    :documentation "List of items this prop has")
   (bitcoins
    :initarg :bitcoins
    :initform 0
    :accessor bitcoins-of
    :type real
    :documentation "Number of bitcoins this prop has")
   (actions
    :initarg :actions
    :initform ()
    :accessor actions-of
    :type list
    :documentation "Plist of actions who's lambda-list is @code{(prop &key &allow-other-keys)} that the player sees as actions they can perform with the prop, @var{PROP} is the instance that this slot belongs to"))
  (:documentation "Tangible objects in the AREA that the player can interact with"))
(defclass placable-prop (prop item)
  ()
  (:documentation "Prop that you can place"))
(defclass consumable (item)
  ()
  (:documentation "Doesn't actually cause items to be consumable, but is there to make filtering easier"))
(defclass ammo (item)
  ((ammo-power
    :initarg :ammo-power
    :initform 0
    :accessor ammo-power-of
    :type real
    :documentation "Attack base when using this as ammo."))
  (:documentation "Ammo is typically inherited by this class, but nothing in the code actually enforces this and is meant to make filtering easier"))
(defclass damage-wield (item)
  ((power
    :initarg :power
    :initform 40
    :accessor power-of
    :type real
    :documentation "Attack base when used as a melee weapon"))
  (:documentation "Items that cause damage when wielded"))
(defclass weapon (damage-wield)
  ((ammo-type
    :initarg :ammo-type
    :initform nil
    :accessor ammo-type-of
    :type type-specifier
    :documentation "A type specifier specifying the type of ammo this will hold")
   (ammo
    :initarg :ammo
    :initform ()
    :accessor ammo-of
    :type list
    :documentation "List of ammo this item has")
   (reload-count
    :initarg :reload-count
    :initform nil
    :accessor reload-count-of
    :type (or unsigned-byte null)
    :documentation "When in battle, the maximum amount of ammo the user can reload into this item per turn, if nil, then there is no limit")
   (ammo-capacity
    :initarg :ammo-capacity
    :initform 0
    :type unsigned-byte
    :accessor ammo-capacity-of
    :documentation "How much ammo this thing can hold"))
  (:documentation "Items intended to be wielded as a weapon"))
(defclass clothing (item)
  ())
(defclass top (clothing)
  ())
(defclass headpiece (clothing)
  ())
(defclass bottoms (clothing)
  ((bulge-text
    :initarg :bulge-text
    :initform ()
    :type list
    :accessor bulge-text-of
    :documentation "A list of pairs containing the different text that describes the appearance that your diapers have on your pants based on the thickness, first one is the minimum thickness needed for the second text. the text for thicker padding must be listed first")
   (thickness-capacity
    :initarg :thickness-capacity
    :initform (* (expt 6.0l0 1/3) (+ 25 2/5))
    :accessor thickness-capacity-of
    :type (or (real 0) null)
    :documentation "The maximum thickness of your diaper that this can fit over. @code{NIL} means infinite")
   (thickness-capacity-threshold
    :initarg :thickness-capacity-threshold
    :initform 50
    :type (or (real 0) null)
    :accessor thickness-capacity-threshold-of
    :documentation "How much higher than the thickness capacity the clothing can handle diaper expansion in mm before popping/tearing, @code{NIL} means it won't pop/tear")
   (key
    :initarg :key
    :initform nil
    :accessor key-of
    :type type-specifier
    :documentation "Whether this piece of clothing can be locked to prevent removal. Set this to the quoted type specifier that is needed to unlock it")
   (locked
    :initarg :locked
    :initform nil
    :accessor lockedp
    :type boolean
    :documentation "Whether this clothing is locked to prevent removal"))
  (:documentation "Clothing you wear below the waist"))
(defclass closed-bottoms (bottoms)
  ((thickness
    :initarg :thickness
    :initform 1
    :accessor thickness-of
    :type (real 0)
    :documentation "the thickness of the undies in mm")
   (waterproof
    :initarg :waterproof
    :initform nil
    :accessor waterproofp
    :type boolean
    :documentation "Whether this prevents your diapers from swelling up in water")
   (leakproof
    :initarg :leakproof
    :initform nil
    :accessor leakproofp
    :type boolean
    :documentation "Whether this diaper leaks")
   (disposable
    :initarg :disposable
    :initform nil
    :accessor disposablep
    :type boolean
    :documentation "Whether you clean this or throw it away")
   (sogginess
    :initarg :sogginess
    :initform 0
    :accessor sogginess-of
    :type (real 0)
    :documentation "sogginess in ml")
   (sogginess-capacity
    :initarg :sogginess-capacity
    :initform 10
    :accessor sogginess-capacity-of
    :type (real 0)
    :documentation "sogginess capacity in ml")
   (messiness
    :initarg :messiness
    :initform 0
    :accessor messiness-of
    :type (real 0)
    :documentation "messiness in grams")
   (messiness-capacity
    :initarg :messiness-capacity
    :initform 10
    :accessor messiness-capacity-of
    :type (real 0)
    :documentation "messiness capacity in grams")
   (mess-text
    :initarg :mess-text
    :initform '()
    :accessor mess-text-of
    :documentation "Plist that contain the text that comes up in the description when in the inventory with the minimal messiness as the key")
   (wet-text
    :initarg :wet-text
    :initform '()
    :accessor wet-text-of
    :type list
    :documentation "Plist that contains that contain the text that comes up in the description when in the inventory with the minimal sogginess as the key")
   (wear-mess-text
    :initarg :wear-mess-text
    :initform ()
    :type list
    :accessor wear-mess-text-of
    :documentation "Plist that contains the text that comes up in the description when wearing it with the minimal messiness as the key")
   (wear-wet-text
    :initarg :wear-wet-text
    :initform ()
    :type list
    :accessor wear-wet-text-of
    :documentation "Plist that contain the text that comes up in the description when wearing it with the minimal sogginess as the key"))
  (:documentation "these are stuff like pants and underwear and not skirts"))
(defclass full-outfit (top bottoms)
  ())
(defclass closed-full-outfit (full-outfit closed-bottoms)
  ())
(defclass onesie (full-outfit)
  ((onesie-thickness-capacity
    :initarg :onesie-thickness-capacity
    :initform (cons 100 nil)
    :accessor onesie-thickness-capacity-of
    :type cons
    :documentation "cons of values for the thickness capacity of the onesie, first value is for when it's closed, second for when it's opened")
   (onesie-thickness-capacity-threshold
    :initarg :onesie-thickness-capacity-threshold
    :initform (cons 5 nil)
    :type cons
    :accessor onesie-thickness-capacity-threshold-of
    :documentation "cons of values for the thickness capacity threshold of the onesie, first value is for when it's closed, second for when it's opened")
   (onesie-waterproof
    :initarg :onesie-waterproof
    :initform nil
    :type boolean
    :accessor onesie-waterproof-p
    :documentation "Boolean that determines whether the onesie prevents your diaper from swelling up when closed.")
   (onesie-bulge-text
    :initarg :onesie-bulge-text
    :initform (cons () ())
    :type cons
    :accessor onesie-bulge-text-of
    :documentation "A cons containing 2 lists of pairs containing the different text that describes the appearance that your diapers have on your pants based on the thickness, first one is the minimum thickness needed for the second text. the text for thicker padding must be listed first. car is the value for when it's closed, cdr is the value when it's open")))
(defclass onesie/opened (onesie)
  ())
(defclass onesie/closed (onesie closed-full-outfit)
  ())

(defmethod update-instance-for-different-class :after ((old onesie/opened) (new onesie/closed) &key)
  (setf (thickness-capacity-of new) (car (slot-value old 'onesie-thickness-capacity)))
  (setf (thickness-capacity-threshold-of new) (car (slot-value old 'onesie-thickness-capacity-threshold)))
  (setf (waterproofp new) (onesie-waterproof-p old))
  (setf (bulge-text-of new) (car (slot-value old 'onesie-bulge-text))))
(defmethod update-instance-for-different-class :after ((old onesie/closed) (new onesie/opened) &key)
  (setf (thickness-capacity-of new) (cdr (slot-value old 'onesie-thickness-capacity)))
  (setf (thickness-capacity-threshold-of new) (cdr (slot-value old 'onesie-thickness-capacity-threshold)))
  (setf (bulge-text-of new) (cdr (slot-value old 'onesie-bulge-text))))
(defmethod initialize-instance :after
    ((c onesie/opened) &key &allow-other-keys)
  (setf (thickness-capacity-of c) (cdr (onesie-thickness-capacity-of c)))
  (setf (thickness-capacity-threshold-of c) (cdr (onesie-thickness-capacity-threshold-of c)))
  (setf (bulge-text-of c) (cdr (onesie-bulge-text-of c))))
(defmethod initialize-instance :after
    ((c onesie/closed) &key &allow-other-keys)
  (setf (thickness-capacity-of c) (car (onesie-thickness-capacity-of c)))
  (setf (thickness-capacity-threshold-of c) (car (onesie-thickness-capacity-threshold-of c)))
  (setf (waterproofp c) (onesie-waterproof-p c))
  (setf (bulge-text-of c) (car (onesie-bulge-text-of c))))
(defclass incontinence-product (closed-bottoms) ()
  (:default-initargs
   :thickness-capacity-threshold nil
   :disposable t
   :sellable nil)
  (:documentation "these include diapers, pullups, and stuffers"))
(defclass snap-bottoms (bottoms) ()
  (:documentation "These have snaps on them so don't tear when the diaper expands but instead come apart"))
(defclass undies (clothing)
  ())
(defclass padding (incontinence-product) ()
  (:documentation "everything but stuffers"))
(defclass ab-clothing (clothing) ()
  (:documentation "clothing that is more AB than DL"))
(defclass pullup (padding) ()
  (:default-initargs
   :thickness (* 1/2 (+ 25 2/5))
   :thickness-capacity 40))
(defclass diaper (padding) ()
  (:default-initargs
   :thickness (+ 25 2/5)
   :thickness-capacity 80
   :key 'yadfa-items:magic-diaper-key))
(defclass stuffer (incontinence-product) ()
  (:default-initargs
   :thickness (* 1/4 (+ 25 2/5))
   :thickness-capacity 20))
(defclass skirt (bottoms)
  ()
  (:default-initargs
   :thickness-capacity 100
   :thickness-capacity-threshold nil))
(defclass dress (full-outfit)
  ()
  (:default-initargs
   :thickness-capacity 100
   :thickness-capacity-threshold nil))
(defclass shirt (top)
  ())
(defclass pants (closed-bottoms)
  ())
(defclass npc (base-character)
  ((watersport-limit
    :initarg :watersport-limit
    :initform nil
    :accessor watersport-limit-of
    :type (or null (real 0))
    :documentation "How close to @var{BLADDER/MAXIMUM-LIMIT} in ml the enemy is before voluntarily wetting his/her diapers. A value of @code{NIL} means he'll/she'll never wet voluntarily")
   (mudsport-limit
    :initarg :mudsport-limit
    :initform nil
    :accessor mudsport-limit-of
    :type (or null (real 0))
    :documentation "How close to @var{BOWELS/MAXIMUM-LIMIT} in cg the enemy is before voluntarily wetting his/her diapers. A value of @code{NIL} means he'll/she'll never mess voluntarily")
   (watersport-chance
    :initarg :watersport-chance
    :initform 1
    :accessor watersport-chance-of
    :type (real 0)
    :documentation "when @var{WATERSPORT-LIMIT} is reached, there is a 1 in @var{WATERSPORT-CHANCE} he'll voluntarily wet himself")
   (mudsport-chance
    :initarg :mudsport-chance
    :initform 1
    :type (real 0)
    :accessor mudsport-chance-of
    :documentation "when @var{MUDSPORT-LIMIT} is reached, there is a 1 in @var{MUDSPORT-CHANCE} he'll voluntarily mess himself")))
(defclass enemy (npc)
  ((exp-yield
    :initarg :exp-yield
    :initform 50
    :accessor exp-yield-of
    :type (real 0)
    :documentation "Integer that is the base exp points that player receives when this guy is defeated")
   (bitcoins-per-level
    :initarg :bitcoins-per-level
    :initform nil
    :accessor bitcoins-per-level-of
    :type (or (real 0) null)
    :documentation "Bitcoins per level that you get from this enemy per battle. Only used not @code{NIL}."))
  (:default-initargs
   :base-stats (list :health 40
                     :attack 45
                     :defense 40
                     :energy 40
                     :speed 56)
   :bitcoins 0
   :level (random-from-range 2 5))
  (:documentation "Class for enemies"))
(defclass bladder-enemy (enemy bladder-character) ()
  (:documentation "Class for an enemy with a bladder fill rate. This enemy may @{wet,mess@} @{him,her@}self in battle."))
(defclass bowels-enemy (enemy bowels-character) ()
  (:documentation "Class for an enemy with a bowels fill rate. This enemy may @{wet,mess@} @{him,her@}self in battle."))
(defclass potty-enemy (bladder-enemy bowels-enemy) ()
  (:documentation "Class for an enemy with a bladder and bowels fill rate. This enemy may @{wet,mess@} @{him,her@}self in battle."))
(defclass pantsable-character (base-character) ())
(defclass battle (yadfa-class)
  ((turn-queue
    :initarg :turn-queue
    :initform ()
    :accessor turn-queue-of
    :type list
    :documentation "The queue of characters specifying the order of who attacks when in battle")
   (enter-battle-text
    :initarg :enter-battle-text
    :initform nil
    :accessor enter-battle-text-of
    :type (or string null)
    :documentation "The text that comes up when you enter a battle")
   (enemies
    :initarg :enemies
    :initform ()
    :accessor enemies-of
    :type list
    :documentation "List of enemies in battle")
   (team-npcs
    :initarg :team-npcs
    :initform ()
    :accessor team-npcs-of
    :type list
    :documentation "List of team members that the player doesn't actually control but are controlled by the game")
   (win-events
    :initarg :win-events
    :initform ()
    :accessor win-events-of
    :type list
    :documentation "List of events that trigger when you've won the battle")
   (fainted
    :initarg :fainted
    :initform ()
    :type list
    :accessor fainted-of
    :documentation "Characters that have fainted in battle, used so the \"X has fainted\" messages don't appear repeatedly")
   (status-conditions
    :initarg :status-conditions
    :initform (make-hash-table :test 'eq)
    :type hash-table
    :accessor %status-conditions-of
    :documentation #.(f:fmt nil "Hash table of " (ref status-condition :class) " indexed by " (ref base-character :class) ". These only last until the battle ends")))
  (:documentation "Class that contains the information about the battle"))
(defmethod initialize-instance :after
    ((c battle) &key &allow-other-keys)
  (unless (enter-battle-text-of c)
    (setf
     (enter-battle-text-of c)
     (with-output-to-string (s)
       (iter (for i in (enemies-of c))
         (format s "A Wild ~a Appeared!!!~%" (name-of i))))))
  (setf (turn-queue-of c) (sort (append* (enemies-of c) (team-npcs-of c) (team-of *game*)) '>
                                :key (lambda (a)
                                       (calculate-stat a :speed))))
  (incf (time-of *game*)))
(defclass game (yadfa-class)
  ((zones
    :initform (make-hash-table :test #'equal :size 500)
    :type hash-table
    :documentation "Hash table of zones in the game")
   (enemy-spawn-list
    :initarg :enemy-spawn-list
    :initform (make-hash-table :test #'eq)
    :type hash-table
    :accessor enemy-spawn-list-of
    :documentation "contains enemy spawn lists that can be reused. Use a symbol instead of a list in the enemy spawn list to use a key")
   (must-wear
    :initarg :must-wear
    :initform (make-hash-table :test #'eq)
    :accessor must-wear-of
    :type hash-table
    :documentation #.(format nil "hash table of conses that can be used with @code{MUST-WEAR} in ~a.

See @code{MUST-WEAR} in ~a."
                             (ref zone :class) (ref zone :class)))
   (must-not-wear
    :initarg :must-not-wear
    :initform (make-hash-table :test #'eq)
    :type hash-table
    :accessor must-not-wear-of
    :documentation #.(format nil "hash table of conses that can be used with @code{MUST-NOT-WEAR} in ~a.

See @code{MUST-NOT-WEAR} in ~a."
                             (ref zone :class) (ref zone :class)))
   (must-wear*
    :initarg :must-wear*
    :initform (make-hash-table :test #'eq)
    :type hash-table
    :accessor must-wear*-of
    :documentation #.(format nil "hash table of conses that can be used with @code{MUST-WEAR*} in ~a.

See @code{MUST-WEAR*} in ~a."
                             (ref zone :class) (ref zone :class)))
   (must-not-wear*
    :initarg :must-not-wear*
    :initform (make-hash-table :test #'eq)
    :type hash-table
    :accessor must-not-wear*-of
    :documentation #.(format nil "hash table of conses that can be used with @code{MUST-NOT-WEAR*} in ~a.

See @code{MUST-NOT-WEAR*} in ~a."
                             (ref zone :class) (ref zone :class)))
   (player%
    :initarg :player
    :initform nil
    :accessor player-of
    :type (or null player)
    :documentation "The Player, which is an instance of the player class")
   (allies
    :initarg :allies
    :initform nil
    :accessor allies-of
    :type list
    :documentation "List of characters that have joined you")
   (team
    :initarg :team
    :initform nil
    :accessor team-of
    :type list
    :documentation "List of characters sent out to battle")
   (config
    :initarg :config
    :initform (make-hash-table :test 'equal)
    :accessor config-of
    :type hash-table
    :documentation "Arbitrary Configuration")
   (time
    :initarg :time
    :initform 0
    :accessor time-of
    :type unsigned-byte
    :documentation "Turns since start of game")
   (finished-events%
    :initarg :finished-events
    :initform (make-hash-table :test 'equal)
    :type hash-table
    :accessor finished-events-of
    :documentation "A hash table containing whether past events are finished, accepted, and/or declined. Lambda list of the key is @code{(EVENT &OPTIONAL STATUS)} Where @var{EVENT} is the event symbol and @var{STATUS} is either @code{:ACCEPTED}, @code{:DECLINED}. @var{STATUS} isn't passed if it means it is finished")
   (current-events%
    :initarg :finished-events
    :initform (make-hash-table :test 'eq)
    :type hash-table
    :accessor current-events-of
    :documentation "A hash table containing the events currently in progress. Is @code{T} if it is currently in progress.")
   (seen-enemies
    :initarg :seen-enemies
    :initform '()
    :type list
    :accessor seen-enemies-of)
   (event-attributes%
    :initform (make-hash-table :test 'eq)
    :type hash-table
    :documentation "Stores the event attributes of the game"))
  (:documentation "List of all the information in the game"))
(defclass event (yadfa-class)
  ((id
    :initarg :id
    :initform nil
    :type symbol
    :documentation "Unique id identifying the event")
   (lambda
     :initarg :lambda
     :initform (lambda (self &optional accept)
                 (declare (ignore self accept)) nil)
     :type coerced-function
     :documentation "Hook that runs when the event is triggered. @var{SELF} is the event id and @var{ACCEPT} is the result of the function in the @code{MISSION} slot")
   (predicate
    :initarg :predicate
    :initform (lambda (self)
                (declare (ignore self)) t)
    :type coerced-function
    :documentation "Returns true if the mission can be triggered and false if not")
   (repeatable
    :initarg :repeatable
    :type boolean
    :initform nil
    :documentation "Is @code{T} if this event can be triggered more than once")
   (mission
    :initarg :mission
    :initform nil
    :type (or null coerced-function)
    :documentation "If this event is a mission, this slot contains a function that runs the dialog and returns @code{:ACCEPTED} if the mission was accepted, @code{:DECLINED}, if it was declined, or @code{NIL} if it was deferred")
   (finished-depends
    :initarg :finished-depends
    :initform nil
    :type list
    :documentation "List of event ids of events that needs to be finished before this event can be triggered")
   (documentation
    :initform nil
    :initarg :documentation
    :type (or null simple-string)
    :documentation "Documentation explaining the event")))
